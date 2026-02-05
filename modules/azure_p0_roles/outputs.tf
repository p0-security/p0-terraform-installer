
output "registration_client_id" {
  value       = azuread_application_registration.p0_registration.client_id
  description = "The client ID of the Azure AD application registration"
}


output "vm_admin_access_role_id" {
  value       = azurerm_role_definition.vm_admin_access.role_definition_resource_id
  description = "The role ID for VM admin access"
}

output "vm_standard_access_role_id" {
  value       = azurerm_role_definition.vm_standard_access.role_definition_resource_id
  description = "The role ID for VM standard access"
}
