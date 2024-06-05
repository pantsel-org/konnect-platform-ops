terraform {
  backend "s3" {}
  required_providers {
    konnect = {
      source = "kong/konnect"
    }
  }
}

provider "konnect" {
  personal_access_token = var.konnect_personal_access_token
  server_url            = var.konnect_server_url
}

provider "konnect" {
  alias                 = "global"
  personal_access_token = var.konnect_personal_access_token
  server_url            = "https://global.api.konghq.com"
}


variable "module_to_run" {
  description = "Specify which module to run ('federated', or 'central')"
  type        = string
  default     = "central"
}

module "federated" {
  source  = "./modules/federated"
  # count  = var.module_to_run == "federated" ? 1 : 0
  providers = {
    konnect.global = konnect.global
  }
}

# module "module_b" {
#   source = "./modules/central"
#   count  = var.module_to_run == "central" ? 1 : 0
# }
