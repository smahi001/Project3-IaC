# ======================
# PRODUCTION ENVIRONMENT
# ======================
environment = "production"
location    = "southindia"  # Consider Azure Availability Zones for production

# =================
# NETWORK ARCHITECTURE  
# =================
vnet_name          = "vnet-prod"
vnet_address_space = ["10.2.0.0/16"]  # /16 provides 65,536 IPs for scaling

subnets = [
  {
    name              = "web-tier"
    address_prefix    = "10.2.1.0/24"
    service_endpoints = ["Microsoft.Web"]
    nsg_rules = [
      {
        name                       = "AllowHTTP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name              = "app-tier"
    address_prefix    = "10.2.2.0/24"
    service_endpoints = ["Microsoft.Sql"]
    nsg_rules = [
      {
        name                       = "AllowAppToDB"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "1433"
        source_address_prefix      = "10.2.1.0/24"  # Only from web tier
        destination_address_prefix = "*"
      }
    ]
  },
  {
    name              = "db-tier"
    address_prefix    = "10.2.3.0/24"
    service_endpoints = ["Microsoft.Storage"]
    enforce_private_link = true  # Requires private endpoints
  }
]

# ================
# SECURITY CONTROLS
# ================
enable_ddos_protection = true
network_watcher_name   = "nw-prod-southindia"

# =============
# TAGGING SCHEMA
# =============
tags = {
  Environment = "Production"
  Owner       = "DevOps"
  Critical    = "true"
  SLA         = "99.95%"
  DataClass   = "PII"  # For compliance tracking
  CostCenter  = "FIN-001"
  Terraform   = "true"
  LastUpdated = formatdate("DD-MM-YYYY hh:mm ZZZ", timestamp())
}
