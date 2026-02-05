output "bastion_resource_id" {
  value       = azurerm_bastion_host.p0_bastion.id
  description = "The ID of the Azure bastion host"
}
