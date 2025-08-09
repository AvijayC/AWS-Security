# How to List AWS IAM Identity Center Users - Complete Guide

## Prerequisites

1. **AWS CLI installed and configured** with appropriate credentials
2. **IAM permissions** to access IAM Identity Center (SSO Admin permissions)
3. **AWS profile** configured with necessary access

## Step 1: Find Your Identity Center Instance Details

First, you need to get your Identity Center instance information, which includes the Identity Store ID.

```bash
aws sso-admin list-instances --profile YOUR_PROFILE
```

This returns:
- **InstanceArn**: The ARN of your Identity Center instance
- **IdentityStoreId**: The ID you'll need for user operations (e.g., `d-1234567890`)
- **Name**: Your Identity Center instance name
- **OwnerAccountId**: The AWS account that owns the instance

Example output:
```json
{
    "Instances": [
        {
            "IdentityStoreId": "d-1234567890",
            "InstanceArn": "arn:aws:sso:::instance/ssoins-exampleinstance",
            "Name": "your-identity-center-name"
        }
    ]
}
```

## Step 2: List All Users

Once you have the Identity Store ID, list all users:

```bash
aws identitystore list-users --identity-store-id "YOUR_IDENTITY_STORE_ID" --profile YOUR_PROFILE
```

### Real Example:
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile
```

### Understanding the Output

The command returns a JSON object with user details:
- **UserId**: Unique identifier for the user
- **UserName**: The login username
- **DisplayName**: Full display name
- **Name**: Object containing GivenName and FamilyName
- **Emails**: Array of email addresses (primary work email)

## Step 3: Format Output for Better Readability

### Option A: Get just usernames
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[*].UserName' --output text
```

### Option B: Get usernames and display names in table format
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[*].[UserName, DisplayName]' --output table
```

### Option C: Get specific fields as JSON
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[*].{Username:UserName, Name:DisplayName, Email:Emails[0].Value}'
```

## Step 4: Get Detailed Information About a Specific User

To get more details about a specific user:

```bash
aws identitystore describe-user \
  --identity-store-id "YOUR_IDENTITY_STORE_ID" \
  --user-id "USER_ID" \
  --profile YOUR_PROFILE
```

Example:
```bash
aws identitystore describe-user \
  --identity-store-id "d-1234567890" \
  --user-id "12345678-1234-1234-1234-123456789012" \
  --profile example-admin-profile
```

## Step 5: Find Users by Username

If you know the username but need other details:

```bash
aws identitystore list-users \
  --identity-store-id "d-1234567890" \
  --profile example-admin-profile \
  --filters "AttributePath=UserName,AttributeValue=test-admin"
```

## Step 6: Check User Group Memberships

To see which groups a user belongs to:

```bash
aws identitystore list-group-memberships-for-member \
  --identity-store-id "YOUR_IDENTITY_STORE_ID" \
  --member-id "USER_ID" \
  --profile YOUR_PROFILE
```

## Pagination for Large User Lists

If you have many users, results may be paginated. Use the `--max-results` and `--next-token` parameters:

```bash
# First page (get up to 50 users)
aws identitystore list-users \
  --identity-store-id "d-1234567890" \
  --max-results 50 \
  --profile example-admin-profile

# If NextToken is returned, get next page
aws identitystore list-users \
  --identity-store-id "d-1234567890" \
  --max-results 50 \
  --next-token "YOUR_NEXT_TOKEN" \
  --profile example-admin-profile
```

## Common Use Cases

### 1. Count Total Users
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'length(Users)'
```

### 2. Find Users by Email Domain
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[?contains(Emails[0].Value, `@yourdomain.com`)]'
```

### 3. Export User List to CSV
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[*].[UserName, DisplayName, Emails[0].Value]' \
  --output text | sed 's/\t/,/g' > users.csv
```

### 4. List Users with Their IDs (useful for scripting)
```bash
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile \
  --query 'Users[*].{ID:UserId, Username:UserName}' --output table
```

## Troubleshooting

### Common Errors and Solutions

1. **AccessDeniedException**: Your profile doesn't have sufficient permissions
   - Solution: Ensure your IAM user/role has `identitystore:ListUsers` permission

2. **ResourceNotFoundException**: Invalid Identity Store ID
   - Solution: Verify the Identity Store ID using `aws sso-admin list-instances`

3. **ValidationException**: Incorrect parameter format
   - Solution: Check that Identity Store ID is in correct format (e.g., `d-XXXXXXXXXX`)

## Required IAM Permissions

Your IAM user/role needs these permissions at minimum:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sso-admin:ListInstances",
                "identitystore:ListUsers",
                "identitystore:DescribeUser",
                "identitystore:ListGroupMembershipsForMember"
            ],
            "Resource": "*"
        }
    ]
}
```

## Quick Reference Commands

```bash
# Get Identity Store ID
aws sso-admin list-instances --profile example-admin-profile --query 'Instances[0].IdentityStoreId' --output text

# List all users (simple)
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile

# List usernames only
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile --query 'Users[*].UserName' --output text

# Count users
aws identitystore list-users --identity-store-id "d-1234567890" --profile example-admin-profile --query 'length(Users)' --output text
```

## Notes

- The Identity Store ID remains constant for your Identity Center instance
- User IDs are UUIDs and are unique across the Identity Store
- Results are returned in no specific order
- The `list-users` command returns all attributes by default; use `--query` to filter