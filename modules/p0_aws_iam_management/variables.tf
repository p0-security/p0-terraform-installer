variable "aws_account_id" {
  description = "The AWS Account ID"
  type        = string
}

variable "aws_group_key" {
  description = "The tag key used to group AWS instances. Access can be requested, in one request, to all instances with a shared tag value"
  type        = string
}

variable "aws_is_sudo_enabled" {
  description = "If true, users will be able to request sudo access to the instances"
  type        = bool
}
