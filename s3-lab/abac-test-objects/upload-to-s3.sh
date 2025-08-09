#!/bin/bash

# Upload test objects to S3 with ABAC tags
# Usage: ./upload-to-s3.sh <bucket-name> [profile]

BUCKET=${1:-avijay-lab-1-sse-s3}
PROFILE=${2:-awssec-gen-admin}

echo "Uploading ABAC test objects to bucket: $BUCKET"
echo "Using profile: $PROFILE"
echo ""

# Process each object in manifest
cat manifest.json | jq -c '.objects[]' | while read -r obj; do
  # Extract file path and tags
  LOCAL_PATH=$(echo "$obj" | jq -r '.local_path')
  S3_KEY=$(echo "$obj" | jq -r '.s3_key')
  
  # Extract individual tags
  FLAG_A=$(echo "$obj" | jq -r '.tags.sample_access_flag_A')
  VPCE_FLAG=$(echo "$obj" | jq -r '.tags.vpce_access_flag')
  OWNER=$(echo "$obj" | jq -r '.tags.username_owner')
  
  # Build tagging string
  TAGGING="sample_access_flag_A=$FLAG_A&vpce_access_flag=$VPCE_FLAG&username_owner=$OWNER"
  
  echo "Uploading: $LOCAL_PATH"
  echo "  -> s3://$BUCKET/$S3_KEY"
  echo "  Tags: $TAGGING"
  
  # Upload file first
  aws s3 cp "$LOCAL_PATH" "s3://$BUCKET/$S3_KEY" \
    --profile "$PROFILE" \
    --no-progress
  
  if [ $? -eq 0 ]; then
    # Apply tags after upload
    aws s3api put-object-tagging \
      --bucket "$BUCKET" \
      --key "$S3_KEY" \
      --tagging "TagSet=[{Key=sample_access_flag_A,Value=$FLAG_A},{Key=vpce_access_flag,Value=$VPCE_FLAG},{Key=username_owner,Value=$OWNER}]" \
      --profile "$PROFILE" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
      echo "  ✓ Success (uploaded and tagged)"
    else
      echo "  ✓ Uploaded, ✗ Tagging failed"
    fi
  else
    echo "  ✗ Upload failed"
  fi
  echo ""
done

echo "Upload complete!"
echo ""
echo "To verify tags on an object:"
echo "aws s3api get-object-tagging --bucket $BUCKET --key <key> --profile $PROFILE"