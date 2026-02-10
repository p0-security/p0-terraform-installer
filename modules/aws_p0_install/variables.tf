variable "gcp_service_account_id" {
  description = "The GCP service account ID that P0 uses to access the AWS account"
  type        = string
  default     = "106141354930392279110"
}

variable "identity_center_parent_account_id" {
  description = "Account ID where IAM Identity Center lives (org management or delegated admin); used for SSO resource conditions"
  type        = string
}
