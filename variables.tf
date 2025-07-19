variable "environment" {
  type        = string
  description = "Deployment environment (dev/staging/prod)"
}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = string
    service_endpoints = optional(list(string))
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
    })))
  }))
}
