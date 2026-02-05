variable "app_instance" {
  description = "The instance name for this deployment of our app. Previously called 'environment'."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "VPC Subnet(s) where the DocumentDB cluster will reside."
  type = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups that are allowed to connect to the DocumentDB cluster."
  type = list(string)
}

variable "oidc_provider" {
  description = "AWS IAM OIDC Provider that will be used to validate Kubernetes Service Account credentials. Must not include the 'https://' part of the provider."
  type = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace in which the P0 app will be installed."
  type = string
}

variable "service_role_count" {
  type    = number
  default = 1
}
