variable "tenant_id" {
  description = "The Azure tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "region" {
  description = "The Azure region to deploy resources"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to create"
  type        = string
}

variable "virtual_network_address_space" {
  description = "The address space for the virtual network"
  type        = string
}

variable "bastion_name" {
  description = "The name of the bastion host"
  type        = string
}

variable "bastion_subnet_address_prefix" {
  description = "The address prefix for the bastion subnet"
  type        = string
}

variable "bastion_scale_units" {
  description = "The number of scale units for the bastion host"
  type        = number
}
