environment          = "staging"
resource_group_name  = "myapp-staging-rg"
location             = "southindia"

vnet_name            = "vnet-staging"
vnet_address_space   = ["10.1.0.0/16"]

subnets = [
  {
    name           = "subnet-1"
    address_prefix = "10.1.1.0/24"
  }
]

tags = {
  Environment = "Staging"
  Owner       = "DevOps"
}
