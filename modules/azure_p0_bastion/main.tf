# Bastion module for Azure resources
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.18.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


# Create Resource Group (if not exists)
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.region
}

# Create Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.bastion_name}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = [var.virtual_network_address_space]
}

# Create Bastion Subnet
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.bastion_subnet_address_prefix]
}

# Create Public IP for Bastion
resource "azurerm_public_ip" "bastion_ip" {
  name                = "${var.bastion_name}-public-ip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard" # Required for Bastion
}

# Create Azure Bastion
resource "azurerm_bastion_host" "p0_bastion" {
  name                = var.bastion_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"              # Required for Native client support
  scale_units         = var.bastion_scale_units # At least 2 scale units are required for standard sku
  tunneling_enabled   = true                    # Enable Native Client Support (for SSH and RDP tunneling)

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_ip.id
  }
}
