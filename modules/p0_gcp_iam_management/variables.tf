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
