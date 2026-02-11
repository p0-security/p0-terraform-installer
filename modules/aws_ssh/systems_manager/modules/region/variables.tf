variable "enabled_vpcs" {
  description = "Set of VPC IDs to enable AWS Systems Manager VPC endpoints for."
  type        = set(string)
}

variable "default_host_management_role_path" {
  description = "The role path of the IAM role to use for host management"
  type        = string
}

variable "default_host_management_role_name" {
  description = "Name of IAM role to use for host management"
  type        = string
}
