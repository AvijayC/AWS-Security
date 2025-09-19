# AWS IAM and Resource Policy Evaluation Logic

## Core Concept: How AWS Evaluates Permissions

AWS uses a specific evaluation logic when determining whether to allow or deny access to resources. Understanding this logic is crucial for AWS security.

## The Fundamental Rule

**For same-account access:**
```
Access = (IAM Policy Allow OR Resource Policy Allow) AND NOT (Any Explicit Deny)
```

**For cross-account access:**
```
Access = (IAM Policy Allow AND Resource Policy Allow) AND NOT (Any Explicit Deny)
```

## Decision Tree for Policy Evaluation

```
                    Is there an Explicit DENY anywhere?
                    /                                \
                  YES                                NO
                   ↓                                  ↓
                 DENIED                    Is this cross-account access?
                                          /                        \
                                        NO                         YES
                                         ↓                          ↓
                            Is there an ALLOW in              Are there ALLOWs in
                            IAM OR Resource Policy?           BOTH IAM AND Resource Policy?
                            /                \                /                    \
                          YES                NO             YES                    NO
                           ↓                  ↓              ↓                      ↓
                        ALLOWED           DENIED         ALLOWED                DENIED
                                     (implicit deny)                      (implicit deny)
```

## AWS Documentation References

### Primary Sources
- [Policy evaluation logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html) - Complete evaluation logic documentation
- [Single account policy evaluation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic_policy-eval-basics.html) - How policies work within one account
- [Cross-account policy evaluation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic-cross-account.html) - Cross-account access requirements
- [Identity vs Resource policies](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_identity-vs-resource.html) - Differences and interactions

### S3-Specific Documentation
- [S3 and IAM integration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security_iam_service-with-iam.html) - How S3 works with IAM
- [S3 bucket policy examples](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html) - Common patterns
- [S3 policy condition keys](https://docs.aws.amazon.com/AmazonS3/latest/userguide/amazon-s3-policy-keys.html) - Available conditions

## The Three Golden Rules

### 1. DENY Always Wins
An explicit deny in ANY policy immediately blocks access, regardless of any allows elsewhere.

### 2. Same-Account: OR Logic
For same-account access, you need at least ONE allow (IAM OR resource policy).

### 3. Cross-Account: AND Logic  
For cross-account access, you need allows in BOTH accounts (IAM AND resource policy).

## Understanding "Most Restrictive" Conditions

When both IAM and resource policies have conditions, the **most restrictive interpretation applies**. This means:

### All Conditions Must Be True
According to [AWS Condition Logic Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-logic-multiple-context-keys-or-values.html):
- If multiple conditions exist in a statement, ALL must evaluate to true
- If multiple values exist for a single condition key, the logic depends on the condition operator

### Example: Both Policies Have Conditions
```json
// IAM Policy
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "*",
  "Condition": {
    "IpAddress": {
      "aws:SourceIp": "10.0.0.0/8"
    }
  }
}

// Bucket Policy  
{
  "Effect": "Allow",
  "Principal": {"AWS": "arn:aws:iam::123456789012:user/Bob"},
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::mybucket/*",
  "Condition": {
    "StringEquals": {
      "s3:x-amz-server-side-encryption": "AES256"
    }
  }
}
```

**Result:** Access is allowed ONLY if:
- Request comes from IP range 10.0.0.0/8 (IAM condition)
- AND object has AES256 encryption (bucket policy condition)

Both conditions must be satisfied - this is the "most restrictive" interpretation.

## Practical Scenarios

### Scenario 1: IAM Allow, No Bucket Policy
```
IAM Policy:         ALLOW s3:PutObject
Bucket Policy:      (no policy exists)
Result:             ✅ ALLOWED
Explanation:        IAM allow is sufficient for same-account
```

### Scenario 2: Both Allow with Different Conditions
```
IAM Policy:         ALLOW s3:GetObject (Condition: MFA required)
Bucket Policy:      ALLOW s3:GetObject (Condition: IP range)
Result:             ✅ ALLOWED only if BOTH MFA and IP conditions met
Explanation:        Most restrictive - all conditions must be true
```

### Scenario 3: Conflicting Allow and Deny
```
IAM Policy:         ALLOW s3:DeleteObject
Bucket Policy:      DENY s3:DeleteObject
Result:             ❌ DENIED
Explanation:        Explicit deny always wins
```

### Scenario 4: Cross-Account Access
```
Account A IAM:      ALLOW s3:GetObject on Account B bucket
Account B Bucket:   ALLOW s3:GetObject from Account A principal
Result:             ✅ ALLOWED
Explanation:        Cross-account requires both allows
```

### Scenario 5: No Explicit Permissions
```
IAM Policy:         (no s3:GetObject permission)
Bucket Policy:      (no policy exists)
Result:             ❌ DENIED
Explanation:        Implicit deny (no explicit allow anywhere)
```

## Real-World Example: Your Current Setup

### Your PutObject Success
```
Request: aalsg-user-1 doing s3:PutObject
├── IAM Check: 
│   └── Inline Policy: ALLOW s3:PutObject ✓
├── Bucket Policy Check:
│   └── No statement about PutObject (neither allow nor deny)
├── No explicit deny found anywhere
└── Result: ALLOWED (IAM allow is sufficient)
```

### Your GetObject Failure
```
Request: aalsg-user-1 doing s3:GetObject
├── IAM Check:
│   └── No s3:GetObject permission (ReadOnly role)
├── Bucket Policy Check:
│   ├── ABACObjectLevelAccess statement:
│   │   └── Condition StringEquals "s3:ExistingObjectTag/username_owner"
│   │   └── Object has no tags → Condition FALSE → Statement doesn't apply
│   └── ABACDenyObjectLevelAccess statement:
│       └── Condition StringNotEquals "s3:ExistingObjectTag/username_owner"
│       └── Object has no tags → Condition TRUE → DENY applies
└── Result: DENIED (explicit deny in bucket policy)
```

## Mental Models

### The "Doors and Walls" Model
- **Allows = Doors**: You need at least one open door to get through
- **Denies = Walls**: One wall blocks you regardless of doors
- **Conditions = Locks**: All locks on a door must be opened

### The "Union vs Intersection" Model
- **Same-Account Allows**: Union (IAM ∪ Resource Policy)
- **Same-Account Denies**: Union (any deny blocks)
- **Cross-Account Allows**: Intersection (IAM ∩ Resource Policy)

### The "Traffic Light" Model
- **Explicit Deny**: Red light (stop immediately)
- **Explicit Allow**: Green light (proceed if no red)
- **No Explicit Allow**: No light (default to stop)

## Quick Reference Algorithm

```python
def is_action_allowed(principal, action, resource):
    # Step 1: Check for explicit deny
    if any_explicit_deny(principal, action, resource):
        return False
    
    # Step 2: Check account relationship
    if same_account(principal, resource):
        # Same account: OR logic
        if iam_allows(principal, action, resource) or \
           resource_policy_allows(principal, action, resource):
            # Step 3: Evaluate all conditions
            if all_conditions_met(principal, action, resource):
                return True
    else:
        # Cross-account: AND logic
        if iam_allows(principal, action, resource) and \
           resource_policy_allows(principal, action, resource):
            # Step 3: Evaluate all conditions
            if all_conditions_met(principal, action, resource):
                return True
    
    # Step 4: Implicit deny
    return False
```

## Common Pitfalls

### 1. Assuming Bucket Policy is Required
**Wrong:** "I need a bucket policy to allow access"
**Right:** For same-account, IAM policy alone is sufficient

### 2. Forgetting Explicit Deny Precedence
**Wrong:** "I have an allow, so it should work"
**Right:** Check for explicit denies first - they always win

### 3. Misunderstanding Condition Evaluation
**Wrong:** "One of my conditions is met, so access is granted"
**Right:** ALL conditions across ALL applicable policies must be true

### 4. Cross-Account Confusion
**Wrong:** "I added bucket policy allow, why can't Account B access?"
**Right:** Account B also needs IAM permissions in their account

## Best Practices

1. **Start with IAM policies** for baseline permissions
2. **Use bucket policies** for:
   - Cross-account access
   - Additional security conditions (IP, MFA, encryption)
   - Public access (carefully!)
   - Explicit denies for sensitive data

3. **Test with IAM Policy Simulator**: [Policy Simulator](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_testing-policies.html)

4. **Document your intent** - Complex policies can be confusing later

5. **Use explicit denies** sparingly but strategically - they're hard to override

## Summary

The key to understanding AWS policy evaluation is remembering:
- Explicit deny > Explicit allow > Implicit deny
- Same-account needs one allow, cross-account needs two
- All conditions must be met (most restrictive wins)
- Resource policies are optional for same-account access

When troubleshooting access issues, always check:
1. Is there an explicit deny?
2. Is there at least one allow?
3. Are all conditions satisfied?
4. Is this cross-account (needs both allows)?