# staging.tfvars - Staging environment configuration

# Resource naming prefix
prefix = "stg"

# Azure Resource Group
resource_group_name = "myapp-staging-rg"
location           = "southindia"

# Network Configuration
virtual_network_name = "vnet-staging"
address_space       = ["10.1.0.0/16"]
subnet_prefixes     = ["10.1.1.0/24", "10.1.2.0/24"]

# Virtual Machine Configuration
vm_size          = "Standard_B2s"
admin_username   = "stagingadmin"
instance_count   = 2

# Database Configuration
db_sku_name     = "GP_Gen5_2"
db_storage_mb   = 5120

# Tags
tags = {
  Environment = "Staging"
  Owner       = "DevOps"
  CostCenter  = "STG123"
}
