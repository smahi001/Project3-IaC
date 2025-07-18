environment = "dev"
prefix = "dev"

resource_group_name = "myapp-dev-rg"
location = "southindia"

virtual_network_name = "vnet-dev"
address_space = ["10.0.0.0/16"]
subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24"]

vm_size = "Standard_B1s"
admin_username = "devadmin"

db_sku_name = "GP_Gen5_2"
db_storage_mb = 5120

enable_monitoring = false

tags = {
  Environment = "Development"
  Owner = "DevOps"
}
