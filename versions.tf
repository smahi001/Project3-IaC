terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # or your preferred version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
