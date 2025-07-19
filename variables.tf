# ========================
# GLOBAL CONFIGURATION
# ========================
variable "environment" {
  type        = string
  description = "Deployment environment (dev/staging/prod)"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, production."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources"
  default     = "eastus"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.resource_group_name))
    error_message = "Resource group name can only contain alphanumerics, hyphens and underscores."
  }
}

# ========================
# NETWORK CONFIGURATION
# ========================
variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
  validation {
    condition = alltrue([
      for cidr in var.vnet_address_space : can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", cidr))
    ])
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "subnets" {
  type = list(object({
    name                = string
    address_prefix      = string
    service_endpoints   = optional(list(string))
    enforce_private_link = optional(bool, false)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  description = "List of subnets with their configurations"
}

variable "enable_ddos_protection" {
  type        = bool
  default     = false
  description = "Enable Azure DDoS Protection Standard"
}

variable "network_watcher_name" {
  type        = string
  default     = ""
  description = "Name for Network Watcher resource"
}

# ========================
# COMPUTE CONFIGURATION
# ========================
variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "VM size for the environment"
}

variable "vm_admin_username" {
  type        = string
  sensitive   = true
  description = "Admin username for virtual machines"
}

variable "vm_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for virtual machines"
}

# ========================
# STORAGE CONFIGURATION
# ========================
variable "storage_account" {
  type = object({
    name                      = string
    tier                      = string
    replication_type          = string
    enable_https_traffic_only = bool
  })
  description = "Storage account configuration"
}

# ========================
# TAGGING & MONITORING
# ========================
variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default     = {}
}

variable "enable_monitoring" {
  type        = bool
  default     = true
  description = "Enable Azure Monitor for resources"
}

# ========================
# SECURITY CONFIGURATION
# ========================
variable "enable_private_endpoints" {
  type        = bool
  default     = false
  description = "Enable private endpoints for sensitive services"
}

variable "allowed_ip_ranges" {
  type        = list(string)
  default     = []
  description = "List of allowed IP ranges for NSG rules"
}
