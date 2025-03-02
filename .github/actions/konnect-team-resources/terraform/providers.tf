provider "konnect" {
  system_account_access_token = var.system_account_access_token
  server_url                  = var.konnect_server_url
}

provider "aws" {
  region = var.aws_region
}
