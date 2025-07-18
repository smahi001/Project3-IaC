provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "project3-rg"
  location = "southindia"
}

# Add other resources here
