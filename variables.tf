variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "prefix" {
  description = "Resource naming prefix"
  type        = string
}

variable "resource_group_name" {
  description = "Azure Resource Group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "southindia"
}

variable "virtual_network_name" {
  description = "Virtual Network name"
  type        = string
}

variable "address_space" {
  description = "Virtual Network address space"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
}

variable "vm_size" {
  description = "Virtual Machine size"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
}

variable "db_sku_name" {
  description = "Database SKU name"
  type        = string
}

variable "db_storage_mb" {
  description = "Database storage in MB"
  type        = number
}

variable "enable_monitoring" {
  description = "Enable monitoring resources"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
