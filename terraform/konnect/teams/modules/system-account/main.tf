terraform {
  required_providers {
    konnect = {
      source = "kong/konnect"
    }
  }
}

locals {
  days_to_hours        = 365 * 24 // 1 year
  expiration_date      = timeadd(formatdate("YYYY-MM-DD'T'HH:mm:ssZ", timestamp()), "${local.days_to_hours}h")
}

### Foreach team, create system accounts
resource "konnect_system_account" "this" {

  name = "sa-${var.team_name}"
  description = "System account for creating control planes for the ${var.team_name} team"
  
  konnect_managed  = false
}

# Assign the system accounts to the teams
resource "konnect_system_account_team" "this" {
  team_id =  var.team_id

  account_id = konnect_system_account.this.id
}

# Assign systen account to org read only team
# resource "konnect_system_account_team" "org_admin_ro" {
#   team_id =  "34419646-a48f-4b83-af35-e8f7a521887a"

#   account_id = konnect_system_account.this.id
# }

### Add the control plane creator role to every team system account
resource "konnect_system_account_role" "cp_creators" {

  entity_id = "*"
  entity_region    = "eu" # Hardcoded for now
  entity_type_name = "Control Planes"
  role_name        = "Creator"
  account_id = konnect_system_account.this.id
}

### Add the control plane viewer role to every team system account
resource "konnect_system_account_role" "cp_viewers" {

  entity_id = "*"
  entity_region    = "eu" # Hardcoded for now
  entity_type_name = "Control Planes"
  role_name        = "Viewer"
  account_id = konnect_system_account.this.id
}

### Add the api product creator role to every team system account
resource "konnect_system_account_role" "ap_creators" {
  entity_id = "*"
  entity_region    = "eu" # Hardcoded for now
  entity_type_name = "API Products"
  role_name        = "Creator"
  account_id = konnect_system_account.this.id
}

### Add the api product viewer role to every team system account
resource "konnect_system_account_role" "ap_viewers" {
  entity_id = "*"
  entity_region    = "eu" # Hardcoded for now
  entity_type_name = "API Products"
  role_name        = "Viewer"
  account_id = konnect_system_account.this.id
}


# Create an access token for every system account
resource "konnect_system_account_access_token" "this" {
  name       = "${konnect_system_account.this.name}-token"
  expires_at = local.expiration_date
  account_id = konnect_system_account.this.id

}

output "system_account_token" {
  value = konnect_system_account_access_token.this.token

  sensitive = true
}