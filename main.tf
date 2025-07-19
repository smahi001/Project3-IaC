# Configure Terraform backend and providers
terraform {
  required_version = ">= 1.0.0"
  
  backend "azurerm" {
    # Configuration will be passed via CLI during init
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-${var.vnet_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = azurerm_resource_group.main.tags

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Subnets
resource "azurerm_subnet" "subnets" {
  count                = length(var.subnets)
  name                 = "${var.environment}-${var.subnets[count.index].name}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnets[count.index].address_prefix]

  depends_on = [azurerm_virtual_network.main]
}

# Network Security Group (Example additional resource)
resource "azurerm_network_security_group" "default" {
  name                = "${var.environment}-default-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = azurerm_resource_group.main.tags

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
