variable "regional_aws" {
  description = "Per-region configuration (e.g. which region is Resource Explorer aggregator)"
  type = map(object({
    is_resource_explorer_aggregator = bool
  }))
}

variable "aws_account_id" {
  description = "AWS account ID for the P0 resource inventory integration"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the IAM resource lister role"
  type        = map(string)
  default     = {}
}
