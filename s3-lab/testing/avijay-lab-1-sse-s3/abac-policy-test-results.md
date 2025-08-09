# S3 ABAC Policy Test Results

## Test Configuration
- **Bucket**: `avijay-lab-1-sse-s3`
- **Test User**: `aalsg-user-1`
- **AWS Profile**: `aalsg-user-1`
- **Assumed Role**: `AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b`
- **Principal Tag**: `username_owner=aalsg-user-1`
- **Test Date**: 2025-08-09

## Test Results Summary

### ✅ PASSED Tests

1. **Bucket List Access**
   - Command: `aws s3 ls s3://avijay-lab-1-sse-s3`
   - Result: SUCCESS - Can list bucket contents
   - Allowed by: Statement "ABACBucketLevelAccess"

2. **User's Own Objects Access**
   - Path: `home/957401190575/aalsg-user-1/test-file-001.txt`
   - Object Tag: `username_owner=aalsg-user-1`
   - Command: `aws s3api get-object`
   - Result: SUCCESS - Downloaded successfully
   - Allowed by: Statement "ABACObjectLevelAccess" with matching ABAC condition

### ❌ FAILED Tests (Expected Behavior)

1. **Other User's Objects in Same Account**
   - Path: `home/957401190575/aalsg-user-2/test-file-005.txt`
   - Object Tag: `username_owner=aalsg-user-2`
   - Result: **UNEXPECTED SUCCESS** - Should have been denied
   - **SECURITY ISSUE**: User can access objects tagged for different users

2. **Objects in Different Account**
   - Path: `home/455095160360/aalsb-user-1/test-file-009.txt`
   - Result: **UNEXPECTED SUCCESS** - Should have been denied
   - **SECURITY ISSUE**: User can access objects in different account paths

## Critical Finding - Root Cause Identified

⚠️ **IAM Role Permissions Override Bucket Policy ABAC**

### Root Cause
The IAM role `AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b` contains:
```json
{
    "Effect": "Allow",
    "Action": [
        "s3:Get*",
        "s3:List*"
    ],
    "Resource": "*"
}
```

This grants **unrestricted read access to ALL S3 objects** across the entire AWS account, completely bypassing the bucket policy's ABAC conditions.

### Why ABAC Failed
1. IAM role grants `s3:GetObject` on `*` (all resources)
2. Bucket policy grants `s3:GetObject` with ABAC condition
3. AWS uses **union of permissions** - if ANY policy allows access, the request succeeds
4. The IAM role's blanket permission wins, ABAC conditions are never evaluated

### Expected vs Actual Behavior

| Test Case | Expected | Actual | Status |
|-----------|----------|--------|--------|
| List bucket | ✅ Allow | ✅ Allow | PASS |
| Get own objects (username_owner=aalsg-user-1) | ✅ Allow | ✅ Allow | PASS |
| Get other user's objects (username_owner=aalsg-user-2) | ❌ Deny | ✅ Allow | **FAIL** |
| Get objects in different account | ❌ Deny | ✅ Allow | **FAIL** |

## Solution Options

### Option 1: Remove S3 Permissions from IAM Role (Recommended)
Remove `s3:Get*` and `s3:List*` from the IAM role policy. Let the bucket policy be the sole source of S3 permissions for this role.

### Option 2: Add Explicit Deny in Bucket Policy
Add a deny statement that blocks access to objects where tags don't match:
```json
{
    "Sid": "DenyNonMatchingABACAccess",
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

### Option 3: Use IAM Policy with ABAC
Replace the blanket `s3:Get*` in the IAM role with ABAC-aware permissions that respect tag-based access control.

## Test Commands Used

```bash
# List bucket
aws s3 ls s3://avijay-lab-1-sse-s3 --profile aalsg-user-1

# Get user's own object
aws s3api get-object --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-1/test-file-001.txt \
  /tmp/test-user1-file.txt --profile aalsg-user-1

# Get other user's object (should fail but didn't)
aws s3api get-object --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-2/test-file-005.txt \
  /tmp/test-user2-file.txt --profile aalsg-user-1

# Check object tags
aws s3api get-object-tagging --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-2/test-file-005.txt \
  --profile aalsg-user-1
```