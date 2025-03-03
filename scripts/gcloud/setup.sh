set -e

REGION=europe-west4
GC_PROJECT_ID=konnect-platform-ops
VAULT_STORAGE_BUCKET=kpo-vault-storage
GITHUB_ORG=pantsel-org
GITHUB_REPO=konnect-platform-ops

gcloud services enable run.googleapis.com \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com \
    secretmanager.googleapis.com \
    sqladmin.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com

# Create a Workload Identity Pool
if ! gcloud iam workload-identity-pools describe "github-pool" --location="global" &>/dev/null; then
    gcloud iam workload-identity-pools create "github-pool" \
        --location="global" \
        --display-name="GitHub Pool"
else
    echo "Workload Identity Pool 'github-pool' already exists."
fi

# Create a Workload Identity Provider
if ! gcloud iam workload-identity-pools providers describe "github-provider" --location="global" --workload-identity-pool="github-pool" &>/dev/null; then
    gcloud iam workload-identity-pools providers create-oidc "github-provider" \
        --project="$GC_PROJECT_ID" \
        --location="global" \
        --workload-identity-pool="github-pool" \
        --display-name="GitHub Actions Provider" \
        --issuer-uri="https://token.actions.githubusercontent.com/" \
        --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository,attribute.actor=assertion.actor,attribute.ref=assertion.ref" \
        --attribute-condition="attribute.repository=='$GITHUB_ORG/$GITHUB_REPO' && attribute.ref=='refs/heads/main'"
        

else
    echo "Workload Identity Provider 'github-provider' already exists."
fi

# This Service Account (SA) will be assumed by GitHub.
if ! gcloud iam service-accounts describe "github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com" &>/dev/null; then
    gcloud iam service-accounts create "github-actions" \
        --display-name="GitHub Actions SA"
else
    echo "Service Account 'github-actions' already exists."
fi

gcloud projects add-iam-policy-binding $GC_PROJECT_ID \
    --member="serviceAccount:github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/owner"

# Allow GitHub Workload Identity to Assume the SA
gcloud iam service-accounts add-iam-policy-binding \
    github-actions@$GC_PROJECT_ID.iam.gserviceaccount.com \
    --role="roles/iam.workloadIdentityUser" \
    --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $GC_PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/github-pool/attribute.repository/$GITHUB_ORG/$GITHUB_REPO"




