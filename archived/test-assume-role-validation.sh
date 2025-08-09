#!/bin/bash

# Test script for validating username matching in role assumption

ROLE_ARN="arn:aws:iam::957401190575:role/ABAC-S3-Test-Role"
SSO_ROLE_NAME="AWSReservedSSO_ReadOnlyAccessWithABACAssumeRole_14f5f79043c2ff3b"

echo "Testing role assumption with username validation..."
echo ""

# Test 1: Correct username (should succeed)
echo "Test 1: Assuming role with matching username (should succeed)"
aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "test-session-$(date +%s)" \
    --tags Key=username_owner,Value=aalsg-user-1 \
           Key=sample_access_flag_A,Value=true \
    --query 'AssumedRoleUser.Arn' \
    --output text 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Success: Role assumed with matching username"
else
    echo "❌ Failed: Could not assume role with matching username"
fi

echo ""

# Test 2: Wrong username (should fail)
echo "Test 2: Assuming role with mismatched username (should fail)"
aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "test-session-$(date +%s)" \
    --tags Key=username_owner,Value=wrong-user \
           Key=sample_access_flag_A,Value=true \
    --query 'AssumedRoleUser.Arn' \
    --output text 2>&1

if [ $? -ne 0 ]; then
    echo "✅ Success: Role assumption correctly denied for wrong username"
else
    echo "❌ Failed: Role assumption should have been denied"
fi

echo ""

# Test 3: With SSO role name tag (for Approach 2)
echo "Test 3: Assuming role with SSO role name tag"
aws sts assume-role \
    --role-arn "${ROLE_ARN}" \
    --role-session-name "test-session-$(date +%s)" \
    --tags Key=username_owner,Value=aalsg-user-1 \
           Key=sso_role_name,Value="${SSO_ROLE_NAME}" \
           Key=sample_access_flag_A,Value=true \
    --query 'AssumedRoleUser.Arn' \
    --output text 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Success: Role assumed with SSO role validation"
else
    echo "❌ Failed: Could not assume role with SSO role validation"
fi