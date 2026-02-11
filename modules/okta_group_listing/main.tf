locals {
  org_url = "https://${var.org_domain}"
}

# --- Okta: Custom admin roles and resource set for directory listing ---
resource "okta_admin_role_custom" "p0_lister_role" {
  label       = "P0 Directory Lister"
  description = "Allows P0 Security to read all users and all groups"
  permissions = [
    "okta.users.read",
    "okta.groups.read"
  ]
}

resource "okta_resource_set" "p0_all_users_groups" {
  label       = "P0 All Users and Groups"
  description = "All users and all groups"
  resources = [
    "${local.org_url}/api/v1/users",
    "${local.org_url}/api/v1/groups"
  ]
}

# --- P0: Staged directory listing (provides JWK for Okta app) ---
resource "p0_okta_directory_listing_staged" "p0_api_integration" {
  domain = var.org_domain
}

# --- Okta: API integration service app (group listing) ---
resource "okta_app_oauth" "p0_api_integration" {
  label                      = var.api_integration_app_name
  type                       = "service"
  token_endpoint_auth_method = "private_key_jwt"
  pkce_required              = false
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  issuer_mode                = "DYNAMIC"

  jwks {
    kty = p0_okta_directory_listing_staged.p0_api_integration.jwk.kty
    kid = p0_okta_directory_listing_staged.p0_api_integration.jwk.kid
    e   = p0_okta_directory_listing_staged.p0_api_integration.jwk.e
    n   = p0_okta_directory_listing_staged.p0_api_integration.jwk.n
  }
}

resource "okta_app_oauth_api_scope" "p0_api_integration_scopes" {
  app_id = okta_app_oauth.p0_api_integration.id
  issuer = local.org_url
  scopes = [
    "okta.users.read",
    "okta.groups.read",
  ]
}

resource "okta_app_oauth_role_assignment" "p0_lister_role_assignment" {
  type         = "CUSTOM"
  client_id    = okta_app_oauth.p0_api_integration.client_id
  role         = okta_admin_role_custom.p0_lister_role.id
  resource_set = okta_resource_set.p0_all_users_groups.id
}

# --- P0: Finalize directory listing ---
resource "p0_okta_directory_listing" "p0_api_integration" {
  client     = okta_app_oauth.p0_api_integration.client_id
  domain     = p0_okta_directory_listing_staged.p0_api_integration.domain
  jwk        = p0_okta_directory_listing_staged.p0_api_integration.jwk
  depends_on = [okta_app_oauth_role_assignment.p0_lister_role_assignment]
}
