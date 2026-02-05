variable "cluster_name" {
  description = "Cluster name; '-docdb' and a random id will be appended to it."
  type        = string
}

# DocumentDB cluster configuration
variable "master_username" {
  description = "Master username for the DocumentDB cluster"
  type        = string
  default     = "docdbadmin"
}

variable "engine_version" {
  description = "DocumentDB engine version"
  type        = string
  default     = "5.0.0"
}

variable "kms_key_arn" {
  type     = string
  default  = null
  nullable = true
}

variable "cluster_size" {
  description = "Number of instances in the DocumentDB cluster"
  type        = number
  default     = 2
}

variable "instance_class" {
  description = "Instance class for DocumentDB cluster instances"
  type        = string
  default     = "db.r5.large"
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID where DocumentDB cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for DocumentDB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "ID of the security group allowed to access DocumentDB"
  type        = list(string)
}

# Backup and maintenance configuration
variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Daily time range for backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Weekly time range for system maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Security configuration
variable "skip_final_snapshot" {
  description = "Skip final snapshot when updating or deleting the cluster"
  type        = bool
  default     = true
}

# Production safeguards
variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

variable "bastion" {
  description = "If a bastion host should be created."
  type        = bool
  default     = true
}
