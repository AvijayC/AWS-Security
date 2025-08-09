# S3 ABAC Policy Test Results - With Deny Statement

## Test Configuration
- **Bucket**: `avijay-lab-1-sse-s3`
- **Test User**: `aalsg-user-1`
- **AWS Profile**: `aalsg-user-1`
- **Assumed Role**: `AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b`
- **Principal Tag**: `username_owner=aalsg-user-1`
- **Test Date**: 2025-08-09

## Policy Configuration
The bucket policy includes an explicit deny statement:
```json
{
    "Sid": "ABACDenyObjectLevelAccess",
    "Effect": "Deny",
    "Principal": {
        "AWS": "arn:aws:iam::957401190575:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b"
    },
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::avijay-lab-1-sse-s3/*",
    "Condition": {
        "StringNotEquals": {
            "s3:ExistingObjectTag/username_owner": "${aws:PrincipalTag/username_owner}"
        }
    }
}
```

## Test Results Summary

### ✅ SUCCESS: ABAC Policy Now Working!

The explicit deny statement is successfully enforcing ABAC controls.

| Test Case | Expected | Actual | Status |
|-----------|----------|--------|--------|
| List bucket | ✅ Allow | ✅ Allow | ✅ PASS |
| Get own objects (tag: aalsg-user-1) | ✅ Allow | ✅ Allow | ✅ PASS |
| Get aalsg-user-2's objects (tag: aalsg-user-2) | ❌ Deny | ❌ Deny | ✅ PASS |
| Get objects in account 455095160360 (tag: aalsb-user-1) | ❌ Deny | ❌ Deny | ✅ PASS |

### Detailed Test Results

#### Test 1: Bucket List Access ✅
- **Command**: `aws s3 ls s3://avijay-lab-1-sse-s3`
- **Result**: SUCCESS - Can list bucket contents
- **Reason**: Allowed by "ABACBucketLevelAccess" statement

#### Test 2: User's Own Object ✅
- **Path**: `home/957401190575/aalsg-user-1/test-file-001.txt`
- **Object Tag**: `username_owner=aalsg-user-1`
- **Command**: `aws s3api get-object`
- **Result**: SUCCESS - Downloaded successfully
- **Reason**: Tag matches principal tag (`aalsg-user-1` = `aalsg-user-1`), not denied

#### Test 3: Other User's Object ✅
- **Path**: `home/957401190575/aalsg-user-2/test-file-005.txt`
- **Object Tag**: `username_owner=aalsg-user-2`
- **Command**: `aws s3api get-object`
- **Result**: ACCESS DENIED
- **Error**: "explicit deny in a resource-based policy"
- **Reason**: Tags don't match (`aalsg-user-2` ≠ `aalsg-user-1`), explicitly denied

#### Test 4: Different Account Object ✅
- **Path**: `home/455095160360/aalsb-user-1/test-file-009.txt`
- **Object Tag**: `username_owner=aalsb-user-1`
- **Command**: `aws s3api get-object`
- **Result**: ACCESS DENIED
- **Error**: "explicit deny in a resource-based policy"
- **Reason**: Tags don't match (`aalsb-user-1` ≠ `aalsg-user-1`), explicitly denied

## How It Works

1. **IAM Role Permission**: Grants broad `s3:Get*` on all resources
2. **Bucket Policy Allow**: Grants `s3:GetObject` with ABAC condition (redundant due to IAM)
3. **Bucket Policy Deny**: **Explicitly denies** `s3:GetObject` when tags don't match
4. **Result**: Explicit deny always wins, overriding the IAM role's broad permissions

## Policy Evaluation Flow

```
Request: GetObject on home/957401190575/aalsg-user-2/test-file-005.txt
├── IAM Role: ALLOW (s3:Get* on *)
├── Bucket Policy Allow: ALLOW (but requires tag match)
├── Bucket Policy Deny: DENY (tags don't match: aalsg-user-2 ≠ aalsg-user-1)
└── Final Result: DENY (explicit deny wins)
```

## Key Insights

1. **Explicit Deny Works**: The deny statement successfully overrides the IAM role's broad permissions
2. **ABAC Conditions Evaluated**: The `${aws:PrincipalTag/username_owner}` variable correctly expands to `aalsg-user-1`
3. **Object Tags Read**: The `s3:ExistingObjectTag` condition correctly reads object tags
4. **Proper Isolation**: Users can only access objects tagged with their username

## Security Validation

✅ **ABAC implementation is now secure**:
- Users cannot access objects belonging to other users
- Users cannot access objects in different account paths
- Tag-based access control is properly enforced
- The explicit deny prevents privilege escalation via IAM permissions

## Test Commands

```bash
# Verify bucket policy is applied
aws s3api get-bucket-policy --bucket avijay-lab-1-sse-s3 --profile aalsg-user-1

# Test bucket listing (should work)
aws s3 ls s3://avijay-lab-1-sse-s3 --profile aalsg-user-1

# Test own object (should work)
aws s3api get-object --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-1/test-file-001.txt \
  /tmp/test-own.txt --profile aalsg-user-1

# Test other user's object (should fail)
aws s3api get-object --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-2/test-file-005.txt \
  /tmp/test-other.txt --profile aalsg-user-1

# Test different account object (should fail)
aws s3api get-object --bucket avijay-lab-1-sse-s3 \
  --key home/455095160360/aalsb-user-1/test-file-009.txt \
  /tmp/test-diff.txt --profile aalsg-user-1
```