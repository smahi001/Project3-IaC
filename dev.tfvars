environment          = "dev"
resource_group_name  = "project3-rg"  # Using your existing RG
location             = "southindia"

# Networking
vnet_name            = "vnet-dev"
vnet_address_space   = ["10.0.0.0/16"]
subnets = [
  {
    name           = "subnet-0"
    address_prefix = "10.0.1.0/24"
  },
  {
    name           = "subnet-1"
    address_prefix = "10.0.2.0/24"
  }
]

# Tags
tags = {
  Environment = "Development"
  Owner       = "DevOps"
}
