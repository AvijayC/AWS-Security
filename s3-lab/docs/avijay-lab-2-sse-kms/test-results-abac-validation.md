# ABAC Validation Test Results - avijay-lab-2-sse-kms

## Test Date: 2025-08-12

## Test Overview
Validated ABAC (Attribute-Based Access Control) implementation using both S3 object tags and KMS encryption context to enforce user-level isolation.

## Test Executor
- **User**: aalsg-user-1
- **Principal Tag**: `username_owner=aalsg-user-1`
- **Role**: AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b

## Test Scenarios and Results

### Test 1: Upload Without Tags
**Command**:
```bash
aws s3api put-object \
  --bucket avijay-lab-2-sse-kms \
  --key aalsg-user-1-no-tags.txt \
  --body example_object_1.txt \
  --server-side-encryption aws:kms \
  --ssekms-key-id arn:aws:kms:us-east-1:957401190575:key/eeb497f8-c9d1-43eb-b255-6dadd262a22c \
  --ssekms-encryption-context eyJ1c2VybmFtZV9vd25lciI6ImFhbHNnLXVzZXItMSJ9Cg==
```

**Result**: ❌ **FAILED** (Expected)
- **Error**: AccessDenied on s3:PutObject
- **Reason**: Bucket policy denied - no `RequestObjectTag` provided
- **Policy Statement**: `ABACDenyUploadUnlessTaggedAsUser` triggered

### Test 2: Upload With Wrong Tag Value
**Command**:
```bash
aws s3api put-object \
  --bucket avijay-lab-2-sse-kms \
  --key aalsg-user-1-wrong-tag.txt \
  --body example_object_1.txt \
  --server-side-encryption aws:kms \
  --ssekms-key-id arn:aws:kms:us-east-1:957401190575:key/eeb497f8-c9d1-43eb-b255-6dadd262a22c \
  --ssekms-encryption-context eyJ1c2VybmFtZV9vd25lciI6ImFhbHNnLXVzZXItMiJ9Cg== \
  --tagging "username_owner=aalsg-user-2"
```

**Result**: ❌ **FAILED** (Expected)
- **Error**: AccessDenied on kms:GenerateDataKey
- **Reason**: KMS key policy denied - encryption context `username_owner=aalsg-user-2` doesn't match principal tag `aalsg-user-1`
- **Policy Statement**: `Explicit Deny for SSE-KMS with invalid ABAC` triggered

### Test 3: Upload With Correct Tags
**Command**:
```bash
aws s3api put-object \
  --bucket avijay-lab-2-sse-kms \
  --key aalsg-user-1-correct-tag.txt \
  --body example_object_1.txt \
  --server-side-encryption aws:kms \
  --ssekms-key-id arn:aws:kms:us-east-1:957401190575:key/eeb497f8-c9d1-43eb-b255-6dadd262a22c \
  --ssekms-encryption-context eyJ1c2VybmFtZV9vd25lciI6ImFhbHNnLXVzZXItMSJ9Cg== \
  --tagging "username_owner=aalsg-user-1"
```

**Result**: ✅ **SUCCESS**
- **Response**: 
  ```json
  {
    "ETag": "\"667f022910e6af206ad7511b51b7e6b9\"",
    "ServerSideEncryption": "aws:kms",
    "SSEKMSKeyId": "arn:aws:kms:us-east-1:957401190575:key/eeb497f8-c9d1-43eb-b255-6dadd262a22c"
  }
  ```
- **Reason**: Both encryption context and object tag matched principal tag

### Test 4: Download Uploaded Object
**Command**:
```bash
aws s3api get-object \
  --bucket avijay-lab-2-sse-kms \
  --key aalsg-user-1-correct-tag.txt \
  /tmp/downloaded-correct-tag.txt
```

**Result**: ✅ **SUCCESS**
- **File Downloaded**: Successfully retrieved and decrypted
- **Content Verified**: Matches original upload
- **Automatic Handling**: S3 automatically used stored encryption context for KMS decryption

## Key Findings

### Policy Corrections Made
1. **Bucket Policy Fix**: Changed `s3:ExistingObjectTag` to `s3:RequestObjectTag` in the `ABACDenyUploadUnlessTaggedAsUser` statement
   - `ExistingObjectTag` cannot be used with PUT operations (only checks existing objects)
   - `RequestObjectTag` validates tags being applied during upload

### ABAC Enforcement Points
1. **S3 Level**: Object tags control access via bucket policy
2. **KMS Level**: Encryption context enforces user isolation via key policy
3. **Double Protection**: Both mechanisms must pass for successful operations

### Required Parameters for Success
- **Encryption Context**: Must include `"username_owner":"<matching-principal-tag>"`
- **Object Tags**: Must include `username_owner=<matching-principal-tag>`
- **Base64 Encoding**: Encryption context must be base64-encoded for s3api

## Encryption Context Details

### User-Provided Context
```json
{"username_owner":"aalsg-user-1"}
```

### S3-Augmented Context (Stored)
```json
{
  "username_owner":"aalsg-user-1",
  "aws:s3:arn":"arn:aws:s3:::avijay-lab-2-sse-kms/aalsg-user-1-correct-tag.txt"
}
```
*Note: S3 automatically adds the object ARN to the encryption context*

## Conclusion
The ABAC implementation successfully enforces user-level isolation through:
- ✅ S3 bucket policy with object tag validation
- ✅ KMS key policy with encryption context validation
- ✅ Proper denial of unauthorized access attempts
- ✅ Successful access for properly tagged and encrypted objects

The system correctly prevents:
- Uploads without proper tags
- Uploads with mismatched user tags
- KMS operations with incorrect encryption context
- Cross-user object access (to be tested in future scenarios)