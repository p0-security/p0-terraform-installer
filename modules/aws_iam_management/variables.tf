variable "iam_inline_policy" {
  description = "Optional override for the IAM role inline policy (JSON string). If not set, the policy from the P0 staged resource is used."
  type        = string
  default     = null
}

