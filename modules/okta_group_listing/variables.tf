variable "org_domain" {
  description = "Domain name of your Okta account, e.g. dev-123456.oktapreview.com"
  type        = string
}

variable "api_integration_app_name" {
  description = "Name/label for the P0 Okta API integration service app (used for listing users and groups)"
  type        = string
}
