# S3 Bucket Policy Access Testing - Comprehensive Analysis

## Test Environment

### AWS Account
- **Account ID**: 957401190575
- **Region**: us-east-1

## IAM Identities Analysis

### 1. aalsg-iam-user1 (Test User)
```json
{
  "UserName": "aalsg-iam-user1",
  "UserId": "AIDA552MO2CX45CYROHGW",
  "Arn": "arn:aws:iam::957401190575:user/aalsg-iam-user1",
  "Groups": ["GenericUserGroup"],
  "AttachedPolicies": [],
  "InlinePolicies": []
}
```

**Group Analysis**: GenericUserGroup
- **Group ARN**: arn:aws:iam::957401190575:group/GenericUserGroup
- **Attached Policies**: None
- **Inline Policies**: None
- **Effective Permissions**: NONE

### 2. iamadmin (Default Profile User)
```json
{
  "UserName": "iamadmin",
  "UserId": "AIDA552MO2CXTUOQ4KDXY",
  "Arn": "arn:aws:iam::957401190575:user/iamadmin",
  "AttachedPolicies": ["AdministratorAccess"],
  "InlinePolicies": []
}
```

**Effective Permissions**: Full administrative access (*)

### 3. S3TestRole-1755931935 (Test Role)
```json
{
  "RoleName": "S3TestRole-1755931935",
  "RoleId": "AROA552MO2CX3R7VWOOWM",
  "Arn": "arn:aws:iam::957401190575:role/S3TestRole-1755931935",
  "AttachedPolicies": [],
  "InlinePolicies": [],
  "TrustPolicy": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::957401190575:root"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
}
```

**Effective Permissions**: NONE (no policies attached)

## S3 Bucket Configurations

### Bucket 1: avijay-account-level-bucket-1755931757

**Bucket Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountLevelAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:root"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::avijay-account-level-bucket-1755931757",
        "arn:aws:s3:::avijay-account-level-bucket-1755931757/*"
      ]
    }
  ]
}
```

**Policy Analysis**:
- Principal: Account root (arn:aws:iam::957401190575:root)
- Actions: All S3 actions (s3:*)
- Resources: Bucket and all objects

### Bucket 2: avijay-user-specific-bucket-1755931868

**Bucket Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUserSpecificAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:user/aalsg-iam-user1"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::avijay-user-specific-bucket-1755931868",
        "arn:aws:s3:::avijay-user-specific-bucket-1755931868/*"
      ]
    }
  ]
}
```

**Policy Analysis**:
- Principal: Specific user (aalsg-iam-user1)
- Actions: All S3 actions (s3:*)
- Resources: Bucket and all objects

### Bucket 3: avijay-role-specific-bucket-1755931969

**Bucket Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleSpecificAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:role/S3TestRole-1755931935"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::avijay-role-specific-bucket-1755931969",
        "arn:aws:s3:::avijay-role-specific-bucket-1755931969/*"
      ]
    }
  ]
}
```

**Policy Analysis**:
- Principal: Specific role (S3TestRole-1755931935)
- Actions: All S3 actions (s3:*)
- Resources: Bucket and all objects

## Access Tests and Results

### Test 1: Account-Level Bucket (avijay-account-level-bucket-1755931757)

| Test User | Operation | Result | Error Message |
|-----------|-----------|--------|---------------|
| **aalsg-iam-user1** | s3:PutObject | ❌ DENIED | "no identity-based policy allows the s3:PutObject action" |
| **aalsg-iam-user1** | s3:ListBucket | ❌ DENIED | "no identity-based policy allows the s3:ListBucket action" |
| **iamadmin** | s3:PutObject | ✅ SUCCESS | File uploaded successfully |
| **iamadmin** | s3:ListBucket | ✅ SUCCESS | Objects listed successfully |

**Analysis**: 
- Bucket policy principal `arn:aws:iam::957401190575:root` means "any principal in the account that has IAM permissions"
- aalsg-iam-user1 has NO IAM permissions, so access is denied
- iamadmin has AdministratorAccess policy, so access is allowed

### Test 2: User-Specific Bucket (avijay-user-specific-bucket-1755931868)

| Test User | Operation | Result | Notes |
|-----------|-----------|--------|-------|
| **aalsg-iam-user1** | s3:PutObject | ✅ SUCCESS | Direct bucket policy grant |
| **aalsg-iam-user1** | s3:ListBucket | ✅ SUCCESS | Direct bucket policy grant |
| **iamadmin** | s3:PutObject | ✅ SUCCESS | IAM AdministratorAccess overrides |
| **iamadmin** | s3:ListBucket | ✅ SUCCESS | IAM AdministratorAccess overrides |

**Analysis**:
- Bucket policy explicitly grants `arn:aws:iam::957401190575:user/aalsg-iam-user1` access
- aalsg-iam-user1 can access despite having NO IAM permissions
- iamadmin can access due to AdministratorAccess (not bucket policy)

### Test 3: Role-Specific Bucket (avijay-role-specific-bucket-1755931969)

| Test Identity | Operation | Result | Notes |
|---------------|-----------|--------|-------|
| **S3TestRole (assumed)** | s3:PutObject | ✅ SUCCESS | Direct bucket policy grant |
| **S3TestRole (assumed)** | s3:ListBucket | ✅ SUCCESS | Direct bucket policy grant |
| **aalsg-iam-user1** | s3:ListBucket | ❌ DENIED | Not the role, no IAM permissions |
| **iamadmin** | s3:PutObject | ✅ SUCCESS | IAM AdministratorAccess overrides |

**Analysis**:
- Bucket policy explicitly grants `arn:aws:iam::957401190575:role/S3TestRole-1755931935` access
- Role can access despite having NO attached policies
- aalsg-iam-user1 cannot access (not assuming the role)
- iamadmin can access due to AdministratorAccess

## AWS Permission Evaluation Logic

### How AWS Evaluates Permissions

1. **Explicit Deny**: Always wins (none in our tests)
2. **Evaluation Union**: AWS evaluates BOTH:
   - Identity-based policies (IAM user/role policies)
   - Resource-based policies (S3 bucket policies)
3. **Allow from Either Source**: Access granted if EITHER allows

### Permission Evaluation for Each Scenario

#### Scenario 1: Account-Level Principal (`:root`)
```
Bucket Policy: Principal = "arn:aws:iam::957401190575:root"
```
- **Meaning**: Any principal in the account WITH IAM permissions
- **NOT**: Blanket allow for all identities in the account
- **Evaluation**:
  - aalsg-iam-user1: Bucket allows IF has IAM permissions → No IAM permissions → DENY
  - iamadmin: Bucket allows IF has IAM permissions → Has AdministratorAccess → ALLOW

#### Scenario 2: Specific User Principal
```
Bucket Policy: Principal = "arn:aws:iam::957401190575:user/aalsg-iam-user1"
```
- **Meaning**: This specific user is allowed
- **Evaluation**:
  - aalsg-iam-user1: Bucket policy explicitly allows → ALLOW (no IAM needed)
  - iamadmin: No bucket policy grant, but IAM AdministratorAccess → ALLOW

#### Scenario 3: Specific Role Principal
```
Bucket Policy: Principal = "arn:aws:iam::957401190575:role/S3TestRole-1755931935"
```
- **Meaning**: This specific role is allowed when assumed
- **Evaluation**:
  - Assumed role session: Bucket policy explicitly allows → ALLOW (no IAM needed)
  - aalsg-iam-user1: Not the role, no IAM permissions → DENY

## Key Findings

1. **Account root principal (`:root`) is NOT a wildcard allow**
   - It means "any identity in this account that also has IAM permissions"
   - Acts as a permission boundary, not a grant

2. **Specific principal ARNs grant direct access**
   - User-specific and role-specific principals in bucket policies grant access
   - No IAM permissions required when explicitly named

3. **IAM Administrator access overrides resource restrictions**
   - AdministratorAccess policy grants access regardless of bucket policy
   - This is why iamadmin could access all buckets

4. **Permission evaluation is a UNION**
   - Access granted if EITHER identity-based OR resource-based policy allows
   - Explicit denies always win (not tested here)

## Security Best Practices Validated

1. ✅ **Principle of Least Privilege**: Account-level policies don't bypass IAM
2. ✅ **Defense in Depth**: Multiple layers of permission evaluation
3. ✅ **Explicit Grants**: Specific principals in bucket policies work as expected
4. ✅ **Role Isolation**: Roles must be assumed to use their permissions

## Executable Test Commands

### Prerequisites

```bash
# Set up the test user profile (aalsg-iam-user1)
aws configure set aws_access_key_id [REDACTED_ACCESS_KEY_ID] --profile aalsg-iam-user1
aws configure set aws_secret_access_key [REDACTED_SECRET_ACCESS_KEY] --profile aalsg-iam-user1
aws configure set region us-east-1 --profile aalsg-iam-user1

# Verify profiles are working
aws sts get-caller-identity --profile default
aws sts get-caller-identity --profile aalsg-iam-user1

# Check IAM permissions for test user
aws iam get-user --user-name aalsg-iam-user1 --profile default
aws iam list-attached-user-policies --user-name aalsg-iam-user1 --profile default
aws iam list-user-policies --user-name aalsg-iam-user1 --profile default
aws iam list-groups-for-user --user-name aalsg-iam-user1 --profile default
```

### Test 1: Account-Level Bucket Policy

#### Setup
```bash
# Create bucket with timestamp
TIMESTAMP=$(date +%s)
ACCOUNT_BUCKET="test-account-level-${TIMESTAMP}"
aws s3 mb s3://${ACCOUNT_BUCKET} --profile default
echo "Created bucket: ${ACCOUNT_BUCKET}"

# Create account-level policy file
cat > /tmp/account-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAccountLevelAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:root"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME",
        "arn:aws:s3:::BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

# Replace bucket name in policy
sed -i.bak "s/BUCKET_NAME/${ACCOUNT_BUCKET}/g" /tmp/account-policy.json

# Apply bucket policy
aws s3api put-bucket-policy --bucket ${ACCOUNT_BUCKET} --policy file:///tmp/account-policy.json --profile default

# Verify policy was applied
aws s3api get-bucket-policy --bucket ${ACCOUNT_BUCKET} --profile default | jq -r '.Policy' | jq .
```

#### Test Commands
```bash
# Test with aalsg-iam-user1 (no IAM permissions) - SHOULD FAIL
echo "Testing aalsg-iam-user1 (no IAM permissions)..."
echo "Test content" > /tmp/test-account.txt

# Upload test - Expected: AccessDenied
aws s3 cp /tmp/test-account.txt s3://${ACCOUNT_BUCKET}/ --profile aalsg-iam-user1

# List test - Expected: AccessDenied  
aws s3 ls s3://${ACCOUNT_BUCKET}/ --profile aalsg-iam-user1

# Test with iamadmin (has AdministratorAccess) - SHOULD SUCCEED
echo "Testing iamadmin (AdministratorAccess)..."

# Upload test - Expected: Success
aws s3 cp /tmp/test-account.txt s3://${ACCOUNT_BUCKET}/ --profile default

# List test - Expected: Success
aws s3 ls s3://${ACCOUNT_BUCKET}/ --profile default
```

### Test 2: User-Specific Bucket Policy

#### Setup
```bash
# Create bucket
TIMESTAMP=$(date +%s)
USER_BUCKET="test-user-specific-${TIMESTAMP}"
aws s3 mb s3://${USER_BUCKET} --profile default
echo "Created bucket: ${USER_BUCKET}"

# Create user-specific policy file
cat > /tmp/user-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowUserSpecificAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:user/aalsg-iam-user1"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::BUCKET_NAME",
        "arn:aws:s3:::BUCKET_NAME/*"
      ]
    }
  ]
}
EOF

# Replace bucket name
sed -i.bak "s/BUCKET_NAME/${USER_BUCKET}/g" /tmp/user-policy.json

# Apply bucket policy
aws s3api put-bucket-policy --bucket ${USER_BUCKET} --policy file:///tmp/user-policy.json --profile default

# Verify policy
aws s3api get-bucket-policy --bucket ${USER_BUCKET} --profile default | jq -r '.Policy' | jq .
```

#### Test Commands
```bash
# Test with aalsg-iam-user1 - SHOULD SUCCEED (bucket policy grants access)
echo "Testing aalsg-iam-user1 (granted by bucket policy)..."
echo "User test content" > /tmp/test-user.txt

# Upload test - Expected: Success
aws s3 cp /tmp/test-user.txt s3://${USER_BUCKET}/ --profile aalsg-iam-user1

# List test - Expected: Success
aws s3 ls s3://${USER_BUCKET}/ --profile aalsg-iam-user1

# Download test - Expected: Success
aws s3 cp s3://${USER_BUCKET}/test-user.txt /tmp/downloaded-user.txt --profile aalsg-iam-user1
cat /tmp/downloaded-user.txt

# Test with iamadmin - SHOULD SUCCEED (IAM permissions)
echo "Testing iamadmin..."
aws s3 ls s3://${USER_BUCKET}/ --profile default
```

### Test 3: Role-Based Bucket Policy

#### Setup
```bash
# Create IAM role with no permissions
TIMESTAMP=$(date +%s)
ROLE_NAME="S3TestRole-${TIMESTAMP}"

# Create trust policy
cat > /tmp/trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::957401190575:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file:///tmp/trust-policy.json --profile default

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name ${ROLE_NAME} --query 'Role.Arn' --output text --profile default)
echo "Created role: ${ROLE_ARN}"

# Verify role has no policies
aws iam list-attached-role-policies --role-name ${ROLE_NAME} --profile default
aws iam list-role-policies --role-name ${ROLE_NAME} --profile default

# Create bucket
ROLE_BUCKET="test-role-specific-${TIMESTAMP}"
aws s3 mb s3://${ROLE_BUCKET} --profile default
echo "Created bucket: ${ROLE_BUCKET}"

# Create role-specific policy
cat > /tmp/role-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowRoleSpecificAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${ROLE_ARN}"
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${ROLE_BUCKET}",
        "arn:aws:s3:::${ROLE_BUCKET}/*"
      ]
    }
  ]
}
EOF

# Apply bucket policy
aws s3api put-bucket-policy --bucket ${ROLE_BUCKET} --policy file:///tmp/role-policy.json --profile default

# Verify policy
aws s3api get-bucket-policy --bucket ${ROLE_BUCKET} --profile default | jq -r '.Policy' | jq .
```

#### Test Commands
```bash
# Test 1: Try with aalsg-iam-user1 directly - SHOULD FAIL
echo "Testing direct access with aalsg-iam-user1 (should fail)..."
aws s3 ls s3://${ROLE_BUCKET}/ --profile aalsg-iam-user1

# Test 2: Assume role and test - SHOULD SUCCEED
echo "Assuming role and testing..."

# Assume the role
CREDS=$(aws sts assume-role --role-arn ${ROLE_ARN} --role-session-name test-session --profile default --output json)

# Extract credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

# Verify assumed role identity
aws sts get-caller-identity

# Test S3 access with assumed role - Expected: Success
echo "Role test content" > /tmp/test-role.txt
aws s3 cp /tmp/test-role.txt s3://${ROLE_BUCKET}/
aws s3 ls s3://${ROLE_BUCKET}/

# Clean up environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Alternative: Configure a profile for the assumed role
aws sts assume-role --role-arn ${ROLE_ARN} --role-session-name test-session2 --profile default > /tmp/role-creds.json

aws configure set aws_access_key_id $(cat /tmp/role-creds.json | jq -r '.Credentials.AccessKeyId') --profile test-role
aws configure set aws_secret_access_key $(cat /tmp/role-creds.json | jq -r '.Credentials.SecretAccessKey') --profile test-role
aws configure set aws_session_token $(cat /tmp/role-creds.json | jq -r '.Credentials.SessionToken') --profile test-role
aws configure set region us-east-1 --profile test-role

# Test with role profile
aws s3 ls s3://${ROLE_BUCKET}/ --profile test-role
```

### Cleanup Commands

```bash
# Delete test objects and buckets
aws s3 rm s3://${ACCOUNT_BUCKET} --recursive --profile default
aws s3 rb s3://${ACCOUNT_BUCKET} --profile default

aws s3 rm s3://${USER_BUCKET} --recursive --profile default
aws s3 rb s3://${USER_BUCKET} --profile default

aws s3 rm s3://${ROLE_BUCKET} --recursive --profile default
aws s3 rb s3://${ROLE_BUCKET} --profile default

# Delete IAM role
aws iam delete-role --role-name ${ROLE_NAME} --profile default

# Clean up temp files
rm -f /tmp/account-policy.json /tmp/account-policy.json.bak
rm -f /tmp/user-policy.json /tmp/user-policy.json.bak
rm -f /tmp/role-policy.json
rm -f /tmp/trust-policy.json
rm -f /tmp/role-creds.json
rm -f /tmp/test-*.txt
rm -f /tmp/downloaded-*.txt

# Remove test profiles (optional)
aws configure --profile test-role set aws_access_key_id ""
aws configure --profile test-role set aws_secret_access_key ""
aws configure --profile test-role set aws_session_token ""
```

### Verification Commands

```bash
# Verify all resources are cleaned up
aws s3 ls --profile default | grep -E "test-(account|user|role)-"
aws iam list-roles --profile default | jq '.Roles[].RoleName' | grep S3TestRole

# Check existing buckets from the lab
aws s3 ls --profile default | grep avijay
```

## Tips for Running Tests

1. **Save bucket names**: Export them as environment variables for easy reuse
   ```bash
   export ACCOUNT_BUCKET="test-account-level-$(date +%s)"
   export USER_BUCKET="test-user-specific-$(date +%s)"
   export ROLE_BUCKET="test-role-specific-$(date +%s)"
   ```

2. **Batch testing**: Create a script to run all tests
   ```bash
   #!/bin/bash
   set -e
   echo "Running S3 bucket policy tests..."
   # Add all test commands here
   ```

3. **Monitor errors**: Use `2>&1` to capture both stdout and stderr
   ```bash
   aws s3 cp file.txt s3://bucket/ --profile user 2>&1 | tee test-output.log
   ```

4. **JSON parsing**: Use `jq` for cleaner output
   ```bash
   aws s3api get-bucket-policy --bucket ${BUCKET} --profile default | jq -r '.Policy' | jq .
   ```