variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network"
  
  validation {
    condition     = can([for s in var.vnet_address_space : regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", s)])
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "project3-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southindia"
}

variable "vnet_name" {
  description = "Virtual Network name"
  type        = string
}

variable "vnet_address_space" {
  description = "Virtual Network address space"
  type        = list(string)
}

variable "subnets" {
  description = "List of subnets"
  type = list(object({
    name           = string
    address_prefix = string
  }))
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
