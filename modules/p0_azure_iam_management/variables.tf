variable "directory_id" {
  description = "The Azure directory ID (also known as tenant ID)"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "management_group_id" {
  description = "The management group ID to assign the P0 service principal"
  type        = string
}

variable "azure_application_registration_client_id" {
  description = "The client ID of the Azure AD application registration"
  type        = string
}

variable "vm_admin_access_role_id" {
  description = "The role ID for VM admin access"
  type        = string
}

variable "vm_standard_access_role_id" {
  description = "The role ID for VM standard access"
  type        = string
}

variable "azure_bastion_id" {
  description = "The ID of the Azure bastion host"
  type        = string
}
