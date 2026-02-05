variable "saml_identity_provider_name" {
  description = "Name of the SAML identity provider in AWS that the P0 roles must trust"
}

// Note: After changing the role count, the roles must be synced into Okta using the "Refresh Application Data" button.
// button. Syncing is not possible via the Okta API - that is why we use a pre-created pool of roles.
// https://support.okta.com/help/s/article/Refresh-Application-Data-Functionality-and-Usage?language=en_US
variable "role_count" {
  description = "Number of P0 roles to create"
  default     = 10
}
