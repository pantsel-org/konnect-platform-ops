#!/bin/bash

# Variables
ROOT_CA_NAME="KongEdu Root CA"
AWS_REGION="eu-central-1"   # Change to your AWS region
SECRET_NAME="KongEdu-RootCA-Secret"

# Generate CA private key
echo "🔑 Generating Root CA private key..."
openssl genrsa -out rootCA.key 4096

# Generate self-signed CA certificate with detailed Subject information
echo "📜 Creating self-signed Root CA certificate..."
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem -subj "/C=NL/ST=North Holland/L=Amsterdam/O=KongEdu/OU=IT/CN=KongEdu Root CA"

echo "✅ Root CA certificate and key generated successfully!"

# Convert private key and certificate to Base64 (for secure storage)
if [[ "$OSTYPE" == "darwin"* ]]; then
    ENCODED_KEY=$(base64 < rootCA.key | tr -d '\n')
    ENCODED_CERT=$(base64 < rootCA.pem | tr -d '\n')
else
    ENCODED_KEY=$(base64 -w 0 rootCA.key)
    ENCODED_CERT=$(base64 -w 0 rootCA.pem)
fi

# Check if AWS Secrets Manager entry already exists
EXISTING_SECRET=$(aws secretsmanager list-secrets --region "$AWS_REGION" --query "SecretList[?Name=='$SECRET_NAME'].Name" --output text)

if [ "$EXISTING_SECRET" == "$SECRET_NAME" ]; then
    echo "🔄 Updating existing secret in AWS Secrets Manager..."
    aws secretsmanager update-secret --region "$AWS_REGION" \
        --secret-id "$SECRET_NAME" \
        --secret-string "{\"RootCA_Key\":\"$ENCODED_KEY\", \"RootCA_Certificate\":\"$ENCODED_CERT\"}"
else
    echo "🆕 Creating new secret in AWS Secrets Manager..."
    aws secretsmanager create-secret --region "$AWS_REGION" \
        --name "$SECRET_NAME" \
        --secret-string "{\"RootCA_Key\":\"$ENCODED_KEY\", \"RootCA_Certificate\":\"$ENCODED_CERT\"}"
fi

echo "✅ Root CA private key and certificate stored securely in AWS Secrets Manager under '$SECRET_NAME'."

# Clean up local files (optional)
rm -f rootCA.key rootCA.pem

echo "🎉 Done! Your Root CA is securely stored in AWS."
