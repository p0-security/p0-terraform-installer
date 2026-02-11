variable "gcp_service_account_id" {
  description = "The GCP service account ID that P0 uses to access the AWS account"
  type        = string
}

variable "identity_center_parent_account_id" {
  description = "Account ID where IAM Identity Center lives (org management or delegated admin)"
  type        = string
}

variable "saml_identity_provider_name" {
  description = "Name of the SAML identity provider in AWS that the P0 grant roles must trust"
  type        = string
}

variable "role_count" {
  description = "Number of P0GrantsRole* roles to create for access requests"
  type        = number
}
