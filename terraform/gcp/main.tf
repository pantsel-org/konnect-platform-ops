terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }

    # vault = {
    #   source  = "hashicorp/vault"
    #   version = "4.6.0"
    # }
  }
}
# Create a Service Account for Vault
resource "google_service_account" "vault" {
  account_id   = "vault-dev-sa"
  display_name = "Vault Development Service Account"
}

# Grant necessary IAM permissions to the service account
resource "google_project_iam_member" "vault_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/iam.serviceAccountUser",
    "roles/storage.objectAdmin",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.vault.email}"
}

# Deploy Vault on Cloud Run
resource "google_cloud_run_service" "vault" {
  name     = "vault-dev"
  location = var.region

  template {
    metadata {
      annotations = {
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/startup-cpu-boost"     = "false"
        "run.googleapis.com/timeoutSeconds"        = "600"
        "autoscaling.knative.dev/minScale"         = "1"
        "autoscaling.knative.dev/maxScale"         = "1"
      }
    }

    spec {
      containers {
        image = "hashicorp/vault:latest"
        args  = ["server", "-dev"]

        ports {
          container_port = 8200
        }

        env {
          name  = "VAULT_DEV_LISTEN_ADDRESS"
          value = "0.0.0.0:8200"
        }

        env {
          name  = "VAULT_DEV_ROOT_TOKEN_ID"
          value = var.vault_root_token
        }
      }

      service_account_name = google_service_account.vault.email
    }
  }
}



# Expose the Cloud Run service publicly for testing
resource "google_cloud_run_service_iam_member" "vault_public_access" {
  service  = google_cloud_run_service.vault.name
  location = google_cloud_run_service.vault.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

data "google_cloud_run_service" "vault" {
  name     = google_cloud_run_service.vault.name
  location = google_cloud_run_service.vault.location
}

# provider "vault" {
#   address = "https://vault-dev-2gcpdhyo5a-ez.a.run.app"
#   token   = "admin"
# }

# resource "vault_mount" "pki" {
#   path        = "pki"
#   type        = "pki"
#   description = "PKI for issuing TLS certificates"
# }

# resource "vault_pki_secret_backend_root_cert" "root_cert" {
#   depends_on           = [vault_mount.pki]
#   backend              = vault_mount.pki.path
#   type                 = "internal"
#   common_name          = "ca.kong.edu.demo"
#   ttl                  = "315360000"
#   format               = "pem"
#   private_key_format   = "der"
#   key_type             = "rsa"
#   key_bits             = 4096
#   exclude_cn_from_sans = true
#   ou                   = "IT"
#   organization         = "Kong EDU Demo"
# }

# resource "vault_pki_secret_backend_config_urls" "pki_urls" {
#   backend = vault_mount.pki.path

#   issuing_certificates    = ["${data.google_cloud_run_service.vault.status[0].url}/v1/${vault_mount.pki.path}/ca"]
#   crl_distribution_points = ["${data.google_cloud_run_service.vault.status[0].url}/v1/${vault_mount.pki.path}/crl"]
# }

# resource "vault_pki_secret_backend_role" "kong" {
#   backend = vault_mount.pki.path

#   name             = "kong"
#   allowed_domains  = ["kong.edu.demo"]
#   allow_subdomains = true
#   max_ttl          = "4380h"  # 6 months
# }


output "vault_url" {
  value = data.google_cloud_run_service.vault.status[0].url
}
