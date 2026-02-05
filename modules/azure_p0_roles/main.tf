# Installation of P0 app registration and role assignment for IAM
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "= 3.1.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.18.0"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Define a custom role for P0 Service Management (IAM Write)
resource "azurerm_role_definition" "p0_service_management" {
  name        = "P0 Service Management"
  scope       = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  description = "Gives P0 Access to manage access to virtual machines"

  permissions {
    actions = [
      "Microsoft.Management/managementGroups/read",
      "Microsoft.Management/managementGroups/subscriptions/read",
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Authorization/roleAssignments/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/bastionHosts/read",
      "Microsoft.Network/bastionHosts/getactivesessions/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/bastionHosts/disconnectactivesessions/action",
      "Microsoft.Compute/virtualMachines/extensions/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/delete",
      "Microsoft.Network/virtualNetworks/peer/action"
    ]
  }

  assignable_scopes = [
    "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  ]
}

# Define a custom role for Virtual Machine Administrator Access (Sudo SSH)
resource "azurerm_role_definition" "vm_admin_access" {
  name        = "P0 Virtual Machine Administrator Access"
  scope       = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  description = "Grants a user read access to virtual machines and Sudo SSH access"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/bastionHosts/read"
    ]
    data_actions = [
      "Microsoft.Compute/virtualMachines/loginAsAdmin/action",
      "Microsoft.Compute/virtualMachines/login/action"
    ]
  }

  assignable_scopes = [
    "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  ]
}

# Virtual Machine Standard Access Role (SSH)
resource "azurerm_role_definition" "vm_standard_access" {
  name        = "P0 Virtual Machine Standard Access"
  scope       = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  description = "Grants a user read access to virtual machines and SSH access"

  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/bastionHosts/read"
    ]
    data_actions = [
      "Microsoft.Compute/virtualMachines/login/action"
    ]
  }

  assignable_scopes = [
    "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  ]
}

# Create the Azure AD application for the P0 service principal
resource "azuread_application_registration" "p0_registration" {
  display_name = var.azure_application_name
}

# Create a federated identity credential for the P0 service principal
resource "azuread_application_federated_identity_credential" "p0_integration" {
  depends_on     = [azuread_application_registration.p0_registration]
  application_id = azuread_application_registration.p0_registration.id
  display_name   = "P0Integration"
  description    = "P0 integration with Azure"
  issuer         = "https://accounts.google.com"
  subject        = var.gcp_service_account_id
  audiences      = ["api://AzureADTokenExchange"]
}

# Create the Azure AD service principal for the P0 service principal
resource "azuread_service_principal" "service_principal" {
  depends_on = [azuread_application_registration.p0_registration]
  client_id  = azuread_application_registration.p0_registration.client_id
}

# Assign the P0 Service Management role to the P0 service principal
resource "azurerm_role_assignment" "p0_management" {
  depends_on         = [azuread_service_principal.service_principal, azurerm_role_definition.p0_service_management, azurerm_role_definition.vm_admin_access, azurerm_role_definition.vm_standard_access]
  scope              = "/providers/Microsoft.Management/managementGroups/${var.management_group_id}"
  role_definition_id = azurerm_role_definition.p0_service_management.role_definition_resource_id
  principal_id       = azuread_service_principal.service_principal.object_id
  condition_version  = var.ssh_only ? "2.0" : null
  condition = var.ssh_only ? join("\n", [
    "(",
    " (",
    "  !(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})",
    " )",
    " OR",
    " (",
    "  @Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${basename(azurerm_role_definition.vm_admin_access.role_definition_id)},${basename(azurerm_role_definition.vm_standard_access.role_definition_id)}}",
    " )",
    ")",
    "AND",
    "(",
    " (",
    "  !(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})",
    " )",
    " OR",
    " (",
    "  @Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${basename(azurerm_role_definition.vm_admin_access.role_definition_id)},${basename(azurerm_role_definition.vm_standard_access.role_definition_id)}}",
    " )",
    ")"
  ]) : null
}

