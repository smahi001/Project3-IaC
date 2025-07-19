environment = "staging"
location    = "southindia"

# Network Configuration
vnet_name          = "vnet-staging"
vnet_address_space = ["10.1.0.0/16"]

subnets = [
  {
    name           = "subnet-1"
    address_prefix = "10.1.1.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    nsg_rules = [
      {
        name                       = "AllowSSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "192.168.1.1"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name           = "subnet-2"
    address_prefix = "10.1.2.0/24"
  }
]

# Tagging Strategy
tags = {
  Environment  = "Staging"
  Owner        = "DevOps"
  CostCenter   = "IT-1234"
  SLA          = "24x7"
  Terraform    = "true"
  LastUpdated  = formatdate("DD-MM-YYYY hh:mm ZZZ", timestamp())
}
