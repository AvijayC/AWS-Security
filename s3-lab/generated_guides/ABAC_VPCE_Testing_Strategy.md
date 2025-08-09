# ABAC + VPC Endpoint Testing Strategy

## The Challenge
Testing ABAC (Attribute-Based Access Control) through VPC endpoints requires combining:
- **User identity attributes** (from IAM Identity Center users)
- **Network isolation** (VPC endpoints)
- **Compute resources** (EC2/Lambda) that can assume user identities

## Solution Approaches

### Option 1: EC2 with AssumeRole + Session Tags (RECOMMENDED)
Most flexible approach for ABAC testing through VPCEs.

#### Setup Architecture
```
IAM Identity Center User → Temporary Credentials → EC2 Instance → AssumeRole with Tags → S3 via VPCE
```

#### Implementation Steps

1. **Create ABAC-enabled IAM Role**
```json
{
  "RoleName": "ABAC-S3-Test-Role",
  "AssumeRolePolicyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com",
          "AWS": "arn:aws:iam::123456789012:root"
        },
        "Action": "sts:AssumeRole"
      },
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::123456789012:saml-provider/IdentityCenter"
        },
        "Action": ["sts:AssumeRoleWithSAML", "sts:TagSession"],
        "Condition": {
          "StringEquals": {
            "SAML:aud": "https://signin.aws.amazon.com/saml"
          }
        }
      }
    ]
  }
}
```

2. **ABAC Policy for S3 Access**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::example-bucket-*/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/Department": "${aws:PrincipalTag/Department}",
          "s3:ExistingObjectTag/Team": "${aws:PrincipalTag/Team}"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::example-bucket-*",
      "Condition": {
        "StringLike": {
          "s3:prefix": "${aws:PrincipalTag/Department}/*"
        }
      }
    }
  ]
}
```

3. **Test Script on EC2 Instance**
```bash
#!/bin/bash

# Get temporary credentials for each user
USERS=(
  "test-user-1:Department=Sales,Team=General"
  "test-user-2:Department=Engineering,Team=General"
  "test-user-3:Department=Sales,Team=B"
  "test-user-4:Department=Engineering,Team=B"
)

for user_config in "${USERS[@]}"; do
  IFS=':' read -r username tags <<< "$user_config"
  
  echo "Testing as $username with tags: $tags"
  
  # Assume role with session tags
  CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \
    --role-session-name "$username-vpce-test" \
    --tags $tags \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)
  
  # Export credentials
  export AWS_ACCESS_KEY_ID=$(echo $CREDS | cut -d' ' -f1)
  export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | cut -d' ' -f2)
  export AWS_SESSION_TOKEN=$(echo $CREDS | cut -d' ' -f3)
  
  # Test S3 access through VPCE
  echo "  Testing bucket access..."
  aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/Sales/
  aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/Engineering/
  
  # Test object access based on tags
  aws s3 cp test-file.txt s3://example-bucket-3-sse-s3-vpce-a/${Department}/test-${username}.txt
  
  unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done
```

### Option 2: Lambda with Identity-Based Invocation
Use Lambda context to pass user attributes.

#### Lambda Function Setup
```python
import boto3
import json
import os

def lambda_handler(event, context):
    # Extract user attributes from event
    user_attributes = event.get('userAttributes', {})
    department = user_attributes.get('Department')
    team = user_attributes.get('Team')
    username = user_attributes.get('Username')
    
    # Create S3 client with session tags
    sts = boto3.client('sts')
    
    assumed_role = sts.assume_role(
        RoleArn='arn:aws:iam::123456789012:role/ABAC-S3-Test-Role',
        RoleSessionName=f'{username}-lambda-test',
        Tags=[
            {'Key': 'Department', 'Value': department},
            {'Key': 'Team', 'Value': team},
            {'Key': 'Username', 'Value': username}
        ]
    )
    
    # Create S3 client with assumed role credentials
    s3 = boto3.client(
        's3',
        aws_access_key_id=assumed_role['Credentials']['AccessKeyId'],
        aws_secret_access_key=assumed_role['Credentials']['SecretAccessKey'],
        aws_session_token=assumed_role['Credentials']['SessionToken']
    )
    
    # Test ABAC access
    test_results = {
        'username': username,
        'department': department,
        'team': team,
        'access_results': {}
    }
    
    # Test department-based folder access
    try:
        response = s3.list_objects_v2(
            Bucket='example-bucket-3-sse-s3-vpce-a',
            Prefix=f'{department}/'
        )
        test_results['access_results'][f'{department}_folder'] = 'ALLOWED'
    except Exception as e:
        test_results['access_results'][f'{department}_folder'] = f'DENIED: {str(e)}'
    
    # Test cross-department access (should fail)
    other_dept = 'Engineering' if department == 'Sales' else 'Sales'
    try:
        response = s3.list_objects_v2(
            Bucket='example-bucket-3-sse-s3-vpce-a',
            Prefix=f'{other_dept}/'
        )
        test_results['access_results'][f'{other_dept}_folder'] = 'ALLOWED (UNEXPECTED)'
    except:
        test_results['access_results'][f'{other_dept}_folder'] = 'DENIED (EXPECTED)'
    
    return {
        'statusCode': 200,
        'body': json.dumps(test_results)
    }
```

#### Invoke Lambda with User Context
```bash
# For each user, invoke Lambda with their attributes
aws lambda invoke \
  --function-name ABAC-VPCE-Test \
  --payload '{
    "userAttributes": {
      "Username": "test-user-1",
      "Department": "Sales",
      "Team": "General"
    }
  }' \
  --profile example-admin-profile \
  output.json
```

### Option 3: SSM Session Manager with RunAs
Use Session Manager to run commands as different users.

#### Setup SSM Document
```json
{
  "schemaVersion": "2.2",
  "description": "Test ABAC S3 access with user context",
  "parameters": {
    "username": {
      "type": "String",
      "description": "Username for testing"
    },
    "department": {
      "type": "String",
      "description": "Department tag"
    },
    "team": {
      "type": "String",
      "description": "Team tag"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "testABACAccess",
      "inputs": {
        "runCommand": [
          "#!/bin/bash",
          "echo 'Testing ABAC access for {{username}}'",
          "",
          "# Assume role with tags",
          "ROLE_CREDS=$(aws sts assume-role \\",
          "  --role-arn arn:aws:iam::123456789012:role/ABAC-S3-Test-Role \\",
          "  --role-session-name {{username}}-ssm-test \\",
          "  --tags Key=Department,Value={{department}} Key=Team,Value={{team}} \\",
          "  --query 'Credentials' --output json)",
          "",
          "# Export credentials",
          "export AWS_ACCESS_KEY_ID=$(echo $ROLE_CREDS | jq -r '.AccessKeyId')",
          "export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_CREDS | jq -r '.SecretAccessKey')",
          "export AWS_SESSION_TOKEN=$(echo $ROLE_CREDS | jq -r '.SessionToken')",
          "",
          "# Test S3 access",
          "echo 'Testing {{department}} folder access:'",
          "aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/{{department}}/",
          "",
          "echo 'Testing cross-department access (should fail):'",
          "OTHER_DEPT=$([[ '{{department}}' == 'Sales' ]] && echo 'Engineering' || echo 'Sales')",
          "aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/$OTHER_DEPT/"
        ]
      }
    }
  ]
}
```

### Option 4: Container-Based Testing (ECS/Fargate)
Run containers with different user contexts in VPC.

#### Task Definition with User Context
```json
{
  "family": "abac-vpce-test",
  "taskRoleArn": "arn:aws:iam::123456789012:role/ABAC-S3-Test-Role",
  "networkMode": "awsvpc",
  "containerDefinitions": [
    {
      "name": "s3-test",
      "image": "amazonlinux:2",
      "environment": [
        {"name": "USER_DEPARTMENT", "value": "Sales"},
        {"name": "USER_TEAM", "value": "General"},
        {"name": "USER_NAME", "value": "test-user-1"}
      ],
      "entryPoint": ["/bin/bash", "-c"],
      "command": [
        "yum install -y aws-cli jq && /test-scripts/abac-test.sh"
      ]
    }
  ]
}
```

## S3 Bucket Configuration for ABAC

### Object Tagging Strategy
```bash
# Tag objects based on department ownership
aws s3api put-object-tagging \
  --bucket example-bucket-3-sse-s3-vpce-a \
  --key Sales/quarterly-report.pdf \
  --tagging 'TagSet=[{Key=Department,Value=Sales},{Key=Team,Value=General}]'

aws s3api put-object-tagging \
  --bucket example-bucket-3-sse-s3-vpce-a \
  --key Engineering/architecture.md \
  --tagging 'TagSet=[{Key=Department,Value=Engineering},{Key=Team,Value=General}]'
```

### Bucket Policy with ABAC + VPCE
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VPCEOnlyAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::example-bucket-3-sse-s3-vpce-a",
        "arn:aws:s3:::example-bucket-3-sse-s3-vpce-a/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:SourceVpce": "vpce-example123"
        }
      }
    },
    {
      "Sid": "ABACBasedAccess",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/ABAC-S3-Test-Role"
      },
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::example-bucket-3-sse-s3-vpce-a/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/Department": "${aws:PrincipalTag/Department}"
        }
      }
    }
  ]
}
```

## Testing Matrix

| User | Department | Team | Test Location | Expected Access |
|------|------------|------|---------------|-----------------|
| test-user-1 | Sales | General | VPC-A via VPCE | Sales/* objects only |
| test-user-2 | Engineering | General | VPC-A via VPCE | Engineering/* objects only |
| test-user-3 | Sales | B | VPC-B via VPCE | Sales/* objects only |
| test-user-4 | Engineering | B | VPC-B via VPCE | Engineering/* objects only |

## Practical Testing Workflow

### Step 1: Prepare Test Environment
```bash
# Create test objects with proper tags
for dept in Sales Engineering; do
  for team in General B; do
    echo "Test data for $dept $team" > /tmp/test-$dept-$team.txt
    aws s3 cp /tmp/test-$dept-$team.txt s3://example-bucket-3-sse-s3-vpce-a/$dept/
    aws s3api put-object-tagging \
      --bucket example-bucket-3-sse-s3-vpce-a \
      --key $dept/test-$dept-$team.txt \
      --tagging "TagSet=[{Key=Department,Value=$dept},{Key=Team,Value=$team}]"
  done
done
```

### Step 2: Deploy EC2 Instance in VPC
```bash
# Launch instance with SSM capability
aws ec2 run-instances \
  --image-id ami-xxxxxxxxx \
  --instance-type t3.micro \
  --subnet-id subnet-vpca-xxxx \
  --iam-instance-profile Name=EC2-ABAC-Test-Profile \
  --user-data '#!/bin/bash
    yum install -y aws-cli jq
    aws s3 cp s3://your-scripts/abac-test.sh /home/ec2-user/
    chmod +x /home/ec2-user/abac-test.sh' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=abac-vpce-test}]' \
  --profile example-admin-profile
```

### Step 3: Execute Tests via Session Manager
```bash
# Connect to instance
aws ssm start-session --target i-instanceid --profile example-admin-profile

# On the instance, run tests for each user
./abac-test.sh test-user-1 Sales General
./abac-test.sh test-user-2 Engineering General
./abac-test.sh test-user-3 Sales B
./abac-test.sh test-user-4 Engineering B
```

## Key Considerations

### 1. Session Tags vs Resource Tags
- **Session Tags**: Attached to the assumed role session (PrincipalTags)
- **Resource Tags**: Attached to S3 objects
- ABAC policies match these tags for access control

### 2. VPCE + ABAC Interaction
- VPC Endpoint restricts network path
- ABAC restricts based on identity attributes
- Both conditions must be satisfied for access

### 3. Identity Propagation Methods
- **AssumeRole with Tags**: Most flexible, works with EC2/Lambda
- **SAML Assertions**: If using federated access
- **JWT Claims**: For modern applications using OIDC

### 4. Testing Automation
```python
# Automated test runner
import boto3
import json

def run_abac_vpce_tests():
    test_cases = [
        {
            'user': 'test-user-1',
            'tags': {'Department': 'Sales', 'Team': 'General'},
            'vpc': 'vpc-a',
            'expected_access': ['Sales/*'],
            'expected_deny': ['Engineering/*']
        },
        # Add more test cases
    ]
    
    results = []
    for test in test_cases:
        # Run test logic
        result = execute_test(test)
        results.append(result)
    
    return results
```

## Troubleshooting ABAC + VPCE

### Common Issues

1. **Tags not propagating**
   ```bash
   # Verify session tags
   aws sts get-caller-identity --query 'Tags' --profile test-session
   ```

2. **VPCE blocking all access**
   ```bash
   # Check from inside VPC
   curl -I https://bucket.s3.region.amazonaws.com
   # Should resolve to VPCE IP
   ```

3. **ABAC policy not matching**
   ```bash
   # Debug with CloudTrail
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=ResourceName,AttributeValue=example-bucket-3-sse-s3-vpce-a \
     --query 'Events[].CloudTrailEvent' \
     --output text | jq '.requestParameters.tagging'
   ```

## Best Practices

1. **Use Least Privilege**
   - Combine VPCE + ABAC for defense in depth
   - Restrict to specific operations needed

2. **Audit Everything**
   - Enable CloudTrail for all S3 operations
   - Log session tag usage

3. **Test Systematically**
   - Test positive cases (should work)
   - Test negative cases (should fail)
   - Test edge cases (boundary conditions)

4. **Document Access Patterns**
   - Create clear matrix of who can access what
   - Document from where (which VPC/VPCE)