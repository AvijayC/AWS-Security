# S3 Security Lab Progress Tracker

## Legacy Progress (Before 2025-08-12)

### Timestamp: Legacy

#### Completed Work
- **Multi-account setup**: Configured two AWS accounts (957401190575-gen, 455095160360-b)
- **IAM Identity Center**: Set up 6 users across both accounts with proper tags
  - aalsg-user-1, aalsg-user-2, aalsg-admin (General account)
  - aalsb-user-1, aalsb-user-2, aalsb-admin (B account)
- **S3 bucket creation**: Created 6 test buckets for different encryption scenarios
  - avijay-lab-1-sse-s3 (SSE-S3 with ABAC)
  - avijay-lab-2-sse-kms through avijay-lab-6-sse-kms-vpce-b
- **ABAC implementation for SSE-S3**: Successfully implemented and tested ABAC policies
  - Created bucket policy with Allow/Deny based on object tags
  - Verified tag-based access control working correctly
- **Test infrastructure**: Created test objects and upload scripts
  - Generated test files with proper directory structure
  - Built ABAC testing framework

## Progress for 2025-08-12

### Timestamp: 2025-08-12

#### KMS Deep Dive and ABAC Integration
- **KMS encryption context exploration**: Discovered how S3 automatically adds `aws:s3:arn` to custom encryption context
- **Custom encryption context implementation**: Successfully uploaded objects with `username_owner` in encryption context using s3api
- **KMS key policy creation**: Developed production-ready KMS key policy with:
  - Admin access for root, iamadmin, and SSO AdminAccess role
  - ABAC enforcement using `${aws:PrincipalTag/username_owner}`
  - Explicit deny for mismatched encryption context
- **IAM policy updates**: Added KMS permissions to ReadOnlyAccessWithABACAssumeRole inline policy
- **Successful ABAC test**: Uploaded file as aalsg-user-1 with matching encryption context

#### Policy Evaluation Understanding
- **Clarified IAM vs Resource policy interaction**: Documented that same-account needs OR logic (either policy allows)
- **Identified key issue**: Bucket policy requires object tags, but upload didn't include tags (only encryption context)
- **Discovered permission precedence**: IAM allow is sufficient even without bucket policy allow for same-account

#### Documentation Created
- **S3-KMS lab notes** (`./notes/s3-lab.md`): Comprehensive guide covering:
  - KMS keys vs Data keys explanation
  - Envelope encryption flow
  - CloudTrail log examples
  - Command examples for s3api with encryption context
- **AWS policy evaluation guide** (`./notes/aws-policy-evaluation.md`): Complete reference for:
  - Decision trees for policy evaluation
  - Same-account vs cross-account logic
  - "Most restrictive" condition clarification
  - Real-world troubleshooting examples

#### Key Learnings
- S3 console cannot specify custom encryption context (must use CLI/SDK)
- KMS encryption context != S3 object tags (separate mechanisms)
- Bucket policies are optional for same-account access when IAM allows
- Explicit deny always wins regardless of allows elsewhere

#### Next Steps
- Add object tagging to uploads to satisfy bucket policy conditions
- Test cross-user access scenarios (aalsg-user-2 attempting aalsg-user-1's objects)
- Begin VPC endpoint labs (labs 3-6)