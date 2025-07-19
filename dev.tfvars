# ======================
# DEVELOPMENT ENVIRONMENT
# ======================
resource_group_name = "dev-rg"
location            = "canadacentral"  # Lower-cost region for dev
environment         = "dev"

# =================
# NETWORK CONFIGURATION
# =================
vnet_name          = "vnet-dev"
vnet_address_space = ["10.0.0.0/16"]  # Standard dev IP range

subnets = [
  {
    name           = "dev-frontend"
    address_prefix = "10.0.1.0/24"
    nsg_rules = [
      {
        name                       = "AllowRDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "192.168.1.0/24"  # Office IP range
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name           = "dev-backend"
    address_prefix = "10.0.2.0/24"
    service_endpoints = ["Microsoft.Storage"]  # For dev storage accounts
  }
]

# =================
# COST OPTIMIZATIONS
# =================
vm_size          = "Standard_B2s"  # Burstable instance for dev
storage_account = {
  tier              = "Standard"
  replication_type  = "LRS"        # Locally redundant storage
  enable_https_traffic_only = true
}

# =============
# TAGGING SCHEMA
# =============
tags = {
  Environment  = "Development"
  Owner        = "DevOps"
  CostCenter   = "DEV-100"
  AutoShutdown = "true"       # For cost savings
  Terraform    = "true"
  LastUpdated  = formatdate("DD-MM-YYYY hh:mm ZZZ", timestamp())
}
