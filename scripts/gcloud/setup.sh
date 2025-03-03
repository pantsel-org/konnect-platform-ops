#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Set default values
DEFAULT_REGION="europe-west4"
DEFAULT_GC_PROJECT_ID="konnect-platform-ops"
DEFAULT_VAULT_STORAGE_BUCKET="kpo-vault-storage"
DEFAULT_GITHUB_ORG="pantsel-org"
DEFAULT_GITHUB_REPO="konnect-platform-ops"

# Function to print messages
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

# Prompt user for input with defaults
read -p "$(echo -e ${YELLOW}Google Cloud region [${DEFAULT_REGION}]: ${NC})" REGION
REGION=${REGION:-$DEFAULT_REGION}

read -p "$(echo -e ${YELLOW}Google Cloud project ID [${DEFAULT_GC_PROJECT_ID}]: ${NC})" GC_PROJECT_ID
GC_PROJECT_ID=${GC_PROJECT_ID:-$DEFAULT_GC_PROJECT_ID}

read -p "$(echo -e ${YELLOW}Vault storage bucket name [${DEFAULT_VAULT_STORAGE_BUCKET}]: ${NC})" VAULT_STORAGE_BUCKET
VAULT_STORAGE_BUCKET=${VAULT_STORAGE_BUCKET:-$DEFAULT_VAULT_STORAGE_BUCKET}

read -p "$(echo -e ${YELLOW}GitHub organization [${DEFAULT_GITHUB_ORG}]: ${NC})" GITHUB_ORG
GITHUB_ORG=${GITHUB_ORG:-$DEFAULT_GITHUB_ORG}

read -p "$(echo -e ${YELLOW}GitHub repository [${DEFAULT_GITHUB_REPO}]: ${NC})" GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-$DEFAULT_GITHUB_REPO}

print_message "Enabling required Google Cloud services..."
gcloud services enable run.googleapis.com \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com \
    secretmanager.googleapis.com \
    sqladmin.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com

# Create a Workload Identity Pool
print_message "Creating Workload Identity Pool..."
if ! gcloud iam workload-identity-pools describe "github-pool" --location="global" &>/dev/null; then
    gcloud iam workload-identity-pools create "github-pool" \
        --location="global" \
        --display-name="GitHub Pool"
    echo -e "${GREEN}Workload Identity Pool 'github-pool' created.${NC}"
else
    echo -e "${YELLOW}Workload Identity Pool 'github-pool' already exists.${NC}"
fi

# Create a Workload Identity Provider
print_message "Creating Workload Identity Provider..."
if ! gcloud iam workload-identity-pools providers describe "github-provider" --location="global" --workload-identity-pool="github-pool" &>/dev/null; then
    gcloud iam workload-identity-pools providers create-oidc "github-provider" \
        --project="$GC_PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="github-pool" \
        --display-name="GitHub Actions Provider" \
        --issuer-uri="https://token.actions.githubusercontent.com/" \
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.ref=assertion.ref" \
        --attribute-condition="attribute.repository=='$GITHUB_ORG/$GITHUB_REPO' && attribute.ref=='refs/heads/main'"
    echo -e "${GREEN}Workload Identity Provider 'github-provider' created.${NC}"
else
    echo -e "${YELLOW}Workload Identity Provider 'github-provider' already exists.${NC}"
fi

# This Service Account (SA) will be assumed by GitHub.
print_message "Creating Service Account for GitHub Actions..."
if ! gcloud iam service-accounts describe "github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com" &>/dev/null; then
    gcloud iam service-accounts create "github-actions" \
        --display-name="GitHub Actions SA"
    echo -e "${GREEN}Service Account 'github-actions' created.${NC}"
else
    echo -e "${YELLOW}Service Account 'github-actions' already exists.${NC}"
fi

print_message "Binding roles to the Service Account..."
gcloud projects add-iam-policy-binding $GC_PROJECT_ID \
    --member="serviceAccount:github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Allow GitHub Workload Identity to Assume the SA
print_message "Allowing GitHub Workload Identity to assume the Service Account..."
gcloud iam service-accounts add-iam-policy-binding \
    github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $GC_PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB_ORG/$GITHUB_REPO"

echo -e "${GREEN}Setup completed successfully!${NC}"
