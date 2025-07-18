# production.tfvars - Production environment configuration

# Resource naming prefix
prefix = "prod"

# Azure Resource Group
resource_group_name = "myapp-production-rg"
location           = "southindia"

# Network Configuration (more robust in prod)
virtual_network_name = "vnet-production"
address_space       = ["10.0.0.0/16"]
subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

# Virtual Machine Configuration (larger instances)
vm_size          = "Standard_D2s_v3"
admin_username   = "prodadmin"
instance_count   = 4

# Database Configuration (higher tier)
db_sku_name     = "GP_Gen5_4"
db_storage_mb   = 10240

# Monitoring (enabled in prod)
enable_monitoring = true

# Tags
tags = {
  Environment = "Production"
  Owner       = "DevOps"
  CostCenter  = "PROD456"
  Criticality = "High"
}
