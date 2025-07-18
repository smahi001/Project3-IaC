environment = "production"
prefix = "prod"

resource_group_name = "myapp-production-rg"
location = "southindia"

virtual_network_name = "vnet-production"
address_space = ["10.0.0.0/16"]
subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

vm_size = "Standard_D2s_v3"
admin_username = "prodadmin"
instance_count = 4

db_sku_name = "GP_Gen5_4"
db_storage_mb = 10240

enable_monitoring = true

tags = {
  Environment = "Production"
  Owner = "DevOps"
  CostCenter = "PROD456"
  Criticality = "High"
}
