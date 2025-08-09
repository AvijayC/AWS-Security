#!/bin/bash

# Configuration
BUCKET_NAME="your-bucket-name"  # Replace with your actual bucket name
ROLE_NAME="ABAC-S3-Test-Role"
ACCOUNT_ID="957401190575"

echo "Setting up ABAC policies for S3 access..."

# 1. Apply the S3 bucket policy
echo "Applying S3 bucket policy..."
sed "s/your-bucket-name/${BUCKET_NAME}/g" s3-bucket-policy-abac.json > temp-bucket-policy.json
aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --policy file://temp-bucket-policy.json
rm temp-bucket-policy.json

# 2. Update the role trust policy
echo "Updating role trust policy..."
aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document file://ABAC-S3-Test-Role-trust-enhanced.json

# 3. Attach inline policy to the role
echo "Attaching inline policy to role..."
aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "ABAC-S3-Access-Policy" \
    --policy-document file://ABAC-S3-Test-Role-inline-policy.json

echo "ABAC policies applied successfully!"
echo ""
echo "Testing role assumption with matching username..."
echo "aws sts assume-role \\"
echo "    --role-arn arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME} \\"
echo "    --role-session-name test-session \\"
echo "    --tags Key=username_owner,Value=aalsg-user-1 \\"
echo "           Key=sample_access_flag_A,Value=true"