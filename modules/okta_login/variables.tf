variable "org_domain" {
  description = "Domain name of your Okta account, e.g. dev-123456.oktapreview.com"
  type        = string
}

variable "native_app" {
  description = "P0 native OIDC app for user login"
  type = object({
    app_name            = string
    app_redirect_uris   = list(string)
    implicit_assignment = optional(bool, false)
  })
}
