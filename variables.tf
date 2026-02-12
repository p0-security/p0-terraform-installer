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
      # Set the OKTA_API_PRIVATE_KEY environment variable to the private key value starting with -----BEGIN PRIVATE KEY-----
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

variable "kubernetes" {
  type = object({
    cluster_id = string
    cluster_endpoint = string
    cluster_arn = string
    cluster_ca = string
    aws_region = string # us-west-2
    org = string # 1password
  })
}

variable "p0" {
  type = object({
    org_id            = string
    iam_inline_policy = optional(string)
  })
}

variable "aws" {
  type = object({
    group_key = optional(string)
  })
}

# A map of region name to variables for that region
variable "regional_aws" {
  type = map(object({
    enabled_vpcs                    = set(string)
    is_resource_explorer_aggregator = bool
  }))
}

variable "datadog" {
  type = object({
    intake_url        = string
    api_key_cleartext = string
  })
  description = "Datadog audit logs configuration"
  sensitive   = true
}
