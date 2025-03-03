variable "project_id" {
  description = "The GCP project ID"
  type    = string
  default = "konnect-platform-ops"
}
variable "region" {
  description = "The region to create resources in"
  type    = string
  default = "europe-west4"
}
variable "vault_bucket_name" {
  description = "The name of the bucket to create for storing vault data"
  type    = string
  default = "kpo-vault-storage"
}

variable "vault_root_token" {
  description = "The root token for the vault"
  type    = string
}

variable "gcp_credentials" {
  type    = string
  default = "gcp-key.json"  # Default path for credentials file
}
