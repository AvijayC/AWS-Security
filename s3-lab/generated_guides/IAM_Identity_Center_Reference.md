# AWS IAM Identity Center Configuration Reference

## Identity Center Instance
- **Name**: example-identity-center
- **Instance ARN**: arn:aws:sso:::instance/ssoins-exampleinstance
- **Identity Store ID**: d-1234567890
- **Owner Account**: 123456789012 (gen)
- **Status**: ACTIVE
- **Created**: 2025-07-26

## AWS Accounts
- **123456789012** - gen (general account)
- **987654321098** - b (secondary testing account)

## Permission Sets

### 1. ReadOnlyAccess
- **ARN**: arn:aws:sso:::permissionSet/ssoins-exampleinstance/ps-example123456789
- **Session Duration**: 12 hours
- **Attached Policy**: arn:aws:iam::aws:policy/ReadOnlyAccess

### 2. AdministratorAccess
- **ARN**: arn:aws:sso:::permissionSet/ssoins-exampleinstance/ps-example987654321
- **Session Duration**: 12 hours
- **Attached Policy**: arn:aws:iam::aws:policy/AdministratorAccess

## Group Assignments

### General Account (123456789012)
| Group Name | Permission Set | Group ID |
|------------|---------------|----------|
| readonly-123456789012-general | ReadOnlyAccess | 11111111-1111-1111-1111-111111111111 |
| admin-123456789012-general | AdministratorAccess | 22222222-2222-2222-2222-222222222222 |

### B Account (987654321098)
| Group Name | Permission Set | Group ID |
|------------|---------------|----------|
| readonly-987654321098-b | ReadOnlyAccess | 33333333-3333-3333-3333-333333333333 |
| admin-987654321098-b | AdministratorAccess | 44444444-4444-4444-4444-444444444444 |

## Summary
- 2 AWS accounts configured
- 2 permission sets (ReadOnlyAccess and AdministratorAccess)
- 4 groups total (2 per account, one for each permission set)
- Each group is assigned to their respective account with the appropriate permission set