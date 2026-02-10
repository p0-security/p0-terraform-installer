variable "okta" {
  type = object({
    # The org name of your Okta account, for example dev-123456.oktapreview.com would have an org name of dev-123456.
    org_name = string
    # The domain of your Okta account, for example dev-123456.oktapreview.com would have a base url of oktapreview.com.
    base_url = string
    tfauth = object({
      client_id      = string
      scopes         = set(string)
      private_key_id = string
      # Set the OKTA_API_PRIVATE_KEY environment variable to the private key value starting with ----BEGIN PRIVATE KEY----
    })
    native_app = object({
      app_name          = string
      app_redirect_uris = list(string)
    })
    api_integration_app = object({
      app_name = string
    })
  })
}

variable "p0" {
  type = object({
    org_id = string
  })
}

variable "aws" {
  type = object({
    saml_identity_provider_name = string
    role_count                  = number
    group_key                   = string
  })
}

# Account ID where the IAM Identity Center instance lives (e.g. org management account or delegated admin). If null, current account is used.
variable "identity_center_parent_account_id" {
  type        = string
  default     = null
  description = "Identity Center parent account ID; set in tfvars for org/delegated setups, leave unset for current account."
}

# A map of region name to variables for that region
variable "regional_aws" {
  type = map(object({
    enabled_vpcs                    = set(string)
    is_resource_explorer_aggregator = bool
  }))
}
