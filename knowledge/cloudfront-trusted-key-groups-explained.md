# CloudFront Trusted Key Groups for Signed URLs and Signed Cookies

## Overview

**Trusted Key Groups** are the AWS-recommended method for implementing signed URLs and signed cookies in CloudFront distributions. They provide a secure way to control access to private content without requiring AWS root account access.

## What are Trusted Key Groups?

A **trusted key group** is a collection of public keys managed in CloudFront that can verify signatures on signed URLs or signed cookies. Each key group can contain up to 5 public keys, and you can associate up to 4 key groups with a single distribution.

**Source:** [AWS CloudFront Documentation - Specify signers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html)

## Why Use Trusted Key Groups?

### Key Benefits (vs. AWS Account-based signers)

1. **No Root Account Required**
   - Follows AWS best practices by avoiding root account usage
   - IAM users can manage keys based on permissions you grant

2. **API Automation**
   - Full CloudFront API support for key management
   - Automate key creation and rotation programmatically

3. **IAM Integration**
   - Granular permissions control
   - Example: Allow users to upload but not delete keys
   - Conditional access (MFA, IP restrictions, time-based)

4. **More Keys Available**
   - Up to 4 key groups × 5 keys = 20 total public keys per distribution
   - Root account method limited to 2 active key pairs

**Source:** [AWS CloudFront Announcement - IAM Support](https://aws.amazon.com/about-aws/whats-new/2020/10/cloudfront-iam-signed-url/)

## Supported Key Types

CloudFront supports two types of cryptographic keys:

### RSA Keys
- **Size:** 2048 bits (also supports 1024, 4096)
- **Format:** SSH-2 RSA in base64-encoded PEM
- **Security:** Standard, widely supported
- **Performance:** Slower than ECDSA

### ECDSA Keys
- **Size:** 256 bits (prime256v1 curve)
- **Format:** Base64-encoded PEM
- **Security:** 128-bit security strength (equivalent to RSA 3072)
- **Performance:** Faster signature generation and verification
- **Benefit:** Better security-to-performance ratio

**Source:** [AWS CloudFront Documentation - Private Content](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html)

## How Trusted Key Groups Work

### Architecture Flow

```
1. Setup Phase:
   Developer → Creates Key Pair → Uploads Public Key to CloudFront
                                → Adds to Key Group
                                → Associates with Distribution

2. Request Phase:
   User → Requests Protected Content
   App Server → Verifies User Authorization
              → Signs URL/Cookie with Private Key
              → Returns Signed URL/Cookie to User

3. Access Phase:
   User → Sends Request with Signed URL/Cookie → CloudFront
   CloudFront → Validates Signature with Public Key from Key Group
              → Checks Policy (expiration, IP, etc.)
              → Serves Content or Returns 403
```

## Signed URLs vs Signed Cookies

### When to Use Signed URLs

Use signed URLs when:
- Restricting access to **individual files** (e.g., software download)
- Clients don't support cookies
- Need on-the-fly access for specific purposes (movie rental, music download)
- Want to track individual file access

**Important:** Signed URLs take precedence over signed cookies if both are present.

### When to Use Signed Cookies

Use signed cookies when:
- Providing access to **multiple files** (e.g., all HLS video segments)
- Don't want to change existing URLs
- Users access multiple restricted files in a session
- Want seamless user experience across multiple requests

**Source:** [AWS CloudFront Documentation - Choosing Signed URLs or Cookies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-choosing-signed-urls-cookies.html)

## Implementation Steps

### 1. Generate Key Pairs

#### RSA Key Generation
```bash
# Generate RSA private key (2048 bits)
openssl genrsa -out private_key.pem 2048

# Extract public key
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

#### ECDSA Key Generation
```bash
# Generate ECDSA private key (prime256v1 curve)
openssl ecparam -name prime256v1 -genkey -noout -out private_key.pem

# Extract public key
openssl ec -in private_key.pem -pubout -out public_key.pem
```

### 2. Create Key Group in CloudFront

#### Using AWS CLI
```bash
# First, create the public key in CloudFront
aws cloudfront create-public-key \
    --public-key-config '{
        "CallerReference": "my-key-2025",
        "Name": "my-public-key",
        "EncodedKey": "'$(cat public_key.pem)'",
        "Comment": "Public key for signed URLs"
    }'

# Create key group with the public key ID
aws cloudfront create-key-group \
    --key-group-config '{
        "Name": "my-key-group",
        "Items": ["PUBLIC_KEY_ID"],
        "Comment": "Key group for application content"
    }'
```

**Source:** [AWS CLI Reference - create-key-group](https://docs.aws.amazon.com/cli/latest/reference/cloudfront/create-key-group.html)

### 3. Configure Distribution

Add the key group to your CloudFront distribution's cache behavior:

```json
{
    "TrustedKeyGroups": {
        "Enabled": true,
        "Quantity": 1,
        "Items": ["KEY_GROUP_ID"]
    }
}
```

### 4. Generate Signed URLs (Python/Boto3)

```python
import datetime
import json
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives import serialization
from botocore.signers import CloudFrontSigner

def rsa_signer(message):
    # Load private key
    with open('private_key.pem', 'rb') as key_file:
        private_key = serialization.load_pem_private_key(
            key_file.read(),
            password=None
        )
    # Sign the message
    return private_key.sign(
        message,
        padding.PKCS1v15(),
        hashes.SHA1()
    )

# Create CloudFront signer
key_id = 'YOUR_PUBLIC_KEY_ID'  # From CloudFront console
cf_signer = CloudFrontSigner(key_id, rsa_signer)

# Generate signed URL
url = 'https://d111111abcdef8.cloudfront.net/private/file.pdf'
expire_date = datetime.datetime.utcnow() + datetime.timedelta(hours=1)

signed_url = cf_signer.generate_presigned_url(
    url,
    date_less_than=expire_date
)
```

**Source:** [AWS CloudFront Documentation - Code Examples](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateCFSignatureCodeAndExamples.html)

### 5. Generate Signed Cookies

```python
# For signed cookies with custom policy
policy = {
    "Statement": [{
        "Resource": "https://d111111abcdef8.cloudfront.net/content/*",
        "Condition": {
            "DateLessThan": {
                "AWS:EpochTime": int(expire_date.timestamp())
            },
            "IpAddress": {
                "AWS:SourceIp": "192.0.2.0/24"
            }
        }
    }]
}

# Create signed cookie values
cookies = cf_signer.generate_presigned_url(
    url=None,
    policy=json.dumps(policy)
)

# Set three required cookies:
# CloudFront-Policy, CloudFront-Signature, CloudFront-Key-Pair-Id
```

## Security Best Practices

### 1. Key Rotation
- Rotate keys periodically (recommended: every 90 days)
- Maintain overlapping validity periods during rotation
- Use multiple keys in a key group for seamless rotation

### 2. Policy Restrictions
- **Shortest Expiration:** Set the minimum viable expiration time
- **IP Restrictions:** Include source IP in custom policies when possible
- **Secure Attribute:** Always use Secure flag for cookies
- **Avoid Expires/Max-Age:** For cookies, omit to auto-delete on browser close

### 3. IAM Permissions Example
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudfront:CreatePublicKey",
                "cloudfront:GetPublicKey",
                "cloudfront:ListPublicKeys"
            ],
            "Resource": "*",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "203.0.113.0/24"
                },
                "Bool": {
                    "aws:MultiFactorAuthPresent": "true"
                }
            }
        },
        {
            "Effect": "Deny",
            "Action": "cloudfront:DeletePublicKey",
            "Resource": "*"
        }
    ]
}
```

## Common Use Cases

### 1. Premium Content Delivery
- Video streaming platforms with subscriber-only content
- Use signed cookies for all video segments
- Set cookie expiration based on subscription validity

### 2. Software Downloads
- Licensed software distribution
- Use signed URLs for individual downloads
- Track download attempts per license

### 3. Document Management
- Corporate document portals
- Use signed cookies for session-based access
- Implement IP restrictions for added security

### 4. E-Learning Platforms
- Course material access control
- Signed cookies for enrolled students
- Time-limited access aligned with course duration

## Troubleshooting

### Common Issues

1. **403 Forbidden Errors**
   - Verify key pair match (public in CloudFront, private for signing)
   - Check policy expiration times
   - Ensure key group is associated with distribution
   - Validate signature generation algorithm

2. **Clock Skew Issues**
   - CloudFront allows 5-minute clock skew
   - Use UTC times consistently
   - Consider adding buffer to start times

3. **Cookie Not Being Sent**
   - Ensure domain/path attributes are correct
   - Verify Secure attribute with HTTPS
   - Check browser cookie settings

## AWS Service Integration

### With Other AWS Services

- **AWS Certificate Manager (ACM):** Manages TLS certificates for HTTPS
- **AWS Lambda@Edge:** Dynamically generate signed URLs/cookies
- **AWS IAM:** Control who can manage keys and key groups
- **AWS Systems Manager Parameter Store:** Securely store private keys
- **AWS Secrets Manager:** Rotate private keys automatically

## Summary

Trusted Key Groups provide a secure, scalable, and manageable way to implement private content delivery through CloudFront. By following AWS best practices and using key groups instead of root account credentials, you can:

- Maintain better security posture
- Automate key management
- Implement granular access controls
- Scale to support multiple applications and use cases

The choice between signed URLs and signed cookies depends on your specific use case, but both benefit from the enhanced security and management capabilities of trusted key groups.

## References

1. [AWS CloudFront Documentation - Private Content with Signed URLs and Cookies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateContent.html)
2. [AWS CloudFront Documentation - Specify Signers](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html)
3. [AWS CloudFront API Reference - TrustedKeyGroups](https://docs.aws.amazon.com/cloudfront/latest/APIReference/API_TrustedKeyGroups.html)
4. [AWS Blog - CloudFront IAM Support Announcement](https://aws.amazon.com/about-aws/whats-new/2020/10/cloudfront-iam-signed-url/)
5. [AWS CloudFront Documentation - Code Examples for Signed URLs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PrivateCFSignatureCodeAndExamples.html)
6. [AWS CloudFront Documentation - Choosing Signed URLs vs Cookies](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-choosing-signed-urls-cookies.html)