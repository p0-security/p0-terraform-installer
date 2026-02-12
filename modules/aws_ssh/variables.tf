variable "regional_aws" {
  description = "Per-region configuration (enabled VPCs for SSM, etc.)"
  type = map(object({
    enabled_vpcs = set(string)
  }))
}

variable "aws_account_id" {
  description = "AWS account ID for the P0 SSH integration"
  type        = string
}

variable "aws_group_key" {
  description = "Tag key used to group instances for SSH access requests"
  type        = string
}

variable "aws_is_sudo_enabled" {
  description = "Whether users can request sudo access on instances"
  type        = bool
}
