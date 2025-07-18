terraform {
  required_version = "~> 1.5.0"

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "mytfstate123"
    container_name       = "tfstate"
    key                  = "dev.tfstate"
  }
}
provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Use your existing resource groups
resource "azurerm_resource_group" "main" {
  name     = "myapp-${var.environment}-rg"  # Matches your existing RGs
  location = "southindia"  # Your specified region
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Example VNET - modify as needed
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.environment}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = azurerm_resource_group.main.tags
}
