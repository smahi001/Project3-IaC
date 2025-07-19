variable "environment" {
  description = "The deployment environment (dev, staging, production)"
  type        = string
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
