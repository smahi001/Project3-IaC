environment = "production" 
vnet_address_space = ["10.2.0.0/16"]
location             = "southindia"

vnet_name            = "vnet-prod"
vnet_address_space   = ["10.2.0.0/16"]

subnets = [
  {
    name           = "subnet-1"
    address_prefix = "10.2.1.0/24"
  },
  {
    name           = "subnet-2"
    address_prefix = "10.2.2.0/24"
  },
  {
    name           = "subnet-3"
    address_prefix = "10.2.3.0/24"
  }
]

tags = {
  Environment = "Production"
  Owner       = "DevOps"
  Critical    = "true"
}
