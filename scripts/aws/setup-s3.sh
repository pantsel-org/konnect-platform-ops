#!/bin/bash

BUCKET_NAME="konnect.teams"
GCP_BUCKET_NAME="gcp.resources"
REGION="eu-central-1"

create_bucket_if_not_exists() {
    local bucket_name=$1

    # Check if the bucket exists (silent check)
    if aws s3api head-bucket --bucket "$bucket_name" 2>&1 | grep -q 'Not Found'; then
        echo "Bucket '$bucket_name' does not exist. Creating..."
        
        # Create the bucket
        aws s3api create-bucket --bucket "$bucket_name" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION" >/dev/null 2>&1
        
        # Enable versioning (Optional)
        aws s3api put-bucket-versioning --bucket "$bucket_name" --versioning-configuration Status=Enabled >/dev/null 2>&1
        
        echo "✅ Bucket '$bucket_name' created successfully."
    else
        echo "✅ Bucket '$bucket_name' already exists. No action needed."
    fi
}

create_bucket_if_not_exists "$BUCKET_NAME"
create_bucket_if_not_exists "$GCP_BUCKET_NAME"
