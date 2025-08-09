#!/bin/bash

# Test ABAC access for each user against their files and others
# Usage: ./test-abac-access.sh <bucket-name>

BUCKET=${1:-avijay-lab-1-sse-s3}

echo "ABAC Access Test Report"
echo "======================="
echo "Bucket: $BUCKET"
echo "Date: $(date)"
echo ""

# Test users and their attributes
declare -A USERS
USERS["aalsg-user-1"]="957401190575"
USERS["aalsg-user-2"]="957401190575"
USERS["aalsb-user-1"]="455095160360"
USERS["aalsb-user-2"]="455095160360"

# Function to test access
test_access() {
  local username=$1
  local account=$2
  local test_file=$3
  
  # Assume role with username tag
  CREDS=$(aws sts assume-role \
    --role-arn arn:aws:iam::957401190575:role/ABAC-S3-Test-Role \
    --role-session-name "$username-abac-test" \
    --tags Key=username_owner,Value=$username \
    --profile awssec-gen-admin \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo "    [ERROR] Failed to assume role"
    return 1
  fi
  
  # Test with assumed credentials
  AWS_ACCESS_KEY_ID=$(echo $CREDS | cut -d' ' -f1) \
  AWS_SECRET_ACCESS_KEY=$(echo $CREDS | cut -d' ' -f2) \
  AWS_SESSION_TOKEN=$(echo $CREDS | cut -d' ' -f3) \
  aws s3api get-object \
    --bucket "$BUCKET" \
    --key "$test_file" \
    /dev/null 2>/dev/null
  
  return $?
}

# Test each user
for username in "${!USERS[@]}"; do
  account="${USERS[$username]}"
  echo "User: $username (Account: $account)"
  echo "----------------------------------------"
  
  # Test access to own files
  echo "  Testing access to own files:"
  for i in {1..4}; do
    # Calculate file number based on user
    case $username in
      "aalsg-user-1") file_num=$(printf "%03d" $i) ;;
      "aalsg-user-2") file_num=$(printf "%03d" $((i+4))) ;;
      "aalsb-user-1") file_num=$(printf "%03d" $((i+8))) ;;
      "aalsb-user-2") file_num=$(printf "%03d" $((i+12))) ;;
    esac
    
    test_file="home/$account/$username/test-file-$file_num.txt"
    
    if test_access "$username" "$account" "$test_file"; then
      echo "    ✓ $test_file"
    else
      echo "    ✗ $test_file"
    fi
  done
  
  # Test access to another user's file (should fail)
  echo "  Testing cross-user access (should fail):"
  if [ "$username" == "aalsg-user-1" ]; then
    other_file="home/957401190575/aalsg-user-2/test-file-005.txt"
  else
    other_file="home/957401190575/aalsg-user-1/test-file-001.txt"
  fi
  
  if test_access "$username" "$account" "$other_file"; then
    echo "    ✓ $other_file (UNEXPECTED - should be denied)"
  else
    echo "    ✗ $other_file (Expected - access denied)"
  fi
  
  echo ""
done

echo "Test complete!"