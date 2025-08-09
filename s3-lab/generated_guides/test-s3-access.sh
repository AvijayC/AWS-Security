#!/bin/bash

# S3 buckets to test
BUCKETS=(
    "example-bucket-1-sse-s3"
    "example-bucket-2-sse-kms"
    "example-bucket-3-sse-s3-vpce-a"
    "example-bucket-4-sse-kms-vpce-a"
    "example-bucket-5-sse-s3-vpce-b"
    "example-bucket-6-sse-kms-vpce-b"
)

# User profiles (you'll need to set these up first with aws configure sso)
PROFILES=(
    "test-admin-1"
    "test-user-1"
    "test-user-2"
    "test-admin-2"
    "test-user-3"
    "test-user-4"
)

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "S3 Access Test Results"
echo "======================"
echo ""

# Test each user against each bucket
for profile in "${PROFILES[@]}"; do
    echo "Testing user: $profile"
    echo "-------------------"
    
    for bucket in "${BUCKETS[@]}"; do
        printf "  %-35s: " "$bucket"
        
        # Test list operation
        if aws s3 ls "s3://$bucket/" --profile "$profile" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ LIST${NC}"
        else
            echo -e "${RED}✗ DENIED${NC}"
        fi
    done
    echo ""
done

# Optional: Test specific operations
echo "Detailed Operation Tests"
echo "========================"
echo ""

for profile in "${PROFILES[@]}"; do
    echo "User: $profile"
    for bucket in "${BUCKETS[@]}"; do
        echo "  Bucket: $bucket"
        
        # Test LIST
        printf "    LIST: "
        if aws s3 ls "s3://$bucket/" --profile "$profile" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
        
        # Test GET (if you have test objects)
        printf "    GET:  "
        if aws s3 cp "s3://$bucket/test-object.txt" - --profile "$profile" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗${NC}"
        fi
        
        # Test PUT
        printf "    PUT:  "
        if echo "test" | aws s3 cp - "s3://$bucket/test-write-$profile.txt" --profile "$profile" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}"
            # Clean up test file
            aws s3 rm "s3://$bucket/test-write-$profile.txt" --profile "$profile" >/dev/null 2>&1
        else
            echo -e "${RED}✗${NC}"
        fi
    done
    echo ""
done