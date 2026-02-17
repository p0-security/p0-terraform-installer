variable "gcp_organization_id" {
  description = "The GCP Organization ID"
  type        = number
}

variable "gcp_project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "service_account_email" {
  description = "The P0 service account email"
  type        = string
}

variable "security_perimeter_email" {
  description = "The Security Perimeter service account email"
  type        = string
}

variable "gcp_group_key" {
  description = "The tag key used to group GCP instances. Access can be requested, in one request, to all instances with a shared tag value"
  type        = string
}

variable "gcp_is_sudo_enabled" {
  description = "If true, users will be able to request sudo access to the instances"
  type        = bool
}
