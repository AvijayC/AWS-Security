# VPC Endpoint Testing Plan for S3 Buckets

## Overview
Testing VPC endpoints for S3 buckets with 6 users across 2 AWS accounts to verify network isolation and access controls.

## Test Environment

### S3 Buckets Configuration
| Bucket | Encryption | VPC Endpoint |
|--------|------------|--------------|
| example-bucket-1-sse-s3 | SSE-S3 | None |
| example-bucket-2-sse-kms | SSE-KMS | None |
| example-bucket-3-sse-s3-vpce-a | SSE-S3 | VPCE-A |
| example-bucket-4-sse-kms-vpce-a | SSE-KMS | VPCE-A |
| example-bucket-5-sse-s3-vpce-b | SSE-S3 | VPCE-B |
| example-bucket-6-sse-kms-vpce-b | SSE-KMS | VPCE-B |

### Test Users
- General Account (123456789012): test-admin-1, test-user-1, test-user-2
- B Account (987654321098): test-admin-2, test-user-3, test-user-4

## Testing Approach

### Option 1: EC2 Instances with Session Manager (RECOMMENDED)
Best for comprehensive VPC endpoint validation.

#### Setup Steps
1. **Deploy EC2 instances in each VPC**
   ```bash
   # VPC-A instance (for testing VPCE-A buckets)
   aws ec2 run-instances \
     --image-id ami-xxxxxxxxx \
     --instance-type t3.micro \
     --subnet-id subnet-vpca-xxxx \
     --iam-instance-profile Name=SSMInstanceProfile \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=vpce-test-a}]' \
     --profile example-admin-profile

   # VPC-B instance (for testing VPCE-B buckets)
   aws ec2 run-instances \
     --image-id ami-xxxxxxxxx \
     --instance-type t3.micro \
     --subnet-id subnet-vpcb-xxxx \
     --iam-instance-profile Name=SSMInstanceProfile \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=vpce-test-b}]' \
     --profile example-b-admin-profile

   # Public subnet instance (for testing non-VPCE buckets)
   aws ec2 run-instances \
     --image-id ami-xxxxxxxxx \
     --instance-type t3.micro \
     --subnet-id subnet-public-xxxx \
     --iam-instance-profile Name=SSMInstanceProfile \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=vpce-test-public}]' \
     --profile example-admin-profile
   ```

2. **Connect via Session Manager**
   ```bash
   aws ssm start-session --target i-instanceid --profile example-admin-profile
   ```

3. **Run test script on each instance**
   ```bash
   # Copy test script to instance
   aws s3 cp test-s3-access.sh s3://temp-bucket/
   
   # On the instance
   aws s3 cp s3://temp-bucket/test-s3-access.sh .
   chmod +x test-s3-access.sh
   ./test-s3-access.sh
   ```

### Option 2: CLI with VPC Endpoint Configuration
For testing from local machine with endpoint routing.

#### Setup
1. **Configure AWS CLI profiles with endpoint URLs**
   ```bash
   # For VPCE-A testing
   export AWS_ENDPOINT_URL_S3=https://vpce-xxxx-xxxx.s3.region.vpce.amazonaws.com
   
   # For VPCE-B testing  
   export AWS_ENDPOINT_URL_S3=https://vpce-yyyy-yyyy.s3.region.vpce.amazonaws.com
   ```

2. **Run tests with endpoint-specific configuration**
   ```bash
   # Test VPCE-A restricted buckets
   aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/ \
     --endpoint-url https://vpce-xxxx.s3.region.vpce.amazonaws.com \
     --profile test-admin-1
   ```

### Option 3: Lambda Functions in VPCs
For automated, repeatable testing.

#### Implementation
```python
import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    test_results = {}
    
    buckets = [
        'example-bucket-3-sse-s3-vpce-a',
        'example-bucket-4-sse-kms-vpce-a'
    ]
    
    for bucket in buckets:
        try:
            s3.list_objects_v2(Bucket=bucket, MaxKeys=1)
            test_results[bucket] = 'ACCESSIBLE'
        except Exception as e:
            test_results[bucket] = f'DENIED: {str(e)}'
    
    return {
        'statusCode': 200,
        'body': json.dumps(test_results)
    }
```

Deploy Lambda in each VPC subnet to test endpoint access.

## Test Scenarios

### 1. VPC Endpoint Isolation Tests
Verify buckets with VPCE restrictions are only accessible from correct VPCs.

| Test Case | Expected Result |
|-----------|----------------|
| Access VPCE-A bucket from VPC-A | ✓ Success |
| Access VPCE-A bucket from VPC-B | ✗ Denied |
| Access VPCE-A bucket from Internet | ✗ Denied |
| Access VPCE-B bucket from VPC-B | ✓ Success |
| Access VPCE-B bucket from VPC-A | ✗ Denied |
| Access non-VPCE bucket from any location | ✓ Success (if IAM allows) |

### 2. Cross-Account Access Tests
Test access patterns across accounts with VPC endpoints.

```bash
# From VPC-A (General Account)
aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/ --profile test-admin-1  # Should work
aws s3 ls s3://example-bucket-5-sse-s3-vpce-b/ --profile test-admin-1  # Should fail

# From VPC-B (B Account)  
aws s3 ls s3://example-bucket-5-sse-s3-vpce-b/ --profile test-admin-2  # Should work
aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/ --profile test-admin-2  # Should fail
```

### 3. Encryption Key Access Tests
Verify KMS key access through VPC endpoints.

```bash
# Test KMS-encrypted bucket through VPCE
aws s3 cp s3://example-bucket-4-sse-kms-vpce-a/test-object.txt . \
  --profile test-admin-1 \
  --endpoint-url https://vpce-xxxx.s3.region.vpce.amazonaws.com
```

## Validation Commands

### Check VPC Endpoint Status
```bash
# List VPC endpoints
aws ec2 describe-vpc-endpoints \
  --filters "Name=service-name,Values=com.amazonaws.region.s3" \
  --profile example-admin-profile

# Get endpoint policy
aws ec2 describe-vpc-endpoints \
  --vpc-endpoint-ids vpce-xxxxx \
  --query 'VpcEndpoints[0].PolicyDocument' \
  --output text | python -m json.tool
```

### Verify Bucket Policies
```bash
# Check bucket policy for VPCE restrictions
aws s3api get-bucket-policy \
  --bucket example-bucket-3-sse-s3-vpce-a \
  --profile example-admin-profile | python -m json.tool
```

### Network Path Analysis
```bash
# From EC2 instance, trace network path
aws ec2 describe-vpc-endpoint-connections \
  --filters "Name=vpc-endpoint-id,Values=vpce-xxxxx" \
  --profile example-admin-profile
```

## Test Execution Plan

### Phase 1: Environment Setup (30 min)
1. Deploy EC2 instances in each VPC
2. Configure Session Manager access
3. Install AWS CLI on instances
4. Copy test scripts to instances

### Phase 2: Baseline Testing (15 min)
1. Test all buckets from public internet (should fail for VPCE buckets)
2. Document baseline access patterns
3. Verify IAM permissions are working

### Phase 3: VPC Endpoint Testing (45 min)
1. Test from VPC-A instance:
   - All 6 buckets with each user profile
   - Document which succeed/fail
2. Test from VPC-B instance:
   - All 6 buckets with each user profile
   - Document which succeed/fail
3. Test from public subnet instance:
   - Non-VPCE buckets (should work)
   - VPCE buckets (should fail)

### Phase 4: Cross-Account Testing (30 min)
1. Test B account users accessing General account buckets
2. Test General account users accessing B account resources
3. Verify VPC endpoint boundaries are enforced

### Phase 5: Results Analysis (15 min)
1. Create access matrix showing all test results
2. Identify any unexpected access patterns
3. Document recommendations for production use

## Expected Results Matrix

| User | Bucket | From VPC-A | From VPC-B | From Internet |
|------|--------|------------|------------|---------------|
| test-admin-1 | example-bucket-1-sse-s3 | ✓ | ✓ | ✓ |
| test-admin-1 | example-bucket-2-sse-kms | ✓ | ✓ | ✓ |
| test-admin-1 | example-bucket-3-sse-s3-vpce-a | ✓ | ✗ | ✗ |
| test-admin-1 | example-bucket-4-sse-kms-vpce-a | ✓ | ✗ | ✗ |
| test-admin-1 | example-bucket-5-sse-s3-vpce-b | ✗ | ✓ | ✗ |
| test-admin-1 | example-bucket-6-sse-kms-vpce-b | ✗ | ✓ | ✗ |

(Similar patterns for other users based on IAM permissions)

## Troubleshooting

### Common Issues
1. **Timeout accessing VPCE buckets**
   - Check VPC endpoint is in correct VPC
   - Verify security groups allow HTTPS (443)
   - Check route tables include endpoint

2. **Access denied with correct VPC**
   - Verify bucket policy includes VPCE ID
   - Check IAM permissions for user
   - Ensure KMS key policy allows access (for KMS buckets)

3. **Session Manager connection fails**
   - Verify SSM agent is running
   - Check instance IAM role has SSM permissions
   - Ensure VPC endpoints for SSM are configured

### Debug Commands
```bash
# Check network connectivity
curl -I https://s3.amazonaws.com

# Test DNS resolution
nslookup example-bucket-3-sse-s3-vpce-a.s3.amazonaws.com

# Check AWS credentials
aws sts get-caller-identity --profile test-admin-1

# Verbose S3 operation
aws s3 ls s3://example-bucket-3-sse-s3-vpce-a/ \
  --debug \
  --profile test-admin-1 2>&1 | grep -i endpoint
```

## Security Considerations

1. **Principle of Least Privilege**
   - VPC endpoints should restrict to minimum required access
   - Use condition keys in bucket policies

2. **Network Isolation**
   - Ensure VPCE buckets are not accessible from internet
   - Validate no data exfiltration paths exist

3. **Audit and Monitoring**
   - Enable S3 access logging
   - Use CloudTrail for API monitoring
   - Set up CloudWatch alarms for unauthorized access attempts

## Cleanup
```bash
# Terminate EC2 instances
aws ec2 terminate-instances --instance-ids i-xxxx i-yyyy --profile example-admin-profile

# Remove test objects from buckets
for bucket in example-bucket-{1..6}-*; do
  aws s3 rm s3://$bucket/test-write-* --recursive --profile example-admin-profile
done
```