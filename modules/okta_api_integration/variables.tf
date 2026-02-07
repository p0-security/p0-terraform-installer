variable "app_name" {
  description = "Name of the P0 API Integration app"
}

variable "org_domain" {
  description = "This is the domain name of your Okta account, for example dev-123456.oktapreview.com."
}

variable "p0_org_id" {
  description = "This is the P0 organization ID"
}

variable "p0_lister_role_id" {
  description = "This is the id of the 'P0 Directory Lister' role"
}

variable "p0_all_users_groups_id" {
  description = "This is the id of the 'P0 All Users and Groups' resource set"
}

variable "p0_manager_role_id" {
  description = "This is the id of the 'P0 App Access Manager' role"
}
