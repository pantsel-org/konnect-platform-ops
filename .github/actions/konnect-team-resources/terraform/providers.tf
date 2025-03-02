provider "konnect" {
  konnect_access_token = var.konnect_access_token
  server_url            = var.konnect_server_url
}

provider "aws" {
  region = var.aws_region
}
