terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # Change this to "~> 4.37"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
