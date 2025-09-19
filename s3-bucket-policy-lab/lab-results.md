# S3 Bucket Policy Access Testing Lab

## Lab Overview
Testing different S3 bucket policy configurations:
1. Account-level access policy
2. User-specific access policy  
3. Role-based access policy

## Setup

### Test User Configuration
- **User**: aalsg-iam-user1
- **Account**: 957401190575
- **ARN**: arn:aws:iam::957401190575:user/aalsg-iam-user1
- **Group**: GenericUserGroup (no permissions attached)
- **AWS CLI Profile**: aalsg-iam-user1

### Default Profile Identity
- **User**: iamadmin
- **Account**: 957401190575
- **ARN**: arn:aws:iam::957401190575:user/iamadmin

## Test 1: Account-Level Bucket Policy

### Bucket Creation
```bash
TIMESTAMP=$(date +%s)
BUCKET_NAME="avijay-account-level-bucket-${TIMESTAMP}"
aws s3 mb s3://${BUCKET_NAME} --profile default
```
**Created Bucket**: avijay-account-level-bucket-1755931757

### Bucket Policy
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

### Testing Results

#### Test without IAM permissions (aalsg-iam-user1)
```bash
# Attempt upload
aws s3 cp /tmp/test-account-level.txt s3://avijay-account-level-bucket-1755931757/ --profile aalsg-iam-user1
# Result: AccessDenied - User has no IAM permissions

# Attempt list
aws s3 ls s3://avijay-account-level-bucket-1755931757/ --profile aalsg-iam-user1  
# Result: AccessDenied - User has no IAM permissions
```

**Finding**: Account-level bucket policy (arn:aws:iam::957401190575:root) does NOT grant access to users without IAM permissions. The bucket policy allows the account, but individual identities still need IAM permissions to access.

## Test 2: User-Specific Bucket Policy

### Bucket Creation
```bash
TIMESTAMP=$(date +%s)
BUCKET_NAME="avijay-user-specific-bucket-${TIMESTAMP}"
aws s3 mb s3://${BUCKET_NAME} --profile default
```
**Created Bucket**: avijay-user-specific-bucket-1755931868

### Bucket Policy
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

### Testing Results

#### Test with specific user (aalsg-iam-user1)
```bash
# Upload test
aws s3 cp /tmp/test-user-specific.txt s3://avijay-user-specific-bucket-1755931868/ --profile aalsg-iam-user1
# Result: SUCCESS - File uploaded

# List test
aws s3 ls s3://avijay-user-specific-bucket-1755931868/ --profile aalsg-iam-user1
# Result: SUCCESS - Listed object: test-user-specific.txt
```

**Finding**: User-specific bucket policy DOES grant access even when the user has no IAM permissions. The bucket policy directly allows the specific user principal.

## Test 3: Role-Based Bucket Policy

### Role Creation
```bash
TIMESTAMP=$(date +%s)
ROLE_NAME="S3TestRole-${TIMESTAMP}"
aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://trust-policy.json --profile default
```
**Created Role**: S3TestRole-1755931935
**Role ARN**: arn:aws:iam::957401190575:role/S3TestRole-1755931935
**Note**: Role has NO attached permissions or permission boundaries

### Trust Policy for Role
```json
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
```

### Bucket Creation
```bash
TIMESTAMP=$(date +%s)
BUCKET_NAME="avijay-role-specific-bucket-${TIMESTAMP}"
aws s3 mb s3://${BUCKET_NAME} --profile default
```
**Created Bucket**: avijay-role-specific-bucket-1755931969

### Bucket Policy
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

### Testing Results

#### Assume role and test access
```bash
# Assume role
aws sts assume-role --role-arn arn:aws:iam::957401190575:role/S3TestRole-1755931935 --role-session-name test-session --profile default

# Upload test with assumed role
aws s3 cp /tmp/test-role.txt s3://avijay-role-specific-bucket-1755931969/ --profile test-role
# Result: SUCCESS - File uploaded

# List test with assumed role  
aws s3 ls s3://avijay-role-specific-bucket-1755931969/ --profile test-role
# Result: SUCCESS - Listed object: test-role.txt
```

**Finding**: Role-specific bucket policy DOES grant access even when the role has no IAM permissions. The bucket policy directly allows the specific role principal.

## Summary of Findings

1. **Account-level bucket policy** (Principal: "arn:aws:iam::957401190575:root")
   - Does NOT grant access to users without IAM permissions
   - Acts as a permission boundary - users still need IAM permissions

2. **User-specific bucket policy** (Principal: "arn:aws:iam::957401190575:user/aalsg-iam-user1")
   - DOES grant access even without IAM permissions
   - Bucket policy directly authorizes the specific user

3. **Role-specific bucket policy** (Principal: "arn:aws:iam::957401190575:role/S3TestRole-1755931935")
   - DOES grant access even without IAM permissions attached to the role
   - Bucket policy directly authorizes the specific role

## Key Takeaway
Bucket policies with specific principal ARNs (user or role) can grant access independently of IAM permissions. However, account-level principals require the identity to also have IAM permissions.