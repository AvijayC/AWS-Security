# How to Assume ABAC-S3-Test-Role and Test with Session Tags

## Quick Start - Single Command Test

### Method 1: Using AWS CLI with Environment Variables
```bash
# Assume the role and get credentials
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --role-session-name test-session \
  --profile example-admin-profile \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text)

# Export credentials as environment variables
export AWS_ACCESS_KEY_ID=$(echo $CREDS | cut -d' ' -f1)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | cut -d' ' -f2)
export AWS_SESSION_TOKEN=$(echo $CREDS | cut -d' ' -f3)

# Now run any AWS command with the assumed role
aws s3 ls
aws sts get-caller-identity

# Clean up when done
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

### Method 2: One-liner with Subshell (No Environment Pollution)
```bash
# Run a single command with assumed role credentials
(
  eval $(aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
    --role-session-name test-session \
    --profile example-admin-profile \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text | \
    awk '{print "export AWS_ACCESS_KEY_ID="$1"; export AWS_SECRET_ACCESS_KEY="$2"; export AWS_SESSION_TOKEN="$3}')
  aws s3 ls
)
```

## Assuming Role with Session Tags (For ABAC)

### Basic Command with Tags
```bash
# Assume role with session tags
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --role-session-name test-user-1-session \
  --tags Key=Department,Value=Sales Key=Team,Value=General Key=Username,Value=test-user-1 \
  --profile example-admin-profile
```

### Full Example with ABAC Tags
```bash
# Step 1: Assume role with tags and capture credentials
ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --role-session-name user1-sales-test \
  --tags Key=Department,Value=Sales Key=Team,Value=General \
  --profile example-admin-profile \
  --output json)

# Step 2: Extract credentials
export AWS_ACCESS_KEY_ID=$(echo $ROLE_OUTPUT | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ROLE_OUTPUT | jq -r '.Credentials.SessionToken')

# Step 3: Test access with ABAC tags
aws s3 ls s3://example-bucket-1-sse-s3/
aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/Sales/  # Should work if ABAC allows Sales dept
aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/Engineering/  # Should fail for Sales dept tag

# Step 4: Verify your identity and session tags
aws sts get-caller-identity

# Step 5: Clean up
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

## Creating a Named Profile for Assumed Role

### Method 1: Manual Profile Configuration
Add to `~/.aws/config`:
```ini
[profile abac-test-role]
role_arn = arn:aws:iam::123456789012:role/ABAC-S3-Test-Role
source_profile = example-admin-profile
role_session_name = abac-test-session
```

Then use:
```bash
aws s3 ls --profile abac-test-role
```

### Method 2: Using aws-vault (Recommended for Security)
```bash
# Install aws-vault first
brew install aws-vault  # macOS

# Add the role
aws-vault add abac-test-role

# Execute commands with the role
aws-vault exec abac-test-role -- aws s3 ls
```

## Helper Script for Testing Different Users

Create `test-as-user.sh`:
```bash
#!/bin/bash

# Usage: ./test-as-user.sh <username> <department> <team>

USERNAME=${1:-test-user-1}
DEPARTMENT=${2:-Sales}
TEAM=${3:-General}

echo "Testing as: $USERNAME (Department: $DEPARTMENT, Team: $TEAM)"

# Assume role with tags
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --role-session-name "$USERNAME-test" \
  --tags Key=Department,Value=$DEPARTMENT Key=Team,Value=$TEAM Key=Username,Value=$USERNAME \
  --profile example-admin-profile \
  --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
  --output text 2>/dev/null)

if [ $? -ne 0 ]; then
  echo "Failed to assume role"
  exit 1
fi

# Export credentials
export AWS_ACCESS_KEY_ID=$(echo $CREDS | cut -d' ' -f1)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | cut -d' ' -f2)
export AWS_SESSION_TOKEN=$(echo $CREDS | cut -d' ' -f3)

# Run tests
echo "Identity:"
aws sts get-caller-identity --query 'Arn' --output text

echo -e "\nTesting S3 access:"
for bucket in example-bucket-{1..6}*; do
  printf "  %-35s: " "$bucket"
  if aws s3 ls "s3://$bucket/" >/dev/null 2>&1; then
    echo "✓ ACCESS"
  else
    echo "✗ DENIED"
  fi
done

# Test department-specific access if configured
echo -e "\nTesting department folders:"
echo "  $DEPARTMENT folder: "
aws s3 ls "s3://example-bucket-3-sse-s3-vpce-a/$DEPARTMENT/" 2>&1 | head -2

# Clean up
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
```

Make it executable and run:
```bash
chmod +x test-as-user.sh

# Test different users
./test-as-user.sh test-user-1 Sales General
./test-as-user.sh test-user-2 Engineering General
./test-as-user.sh test-user-3 Sales B
./test-as-user.sh test-user-4 Engineering B
```

## Testing All Users in a Loop

```bash
# Define users with their attributes
declare -A USERS
USERS["test-user-1"]="Sales,General"
USERS["test-user-2"]="Engineering,General"
USERS["test-user-3"]="Sales,B"
USERS["test-user-4"]="Engineering,B"

# Test each user
for username in "${!USERS[@]}"; do
  IFS=',' read -r dept team <<< "${USERS[$username]}"
  
  echo "=== Testing $username (Dept: $dept, Team: $team) ==="
  
  # Assume role with tags
  CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
    --role-session-name "$username-test" \
    --tags Key=Department,Value=$dept Key=Team,Value=$team \
    --profile example-admin-profile \
    --query 'Credentials' \
    --output json 2>/dev/null)
  
  if [ $? -eq 0 ]; then
    # Use credentials for testing
    AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.AccessKeyId') \
    AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.SecretAccessKey') \
    AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.SessionToken') \
    aws s3 ls s3://example-bucket-1-sse-s3/ 2>&1 | head -2
  else
    echo "Failed to assume role for $username"
  fi
  echo
done
```

## Important Notes

### 1. Session Duration
The role has `MaxSessionDuration: 3600` (1 hour). Your temporary credentials will expire after this time.

### 2. Permission Requirements
Your source profile (`example-admin-profile`) must have permission to assume the role:
```json
{
  "Effect": "Allow",
  "Action": "sts:AssumeRole",
  "Resource": "arn:aws:iam::123456789012:role/ABAC-S3-Test-Role"
}
```

### 3. Tagging Permissions
To use session tags, the role's trust policy must include `sts:TagSession` action (which yours does).

### 4. Credential Precedence
AWS CLI checks credentials in this order:
1. Environment variables (AWS_ACCESS_KEY_ID, etc.)
2. AWS credentials file
3. AWS config file with assume role
4. Instance profile (EC2)

### 5. Debugging
To see what credentials are being used:
```bash
aws sts get-caller-identity
```

To see the assumed role session details:
```bash
aws sts get-session-token  # Won't work with assumed role
aws sts get-caller-identity --query 'Arn' --output text  # Shows role session
```

## Common Errors and Solutions

### "Access Denied" when assuming role
```bash
# Check if your user can assume the role
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query 'Arn' --output text --profile example-admin-profile) \
  --action-names sts:AssumeRole \
  --resource-arns arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --profile example-admin-profile
```

### "Invalid session token" 
- Token might be expired (check 1-hour limit)
- Token might be malformed (check copy/paste)

### Tags not working
```bash
# Verify tags are attached to session
aws sts get-caller-identity --output json | jq '.'
# Note: Tags aren't visible in get-caller-identity, but they're there
```

## Quick Test Commands

```bash
# Test 1: Basic assume role
aws sts assume-role \
  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
  --role-session-name quick-test \
  --profile example-admin-profile \
  --query 'Credentials.Expiration' \
  --output text

# Test 2: Assume with tags and test S3
(
  eval $(aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
    --role-session-name test \
    --tags Key=Department,Value=Sales \
    --profile example-admin-profile \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text | \
    awk '{print "export AWS_ACCESS_KEY_ID="$1"; export AWS_SECRET_ACCESS_KEY="$2"; export AWS_SESSION_TOKEN="$3}')
  aws s3 ls
)

# Test 3: Check role permissions
aws iam get-role-policy \
  --role-name ABAC-S3-Test-Role \
  --policy-name YourPolicyName \
  --profile example-admin-profile
```