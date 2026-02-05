variable "ssh_only" {
  description = "Enable SSH-only condition restriction"
  type        = bool
  default     = false
}

variable "management_group_id" {
  description = "The management group ID to assign the P0 service principal"
  type        = string
}

variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "azure_application_name" {
  description = "The name of the Azure AD application"
  type        = string
}

variable "gcp_service_account_id" {
  description = "The P0 service account ID"
  type        = string
}
