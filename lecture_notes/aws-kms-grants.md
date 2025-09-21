# AWS KMS Grants - Comprehensive Guide

## What Are KMS Grants?

KMS grants are **temporary, flexible permission mechanisms** that allow AWS principals to use KMS keys for cryptographic operations without modifying key policies or IAM policies. Think of grants as temporary access passes that can be quickly created, used, and removed.

### Key Characteristics
- **Temporary and revocable** - Can be created and deleted without policy changes
- **Single KMS key scope** - Each grant applies to exactly one KMS key
- **Allow-only permissions** - Grants can only allow access, never deny it
- **One grantee principal** - Each grant has a single recipient
- **Limited operations** - Only specific KMS operations can be granted

## Why Use KMS Grants?

### Primary Use Cases

1. **AWS Service Integration**
   - Services like RDS, EBS, and S3 use grants to encrypt data on your behalf
   - Service creates grant → performs encryption → retires grant immediately

2. **Temporary Cross-Account Access**
   - Grant permissions to another AWS account without permanent policy changes
   - Useful for short-term data sharing or processing

3. **Delegated Permissions**
   - Allow users to delegate their KMS permissions to others temporarily
   - Common in CI/CD pipelines and automated workflows

## Grants vs. Key Policies vs. IAM Policies

| Aspect | Grants | Key Policies | IAM Policies |
|--------|--------|--------------|--------------|
| **Scope** | Single KMS key | Single KMS key | Multiple resources |
| **Permanence** | Temporary | Permanent | Permanent |
| **Modification Speed** | Instant creation/deletion | Requires policy update | Requires policy update |
| **Permission Type** | Allow only | Allow and Deny | Allow and Deny |
| **Use Case** | Temporary access | Primary key access control | User/role permissions |

## How Grants Work

### The Grant Lifecycle

```
1. Creation → 2. Propagation → 3. Usage → 4. Retirement/Revocation
```

### Eventual Consistency and Grant Tokens

Due to AWS KMS's eventual consistency model, newly created grants might not be immediately available across all KMS endpoints. **Grant tokens** solve this problem:

- **What**: A unique, non-secret string identifier for a grant
- **Why**: Allows immediate use of grant permissions
- **When**: Use when you need grant permissions immediately after creation
- **How**: Pass the grant token in API calls until the grant propagates

## Creating and Managing Grants

### Required Permissions

To create a grant, you need:
- `kms:CreateGrant` permission on the KMS key
- Can come from key policy, IAM policy, or another grant

### Grant Operations Available

**Cryptographic Operations:**
- `Encrypt`
- `Decrypt`
- `GenerateDataKey`
- `GenerateDataKeyWithoutPlaintext`
- `ReEncryptFrom`
- `ReEncryptTo`
- `Sign`
- `Verify`

**Management Operations:**
- `CreateGrant`
- `RetireGrant`
- `DescribeKey`
- `GetPublicKey`

### Grant Constraints

Grants can include **encryption context constraints** to ensure the grant is only used in specific contexts:

- **EncryptionContextEquals**: All specified pairs must match exactly
- **EncryptionContextSubset**: Specified pairs must be present (others allowed)

## Practical Examples

### Example 1: AWS Service Creating a Grant for EBS Encryption

```json
{
  "KeyId": "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012",
  "GranteePrincipal": "arn:aws:iam::123456789012:role/aws-service-role/ebs.amazonaws.com/AWSServiceRoleForEC2",
  "Operations": [
    "Decrypt",
    "GenerateDataKeyWithoutPlaintext",
    "CreateGrant"
  ],
  "RetiringPrincipal": "arn:aws:iam::123456789012:role/aws-service-role/ebs.amazonaws.com/AWSServiceRoleForEC2",
  "Constraints": {
    "EncryptionContextSubset": {
      "aws:ebs:id": "vol-0123456789abcdef0"
    }
  }
}
```

### Example 2: Creating a Grant with AWS CLI

```bash
# Create a grant for another account to decrypt data
aws kms create-grant \
  --key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012 \
  --grantee-principal arn:aws:iam::987654321098:role/DataProcessor \
  --operations Decrypt \
  --retiring-principal arn:aws:iam::987654321098:role/DataProcessor \
  --constraints EncryptionContextSubset={Department=Finance}
```

### Example 3: Using a Grant Token for Immediate Access

```python
import boto3

kms = boto3.client('kms')

# Create a grant and get the token
response = kms.create_grant(
    KeyId='alias/my-key',
    GranteePrincipal='arn:aws:iam::123456789012:role/MyRole',
    Operations=['Encrypt', 'Decrypt']
)

grant_token = response['GrantToken']
grant_id = response['GrantId']

# Use the grant token immediately (no wait needed)
encrypted = kms.encrypt(
    KeyId='alias/my-key',
    Plaintext=b'sensitive data',
    GrantTokens=[grant_token]  # Pass token for immediate access
)

# Later, retire the grant when done
kms.retire_grant(GrantId=grant_id)
```

### Example 4: Grant with Encryption Context Constraints

```bash
# Create a grant that only works with specific encryption context
aws kms create-grant \
  --key-id alias/application-key \
  --grantee-principal arn:aws:iam::123456789012:user/AppUser \
  --operations Encrypt Decrypt \
  --constraints '{
    "EncryptionContextEquals": {
      "ApplicationName": "OrderProcessing",
      "Environment": "Production"
    }
  }'

# The grant will only work when encryption context matches exactly
aws kms decrypt \
  --ciphertext-blob fileb://encrypted-data.bin \
  --encryption-context ApplicationName=OrderProcessing,Environment=Production
```

## Best Practices

### Security Best Practices

1. **Principle of Least Privilege**
   - Only grant minimum necessary operations
   - Use encryption context constraints when possible

2. **Lifecycle Management**
   - Always retire grants when no longer needed
   - Set up retiring principals for automatic cleanup
   - Monitor grant usage with CloudTrail

3. **Cross-Account Considerations**
   - Carefully audit cross-account grants
   - Use time-limited grants where possible
   - Document grant purposes and ownership

### Operational Best Practices

1. **Grant Limits**
   - Maximum 50,000 grants per KMS key
   - Monitor grant counts to avoid hitting limits
   - Clean up unused grants regularly

2. **Performance**
   - Use grant tokens for immediate access needs
   - Cache grant tokens during the propagation period
   - Consider grant overhead in high-throughput scenarios

3. **Monitoring**
   - Enable CloudTrail logging for all KMS operations
   - Monitor CreateGrant, RetireGrant, and RevokeGrant events
   - Set up alerts for unusual grant activity

## Common Pitfalls and Solutions

### Pitfall 1: Grants Not Working Immediately
**Problem**: Grant created but operations fail immediately after
**Solution**: Use grant tokens for immediate access

### Pitfall 2: Grants Accumulating Over Time
**Problem**: Hitting the 50,000 grant limit
**Solution**: Implement grant lifecycle management and regular cleanup

### Pitfall 3: Overly Permissive Grants
**Problem**: Grants with too many operations or no constraints
**Solution**: Apply principle of least privilege and use encryption context

### Pitfall 4: Cross-Account Grant Confusion
**Problem**: Grants not working across accounts as expected
**Solution**: Ensure both key policy and IAM policies allow the cross-account access

## Advanced Grant Patterns

### Pattern 1: Service-to-Service Delegation
```
Service A → Creates Grant → Service B uses KMS key → Auto-retires grant
```

### Pattern 2: Time-Limited Processing
```
Scheduler → Creates grant at start → Process runs → Grant retired at end
```

### Pattern 3: Hierarchical Delegation
```
Admin → Grants to Team Lead → Team Lead grants to Developer (with subset of permissions)
```

## Summary

KMS grants provide a powerful, flexible mechanism for temporary KMS key access that complements traditional policy-based permissions. They're essential for:
- AWS service integrations
- Temporary permission delegation
- Cross-account access scenarios
- Avoiding policy modification overhead

Remember: Grants are about **temporary, delegated access** - use them when you need flexibility and speed, but always with security best practices in mind.