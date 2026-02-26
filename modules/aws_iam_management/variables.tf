variable "iam_inline_policy" {
  description = "Optional override for the IAM role inline policy (JSON string). If not set, the policy from the P0 staged resource is used."
  type        = string
  default     = null
}

variable "identity_center_account_id" {
  description = "AWS account ID that hosts IAM Identity Center (SSO); can be either the management account or a delegated admin account."
  type        = string
}

