provider "google" {
  credentials = var.use_file_credentials ? file(var.gcp_credentials) : null
  project = var.project_id
  region  = var.region
}
