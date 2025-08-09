#!/bin/bash

# Generate test files based on manifest.json
echo "Generating ABAC test files..."

# Parse manifest and create files
cat manifest.json | jq -r '.objects[] | .local_path' | while read filepath; do
  # Extract info from path
  username=$(echo "$filepath" | cut -d'/' -f3)
  filename=$(basename "$filepath")
  
  # Create file content with metadata
  cat > "$filepath" << EOF
ABAC Test File
==============
File: $filename
Owner: $username
Generated: $(date)

This is a test file for ABAC (Attribute-Based Access Control) testing.
The file's S3 tags will determine who can access it based on:
- sample_access_flag_A: Controls access based on flag A
- vpce_access_flag: Controls access through VPC endpoints
- username_owner: Identifies the owner of this file

Test content for security validation.
EOF

  echo "Created: $filepath"
done

echo "All test files generated successfully!"