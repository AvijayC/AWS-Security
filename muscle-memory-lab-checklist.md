# AWS Security Muscle Memory Lab Checklist
*Practice these until you can do them without thinking*

## 🔥 CRITICAL: Top 25 Labs for Exam Success

### IAM & Access Management (8 labs)
- [ ] **Cross-account role assumption** - Should take <3 mins
- [ ] **IAM permission boundaries** - Delegate without over-permitting
- [ ] **External ID implementation** - Prevent confused deputy
- [ ] **SCP deny-all-except** - Organization-wide restrictions
- [ ] **MFA enforcement via IAM policy** - Condition keys mastery
- [ ] **Session tags with ABAC** - Dynamic access control
- [ ] **PassRole scenarios** - Service role delegation
- [ ] **Temporary credential revocation** - Incident response

### KMS & Encryption (6 labs)
- [ ] **KMS key rotation (manual & automatic)** - Know the differences
- [ ] **Cross-account KMS sharing** - Key policy + IAM policy
- [ ] **Envelope encryption with SDK** - Data key caching
- [ ] **S3 SSE-C, SSE-S3, SSE-KMS** - Know when to use each
- [ ] **EBS volume encryption** - Default encryption & snapshots
- [ ] **Secrets Manager rotation** - RDS & custom secrets

### Network Security (6 labs)
- [ ] **VPC endpoints (Gateway & Interface)** - Private service access
- [ ] **NACLs vs Security Groups** - Stateless vs stateful
- [ ] **Site-to-Site VPN** - IPSec tunnel configuration
- [ ] **WAF rate-limiting** - DDoS protection
- [ ] **CloudFront OAC** - Secure S3 origin
- [ ] **PrivateLink setup** - Service exposure

### Detection & Response (5 labs)
- [ ] **Organization CloudTrail** - Multi-account logging
- [ ] **GuardDuty threat detection** - Enable & respond
- [ ] **VPC Flow Logs analysis** - Detect anomalies
- [ ] **Config auto-remediation** - Lambda + SSM
- [ ] **Security Hub custom insights** - Compliance dashboard

## 📝 Daily 15-Minute Drills

### Monday - IAM CLI Operations
```bash
# 1. Create role and assume it
aws iam create-role --role-name test-role --assume-role-policy-document file://trust.json
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/test-role --role-session-name test

# 2. Attach permission boundary
aws iam put-role-permissions-boundary --role-name dev-role --permissions-boundary arn:aws:iam::ACCOUNT:policy/DevBoundary

# 3. Get policy simulator results
aws iam simulate-principal-policy --policy-source-arn arn:aws:iam::ACCOUNT:user/test --action-names s3:GetObject --resource-arns arn:aws:s3:::bucket/*
```

### Tuesday - KMS Operations
```bash
# 1. Create CMK with rotation
aws kms create-key --description "Test key" --key-policy file://policy.json
aws kms enable-key-rotation --key-id KEY_ID

# 2. Encrypt/decrypt with context
aws kms encrypt --key-id KEY_ID --plaintext "data" --encryption-context Purpose=Test
aws kms decrypt --ciphertext-blob fileb://encrypted.txt --encryption-context Purpose=Test

# 3. Grant operations
aws kms create-grant --key-id KEY_ID --grantee-principal arn:aws:iam::ACCOUNT:role/Lambda --operations Decrypt
```

### Wednesday - S3 Security
```bash
# 1. Block public access
aws s3api put-public-access-block --bucket BUCKET --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 2. Enable versioning with MFA delete
aws s3api put-bucket-versioning --bucket BUCKET --versioning-configuration Status=Enabled,MFADelete=Enabled --mfa "arn:aws:iam::ACCOUNT:mfa/root-account-mfa-device 123456"

# 3. Create presigned URL
aws s3 presign s3://bucket/object --expires-in 3600
```

### Thursday - VPC Security
```bash
# 1. Create VPC endpoint
aws ec2 create-vpc-endpoint --vpc-id vpc-123 --service-name com.amazonaws.region.s3 --route-table-ids rtb-123

# 2. Modify security group
aws ec2 authorize-security-group-ingress --group-id sg-123 --protocol tcp --port 443 --source-group sg-456

# 3. Create flow logs
aws ec2 create-flow-logs --resource-type VPC --resource-ids vpc-123 --traffic-type ALL --log-destination-type s3 --log-destination arn:aws:s3:::bucket/logs/
```

### Friday - Monitoring & Response
```bash
# 1. Query CloudTrail
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin --max-items 10

# 2. Enable GuardDuty
aws guardduty create-detector --enable

# 3. Create Config rule
aws configservice put-config-rule --config-rule file://sg-ssh-restricted.json
```

## 🎯 Timed Challenge Labs

### 10-Minute Challenges
1. **Incident Response Drill**
   - Detect compromised credentials in CloudTrail
   - Revoke all active sessions
   - Apply restrictive SCP
   - Enable MFA enforcement
   - Document actions taken

2. **Data Breach Prevention**
   - Enable S3 Block Public Access org-wide
   - Create Macie job for PII detection
   - Set up EventBridge rule for public bucket
   - Create Lambda for auto-remediation
   - Test with intentional misconfiguration

3. **Zero-Trust Network**
   - Remove all 0.0.0.0/0 security group rules
   - Implement VPC endpoints for S3, DynamoDB, KMS
   - Create private API Gateway
   - Set up PrivateLink for service
   - Verify no internet-facing resources

### 5-Minute Speed Runs
1. **S3 Lockdown** - Make bucket completely private
2. **Emergency SCP** - Block all actions except CloudTrail
3. **KMS Key Disable** - Disable and schedule deletion
4. **Root Login Alert** - CloudWatch alarm + SNS
5. **VPC Isolation** - Remove all IGW/NAT routes

## 🔄 Exam Day Scenarios

### Scenario 1: "Company acquired, integrate security"
**Your muscle memory tasks:**
- [ ] Create cross-account roles
- [ ] Set up organization trail
- [ ] Implement SCPs
- [ ] Configure GuardDuty delegated admin
- [ ] Set up AWS SSO

### Scenario 2: "PCI compliance required"
**Your muscle memory tasks:**
- [ ] Enable all encryption at rest
- [ ] Set up CloudTrail + integrity
- [ ] Configure Config rules for compliance
- [ ] Implement network segmentation
- [ ] Enable detailed monitoring

### Scenario 3: "Suspected breach in progress"
**Your muscle memory tasks:**
- [ ] Analyze CloudTrail last 24h
- [ ] Check GuardDuty findings
- [ ] Isolate suspected resources
- [ ] Rotate all credentials
- [ ] Preserve evidence (snapshots)

## ✅ Pre-Exam Validation

Can you do these WITHOUT looking up syntax?
- [ ] Write an IAM policy with 3 condition keys
- [ ] Explain KMS key policy vs IAM policy precedence
- [ ] List VPC endpoint types and use cases
- [ ] Draw S3 request evaluation flow
- [ ] Name 5 CloudTrail event types to monitor
- [ ] Describe GuardDuty finding types
- [ ] Explain SCP inheritance rules
- [ ] List Config managed rules for security
- [ ] Describe rotation process for Secrets Manager
- [ ] Explain CloudFront OAC vs OAI

## 🚀 Speed Goals

By exam day, you should complete these in:
- IAM role assumption: <2 minutes
- KMS key creation with policy: <3 minutes
- S3 bucket lockdown: <2 minutes
- VPC endpoint setup: <3 minutes
- CloudTrail query for specific event: <1 minute
- Security group modification: <30 seconds
- Generate presigned URL: <30 seconds
- Create CloudWatch alarm: <2 minutes
- Enable service in organization: <2 minutes
- Incident response initial steps: <5 minutes