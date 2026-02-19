variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "rds_instance_arn" {
  description = "RDS cluster instance ARN"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}
