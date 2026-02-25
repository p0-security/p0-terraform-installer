variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = null
}

variable "aws_role_name" {
  description = "Name of the AWS IAM role for P0"
  type        = string
  default     = "P0RoleIamManager"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "rds_cluster_arn" {
  description = "RDS cluster instance ARN"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  nullable    = true
  default     = null
}
