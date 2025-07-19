environment = "dev"
vnet_address_space = ["10.0.0.0/16"]
location             = "southindia"

vnet_name            = "vnet-dev"
vnet_address_space   = ["10.0.0.0/16"]

subnets = [
  {
    name           = "subnet-1"
    address_prefix = "10.0.1.0/24"
  },
  {
    name           = "subnet-2"
    address_prefix = "10.0.2.0/24"
  }
]

tags = {
  Environment = "Development"
  Owner       = "DevOps"
}
