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
    federation_app = object({
      app_name       = string
      enduser_note   = string
      aws_account_id = string
    })
    api_integration_app = object({
      app_name = string
    })
  })
}

variable "p0" {
  type = object({
    org_id = string
    project_id = string
    gcp_service_account_id = string
  })
}

variable "aws" {
  type = object({
    saml_identity_provider_name = string
    role_count                  = number
  })
}

# A map of region name to variables for that region
variable "regional_aws" {
  type = map(object({
    enabled_vpcs                    = set(string)
    is_resource_explorer_aggregator = bool
  }))
}

variable "gcp" {
  type = object({
    organization_id  = string
    project_id       = string
    location         = string
  })
}

variable "azure" {
  type = object({
    tenant_id              = string
    management_group_id    = string
    subscription_id        = string
    azure_application_name = string
    ssh_only               = bool
    region                 = string
  })
}


# Pass this as an environment variable to the Terraform process
variable "HEC_TOKEN_CLEARTEXT" {
  type      = string
  sensitive = true
}
