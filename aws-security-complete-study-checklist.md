# AWS Security Certification - Complete Study Checklist

## Course Fundamentals & Account Setup
- [x] AWS Accounts - The Basics
- [x] Creating GENERAL AWS Account
- [x] Multi-factor Authentication (MFA)
- [x] Securing AWS Account with MFA
- [x] Creating a Budget
- [x] Creating the Production Account
- [x] Identity and Access Management (IAM) Basics
- [x] Adding IAMADMIN to GENERAL Account
- [x] Adding IAMADMIN to PRODUCTION Account
- [x] IAM Access Keys
- [x] Creating Access keys and setting up AWS CLI v2 tools

## Domain 6: Management and Security Governance
- [x] AWS Organizations
- [x] AWS Organizations (Demo)
- [x] Service Control Policies (SCP)
- [x] Using Service Control Policies (Demo)
- [x] AWS Control Tower
- [x] AWS Config
- [x] AWS Service Catalog
- [x] AWS Resource Access Manager (RAM)
- [x] Trusted Advisor

### CloudFormation Deep Dive
- [x] CloudFormation Physical & Logical Resources
- [x] CloudFormation Template and Pseudo Parameters
- [x] CloudFormation Intrinsic Functions
- [x] CloudFormation Mappings
- [x] CloudFormation Outputs
- [x] CloudFormation Conditions
- [x] CloudFormation DependsOn
- [x] CloudFormation Wait Conditions & cfn-signal
- [x] CloudFormation Nested Stacks
- [x] CloudFormation Cross-Stack References
- [x] CloudFormation Deletion Policy
- [x] CloudFormation Stack Roles
- [x] CloudFormation ChangeSets
- [x] CloudFormation Custom Resources

## Domain 4: Identity and Access Management

### IAM Core Concepts
- [x] IAM Identity Policies
- [x] IAM Users and ARNs
- [x] IAM Groups
- [x] IAM Roles - The Tech
- [x] When to use IAM Roles
- [x] Service-linked Roles and PassRole
- [x] Security Token Service (STS)
- [x] EC2 Instance Roles & Profile
- [x] IAM Policy Variables

### Policy Deep Dives
- [x] Policy Interpretation Deep Dive - Example 1
- [x] Policy Interpretation Deep Dive - Example 2
- [x] Policy Interpretation Deep Dive - Example 3
- [x] AWS Permissions Evaluation
- [x] IAM Permissions Boundaries and Delegation
- [x] External ID & Confused Deputy

### Directory Services & Federation
- [x] Directory Service Deep Dive (Microsoft AD)
- [x] Directory Service Deep Dive (AD Connector)
- [x] What is ID Federation?
- [x] Amazon Cognito - User and Identity Pools
- [x] Web Identity Federation (WEBIDF) - Complete Implementation
- [x] SAML Federation
- [ ] IAM Identity Center (formerly AWS SSO)
- [ ] Adding Single Sign-on to Organizations

### S3 Security & Access Management
- [x] S3 PreSigned URLs
- [x] Creating and using PresignedURLs (Demo)
- [x] S3 Security (Resource Policies & ACLs)
- [ ] S3 Object Lock
- [ ] S3 Versioning & MFA
- [x] Cross Account Access to S3 - ACL Method
- [ ] Cross Account Access to S3 - Bucket Policy Method
- [ ] Cross Account Access to S3 - Role Method
- [ ] EC2 Instance Metadata

## Domain 1: Threat Detection and Incident Response
- [x] AWS Abuse Notice, UAP & Penetration Testing
- [ ] AWS GuardDuty 101
- [ ] AWS Security Hub
- [ ] Amazon Detective
- [ ] Revoking IAM Role Temporary Security Credentials
- [x] Revoking Temporary Credentials (Demo Part 1)
- [x] Revoking Temporary Credentials (Demo Part 2)

## Domain 3: Infrastructure Security

### VPC Fundamentals
- [ ] Public and Private AWS Services
- [x] Custom VPCs - Theory
- [x] Custom VPCs - Demo
- [x] VPC Subnets
- [x] Implement multi-tier VPC subnets
- [ ] DHCP in a VPC
- [ ] VPC Router Deep Dive

### Network Security Controls
- [x] Stateful vs Stateless firewalls
- [x] Network Access Control Lists (NACL)
- [x] Security Groups (SG)
- [ ] Internet Gateway (IGW) IPv4 and IPv6
- [ ] Egress Only Internet Gateway
- [ ] Bastion Hosts & Authentication
- [ ] Configuring public subnets and Jumpbox
- [ ] Port Forwarding

### NAT & Private Access
- [x] NAT Instance
- [x] NAT Gateway
- [x] Implementing private internet access using NAT Gateways

### VPN Connectivity
- [ ] IPSec VPN Fundamentals
- [ ] Virtual Private Gateway Deep Dive (VGW)
- [ ] AWS Site-to-Site VPN
- [ ] Simple Site2Site VPN - Complete Implementation
- [ ] Client VPN

### VPC Endpoints
- [ ] Gateway VPC Endpoints
- [ ] Interface VPC Endpoints
- [ ] VPC Endpoints - Interface (Demo)
- [ ] VPC Endpoints - Gateway (Demo)
- [ ] Egress-Only Internet Gateway (Demo)
- [ ] Endpoint Policies
- [ ] Private S3 Buckets Setup
- [ ] Private S3 Buckets Implementation

### Advanced VPC Features
- [ ] Advanced VPC DNS & DNS Endpoints
- [ ] VPC Peering
- [ ] VPC Peering (Demo)

### Storage Security
- [ ] EBS Encryption Architecture
- [ ] EBS Volumes - Part 1 (Demo)
- [ ] EBS Volumes - Part 2 (Demo)
- [ ] EBS Volumes - Part 3 (Demo)
- [ ] EBS Volume Secure Wipes
- [ ] S3 Access Points

### CloudFront & CDN Security
- [ ] CloudFront - Architecture
- [ ] AWS Certificate Manager (ACM)
- [ ] CloudFront - SSL/TLS & SNI
- [ ] CloudFront - Security - OAI/OAC & Custom Origins
- [ ] CloudFront - Georestrictions
- [ ] CloudFront - Private Behaviours, Signed URL & Cookies
- [ ] CloudFront - Field Level Encryption
- [ ] Lambda@edge

### DDoS & Network Protection
- [ ] DDoS 101
- [ ] AWS Shield
- [ ] AWS Network Firewall - 101
- [ ] Implementing DNSSEC using Route53

## Domain 2: Security Logging and Monitoring

### CloudWatch
- [ ] CloudWatch 101 - Part 1
- [ ] CloudWatch 101 - Part 2
- [ ] CloudWatch Logs Architecture
- [ ] CloudWatch Events and EventBridge
- [ ] Logging and Metrics with CloudWatch Agent - Part 1
- [ ] Logging and Metrics with CloudWatch Agent - Part 2

### Event Processing
- [ ] S3 Events
- [ ] S3 Events + Lambda (Pixelator) - Part 1
- [ ] S3 Events + Lambda (Pixelator) - Part 2
- [ ] SNS Architecture

### Security Monitoring Services
- [ ] Amazon Inspector
- [ ] AWS Trusted Advisor (Review)
- [ ] VPC Flow Logs
- [ ] Application Layer (7) Firewalls
- [ ] Web Application Firewall (WAF), WEBACLs, Rule Groups and Rules

### CloudTrail & Analysis
- [ ] CloudTrail Architecture
- [ ] Implementing an Organizational Trail
- [ ] CloudTrail log file integrity validation
- [ ] AWS Athena 101
- [ ] Athena Demo - Part 1
- [ ] Athena Demo - Part 2
- [ ] Amazon Macie 101
- [ ] Amazon Macie (Demo)
- [ ] AWS Glue 101
- [ ] AWS Artifact

## Domain 5: Data Protection

### Hardware Security & KMS
- [ ] What is a Hardware Security Module (HSM)
- [ ] AWS Key Management Service (KMS) 101
- [ ] CloudHSM
- [ ] CloudHSM vs KMS

### S3 Encryption
- [x] S3 Object Encryption CSE/SSE
- [x] Object Encryption and Role Separation (Demo)
- [ ] Envelope Encryption
- [ ] Bucket Keys

### KMS Deep Dive
- [ ] AWS Managed Keys vs Customer Managed Keys
- [ ] KMS - Encrypting with KMS (Demo)
- [ ] Importing Key Material vs Generated Key Material
- [ ] Asymmetric keys in KMS
- [ ] Digital Signing using KMS
- [ ] Encryption SDK - Data Key Caching
- [ ] KMS Security Model & Key Policies
- [ ] KMS Grants
- [ ] KMS Multi-region Keys
- [ ] KMS Custom Key Stores
- [ ] KMS Encryption Context

### Other Data Protection Services
- [ ] AWS Secrets Manager 101
- [ ] RDS Encryption & IAM Authentication
- [ ] DynamoDB Encryption

## Load Balancer Security
- [ ] Elastic Load Balancer Architecture - Part 1
- [ ] Elastic Load Balancer Architecture (ELB) - Part 2
- [ ] Application Load Balancing (ALB) vs Network Load Balancing (NLB)
- [ ] ELB: SSL Offload and Session Stickiness
- [ ] Seeing Session Stickiness in Action (Demo)
- [ ] Load Balancer Security Policies

## Exam Preparation
- [ ] General AWS Exam Technique - 3 Phase Approach
- [ ] General AWS Question Technique - Part 1
- [ ] General AWS Question Technique - Part 2
- [ ] Exam Question Walkthrough #1
- [ ] Exam Question Walkthrough #2
- [ ] Practice Exam #1 - Part 1 (Questions 1-20)
- [ ] Practice Exam #1 - Part 2 (Questions 21-40)
- [ ] Practice Exam #1 - Part 3 (Questions 41-60)

---

## Progress Tracking

### By Domain:
- **Domain 1**: Threat Detection and Incident Response - [ ] Complete
- **Domain 2**: Security Logging and Monitoring - [ ] Complete
- **Domain 3**: Infrastructure Security - [ ] Complete
- **Domain 4**: Identity and Access Management - [ ] Complete
- **Domain 5**: Data Protection - [ ] Complete
- **Domain 6**: Management and Security Governance - [ ] Complete

### Study Statistics:
- Total Topics: ~200
- Total Video Time: ~2073 minutes (34.5 hours)
- Topics Completed: ___/200
- Estimated Completion Date: ___________

### Notes Section:
_Use this space to note challenging topics that need review_

---

**Last Updated**: [Date]
**Target Exam Date**: [Your target date]