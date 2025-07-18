terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0, < 4.0"  # or ">= 3.0, < 5.0" to allow v4
    }
  }
}
