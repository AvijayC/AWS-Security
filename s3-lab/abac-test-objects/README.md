# ABAC Test Object Collection

## Overview
This collection contains test objects for validating Attribute-Based Access Control (ABAC) in S3 buckets with VPC endpoint restrictions.

## Structure

```
abac-test-objects/
├── manifest.json           # Master manifest with all object metadata and tags
├── generate-test-files.sh  # Script to generate test files
├── upload-to-s3.sh        # Script to upload files with tags to S3
├── test-abac-access.sh    # Script to test ABAC access patterns
└── home/
    ├── 957401190575/      # General account
    │   ├── aalsg-user-1/  # 4 test files (001-004)
    │   └── aalsg-user-2/  # 4 test files (005-008)
    └── 455095160360/      # B account
        ├── aalsb-user-1/  # 4 test files (009-012)
        └── aalsb-user-2/  # 4 test files (013-016)
```

## Tag Permutations

Each file has a unique combination of tags:
- `sample_access_flag_A`: true/false
- `vpce_access_flag`: true/false  
- `username_owner`: aalsg-user-1, aalsg-user-2, aalsb-user-1, or aalsb-user-2

Total: 16 files (4 users × 4 tag combinations each)

## File Naming Convention

Files are numbered sequentially:
- aalsg-user-1: test-file-001.txt to test-file-004.txt
- aalsg-user-2: test-file-005.txt to test-file-008.txt
- aalsb-user-1: test-file-009.txt to test-file-012.txt
- aalsb-user-2: test-file-013.txt to test-file-016.txt

## Tag Combinations per User

Each user has 4 files with these tag patterns:
1. File 1: sample_access_flag_A=true, vpce_access_flag=true
2. File 2: sample_access_flag_A=true, vpce_access_flag=false
3. File 3: sample_access_flag_A=false, vpce_access_flag=true
4. File 4: sample_access_flag_A=false, vpce_access_flag=false

## Usage

### 1. Generate Test Files
```bash
chmod +x generate-test-files.sh
./generate-test-files.sh
```

### 2. Upload to S3 with Tags
```bash
chmod +x upload-to-s3.sh

# Upload to specific bucket
./upload-to-s3.sh avijay-lab-1-sse-s3 awssec-gen-admin

# Upload to buckets with VPC endpoints
./upload-to-s3.sh avijay-lab-3-sse-s3-vpce-a awssec-gen-admin
./upload-to-s3.sh avijay-lab-5-sse-s3-vpce-b awssec-b-admin
```

### 3. Test ABAC Access
```bash
chmod +x test-abac-access.sh
./test-abac-access.sh avijay-lab-1-sse-s3
```

### 4. Verify Tags on Uploaded Objects
```bash
# Check tags on a specific object
aws s3api get-object-tagging \
  --bucket avijay-lab-1-sse-s3 \
  --key home/957401190575/aalsg-user-1/test-file-001.txt \
  --profile awssec-gen-admin

# List all objects with specific tag
aws s3api list-objects-v2 \
  --bucket avijay-lab-1-sse-s3 \
  --prefix home/ \
  --profile awssec-gen-admin
```

## ABAC Policy Examples

### Allow access based on username_owner tag
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::bucket-name/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/username_owner": "${aws:PrincipalTag/username_owner}"
        }
      }
    }
  ]
}
```

### Allow access only through VPC endpoint
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject"],
      "Resource": "arn:aws:s3:::bucket-name/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/vpce_access_flag": "true",
          "aws:SourceVpce": "vpce-xxxxxx"
        }
      }
    }
  ]
}
```

### Complex ABAC with multiple conditions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::bucket-name/*",
      "Condition": {
        "StringEquals": {
          "s3:ExistingObjectTag/username_owner": "${aws:PrincipalTag/username_owner}",
          "s3:ExistingObjectTag/sample_access_flag_A": "true"
        }
      }
    }
  ]
}
```

## Testing Scenarios

### Scenario 1: User can only access their own files
- User aalsg-user-1 should access files 001-004 ✓
- User aalsg-user-1 should NOT access files 005-016 ✗

### Scenario 2: VPCE-restricted access
- Files with vpce_access_flag=true only accessible from VPC endpoint
- Files with vpce_access_flag=false accessible from anywhere (if IAM allows)

### Scenario 3: Flag-based access control
- Files with sample_access_flag_A=true accessible to users with matching attribute
- Files with sample_access_flag_A=false require different permission set

## Manifest Structure

The `manifest.json` contains:
```json
{
  "objects": [
    {
      "local_path": "relative path to local file",
      "s3_key": "S3 object key",
      "tags": {
        "sample_access_flag_A": "true|false",
        "vpce_access_flag": "true|false",
        "username_owner": "username"
      }
    }
  ]
}
```

## Cleanup

To remove all test objects from S3:
```bash
# Remove from each bucket
for bucket in avijay-lab-{1..6}*; do
  aws s3 rm "s3://$bucket/home/" --recursive --profile awssec-gen-admin
done
```