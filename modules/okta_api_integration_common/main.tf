terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = ">= 4.8.0"
    }
  }
}

locals {
  org_url = "https://${var.org_domain}"
}

# OAuth scopes alone are not sufficient to perform the administrative tasks P0 needs to perform.
# The administrative roles configuration below allows the following access type:
# 1) Read Okta users and groups
#   - Requires: custom role with "okta.users.read" and "okta.groups.read" permissions

# Read Okta users and groups
resource "okta_admin_role_custom" "p0_lister_role" {
  label       = "P0 Directory Lister"
  description = "Allows P0 Security to read all users and all groups"
  permissions = [
    "okta.users.read",
    "okta.groups.read"
  ]
}

output "p0_lister_role_id" {
  value = okta_admin_role_custom.p0_lister_role.id
}

resource "okta_resource_set" "p0_all_users_groups" {
  label       = "P0 All Users and Groups"
  description = "All users and all groups"
  resources = [
    "${local.org_url}/api/v1/users",
    "${local.org_url}/api/v1/groups"
  ]
}

output "p0_all_users_groups_id" {
  value = okta_resource_set.p0_all_users_groups.id
}
