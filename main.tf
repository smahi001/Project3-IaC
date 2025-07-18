provider "azurerm" {
  features {}
  
  # Explicitly configure authentication via environment variables
  # These will be set in Jenkins
  use_msi = false
  skip_provider_registration = true
}
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "mytfstate123"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  address_space       = var.address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnets" {
  count                = length(var.subnet_prefixes)
  name                 = "subnet-${count.index}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_prefixes[count.index]]
}
