# AWS Security Specialty 3-Week Intensive Study Plan
**Start Date: August 18, 2025 | End Date: September 7, 2025**

## Your Current Progress
✅ **Completed:**
- S3 SSE-S3 encryption lab
- S3 SSE-KMS encryption lab (in progress)
- ABAC policies with S3 bucket policies
- IAM Identity Center user setup
- Multi-account environment (957401190575-gen, 455095160360-b)

## Week 1: Core Security Foundations & IAM Deep Dive
**August 18-24, 2025**
**Goal:** Master IAM, Organizations, and foundational security services

### Days 1-2: IAM & Organizations (Aug 18-19)
**Must-Do Labs:**
- [x] **Cross-account role assumption** - Should take <3 mins
- [ ] **IAM permission boundaries** - Delegate without over-permitting
- [ ] **External ID implementation** - Prevent confused deputy
- [ ] **SCP deny-all-except** - Organization-wide restrictions
- [ ] **MFA enforcement via IAM policy** - Condition keys mastery
- [x] **Session tags with ABAC** - Dynamic access control
- [ ] **PassRole scenarios** - Service role delegation

### Days 3-4: KMS & Encryption (Aug 20-21)
**Must-Do Labs:**
- [x] Complete SSE-KMS bucket lab
- [ ] **S3 SSE-C, SSE-S3, SSE-KMS** - Know when to use each
- [ ] **KMS key rotation (manual & automatic)** - Know the differences
- [ ] **Cross-account KMS sharing** - Key policy + IAM policy
- [ ] **Envelope encryption with SDK** - Data key caching
- [ ] **EBS volume encryption** - Default encryption & snapshots
- [ ] **Secrets Manager rotation** - RDS & custom secrets

### Days 5-6: VPC Security (Aug 22-23)
**Must-Do Labs:**
- [ ] **VPC endpoints (Gateway & Interface)** - Private service access
- [ ] **NACLs vs Security Groups** - Stateless vs stateful
- [ ] **Site-to-Site VPN** - IPSec tunnel configuration
- [ ] **PrivateLink setup** - Service exposure
- [ ] **Network segmentation** - Multi-tier VPC architecture
- [ ] **VPC Flow Logs analysis** - Detect anomalies

### Day 7: Review & Practice Exam #1 (Aug 24)

## Week 2: Detection, Response & Advanced Services
**August 25-31, 2025**
**Goal:** Master monitoring, incident response, and advanced security services

### Days 8-9: CloudTrail & Detection (Aug 25-26)
**Must-Do Labs:**
- [ ] **Organization CloudTrail** - Multi-account logging
- [ ] **GuardDuty threat detection** - Enable & respond
- [ ] **Security Hub custom insights** - Compliance dashboard
- [ ] **CloudWatch Events integration** - Real-time API monitoring
- [ ] **Custom threat lists** - GuardDuty configuration

### Days 10-11: Incident Response (Aug 27-28)
**Must-Do Labs:**
- [ ] **Temporary credential revocation** - Incident response
- [ ] **Credential compromise response** - Full forensics workflow
- [ ] **EC2 instance compromise** - Isolation and analysis
- [ ] **Data exfiltration response** - Emergency procedures
- [ ] **Root Login Alert** - CloudWatch alarm + SNS
- [ ] **Emergency SCP** - Block all actions except CloudTrail

### Days 12-13: Advanced Security Services (Aug 29-30)
**Must-Do Labs:**
- [ ] **WAF rate-limiting** - DDoS protection
- [ ] **CloudFront OAC** - Secure S3 origin (replaces OAI)
- [ ] **Secrets Manager rotation** - Automated rotation
- [ ] **Config auto-remediation** - Lambda + SSM
- [ ] **Macie job for PII detection** - Data classification
- [ ] **Field-level encryption** - CloudFront implementation

### Day 14: Practice Exam #2 & #3 (Aug 31)

## Week 3: Integration & Exam Preparation
**September 1-7, 2025**
**Goal:** Complex scenarios, integration, and exam readiness

### Days 15-16: Complex Integration Labs (Sep 1-2)
**Must-Do Labs:**
- [ ] **Complete Web Identity Federation project** - All 5 parts
- [ ] **Private S3 hosting scenario** - Full security stack
- [ ] **Automated remediation pipeline** - Config to Lambda
- [ ] **Zero-Trust Network implementation** - Complete isolation
- [ ] **Data pipeline security** - End-to-end encryption

### Days 17-18: Multi-Service Scenarios (Sep 3-4)
**Must-Do Labs:**
- [ ] **Hybrid architecture security** - Direct Connect + VPN
- [ ] **Private API Gateway** - Internal services only
- [ ] **Certificate Manager for internal PKI** - TLS everywhere
- [ ] **Route 53 private hosted zones** - DNS security
- [ ] **S3 Lockdown** - Complete privatization

### Days 19-20: Final Review & Speed Drills (Sep 5-6)
- [ ] Practice Exam #4 & #5
- [ ] Review weak areas from practice exams
- [ ] Quick repetition of critical labs
- [ ] **10-Minute Challenge:** Incident Response Drill
- [ ] **10-Minute Challenge:** Data Breach Prevention
- [ ] **5-Minute Speed Runs** - All scenarios

### Day 21: Practice Exam #6 & Final Review (Sep 7)

## Daily Muscle Memory Drills (15 mins each morning)

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

## Critical Exam Topics to Lab

### High-Weight Topics (30% of exam):
1. **IAM policy evaluation logic** - Create conflicting policies and test
2. **KMS key policies vs IAM policies** - Test interaction scenarios
3. **S3 bucket policies vs ACLs vs IAM** - Create permission conflicts
4. **VPC endpoint policies** - Test restriction scenarios

### Common Exam Scenarios to Practice:
1. **"Least privilege for Lambda"** - Create execution roles
2. **"Encrypt data in transit"** - TLS/SSL everywhere
3. **"Prevent data exfiltration"** - VPC endpoints + SCPs
4. **"Compliance requirements"** - CloudTrail + Config + AWS Artifact

## Lab Environment Commands

```bash
# Quick environment setup each day
export AWS_PROFILE=awssec-gen-admin
aws sts get-caller-identity

# Switch between accounts quickly
alias gen='export AWS_PROFILE=awssec-gen-admin'
alias prod='export AWS_PROFILE=awssec-b-admin'

# Assume ABAC role
aws sts assume-role \
  --role-arn arn:aws:iam::957401190575:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b \
  --role-session-name abac-test
```

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

## Success Metrics
- [ ] Complete 50+ hands-on labs
- [ ] Score 80%+ on practice exams 4-6
- [ ] Under 2 minutes for common CLI operations
- [ ] Can draw architecture diagrams for all major scenarios
- [ ] Explain permission evaluation logic without hesitation

## Emergency Topics (If behind schedule)
**Absolute must-knows:**
1. IAM policy evaluation (explicit deny > allow)
2. KMS key policies and grants
3. CloudTrail for all regions
4. VPC endpoints for private access
5. GuardDuty + Security Hub basics
6. Incident response procedures
7. S3 request evaluation flow
8. SCP inheritance and evaluation
9. Cross-account access patterns
10. Encryption at rest vs in transit