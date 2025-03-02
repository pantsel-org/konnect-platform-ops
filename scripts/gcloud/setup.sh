set -e

REGION=europe-west4
VAULT_STORAGE_BUCKET=kpo-vault-storage

gcloud services enable run.googleapis.com \
    cloudbuild.googleapis.com \
    cloudresourcemanager.googleapis.com \
    secretmanager.googleapis.com \
    sqladmin.googleapis.com \
    iam.googleapis.com

gsutil mb -l $REGION gs://$VAULT_STORAGE_BUCKET/