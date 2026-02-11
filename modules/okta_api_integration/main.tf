terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = ">= 4.8.0"
    }
    p0 = {
      source  = "p0-security/p0"
      version = "0.24.0"
    }
  }
}

locals {
  org_url = "https://${var.org_domain}"
}

resource "p0_okta_directory_listing_staged" "p0_api_integration" {
  domain = var.org_domain
}

resource "okta_app_oauth" "p0_api_integration" {
  label                      = var.app_name
  type                       = "service"
  token_endpoint_auth_method = "private_key_jwt"
  pkce_required              = false
  grant_types                = ["client_credentials"]
  response_types             = ["token"]
  issuer_mode                = "DYNAMIC"

  # "Require Demonstrating Proof of Possession (DPoP) header in token requests" must be false.
  # This argument is not supported yet by the Terraform provider, however, the resulting application doesn't enable it when created from Terraform. (Created from the UI it defaults to true.)
  # dpop_bound_access_tokens = false

  jwks {
    kty = p0_okta_directory_listing_staged.p0_api_integration.jwk.kty
    kid = p0_okta_directory_listing_staged.p0_api_integration.jwk.kid
    e   = p0_okta_directory_listing_staged.p0_api_integration.jwk.e
    n   = p0_okta_directory_listing_staged.p0_api_integration.jwk.n
  }
}

output "client_id" {
  value = okta_app_oauth.p0_api_integration.client_id
}


# The scopes provided to the app are limited by the administrative roles assigned to the app
resource "okta_app_oauth_api_scope" "p0_api_integration_scopes" {
  app_id = okta_app_oauth.p0_api_integration.id
  issuer = local.org_url # Assumes that the application uses the default org domain
  scopes = [
    # Required for Okta group membership access
    "okta.users.read",
    "okta.groups.manage",
  ]
}

resource "okta_app_oauth_role_assignment" "p0_lister_role_assignment" {
  type         = "CUSTOM"
  client_id    = okta_app_oauth.p0_api_integration.client_id
  role         = var.p0_lister_role_id
  resource_set = var.p0_all_users_groups_id
}

resource "p0_okta_directory_listing" "p0_api_integration" {
  client     = okta_app_oauth.p0_api_integration.client_id
  domain     = p0_okta_directory_listing_staged.p0_api_integration.domain
  jwk        = p0_okta_directory_listing_staged.p0_api_integration.jwk
  depends_on = [okta_app_oauth_role_assignment.p0_lister_role_assignment]
}
