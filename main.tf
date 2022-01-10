terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "random" {

}

resource "random_password" "password" {
  # for_each = local.services
  keepers = {
    id = 2
  }

  length           = 16
  special          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "_%$!=" # : / ? # [ ] @ should be percent encoded, avoid them
}


locals {
  services = jsondecode(file("${path.module}/service_configuration.old.json"))
}

locals {
  configs = [
    for service in local.services.service_configuration: [
      for collection in service.mongoCollection: [
          service.serviceName, 
          service.mongoCluster, 
          service.mongoDatabase, 
          service.mongoCollection[0]
     ]
    ]
  ]
}

resource "local_file" "foo" {
  for_each = local.configs
  content  = join(', ', [
     for service in local.services.service_configuration: [
       for collection in service.mongoCollection: [
        format(
          "mongodb+srv://%s:${random_password.password.result}@%s/%s/%s",
          service.serviceName, 
          service.mongoCluster, 
          service.mongoDatabase, 
          service.mongoCollection[0]
        )
     ]
    ]
  ])

  filename = "${path.module}/foo.bar"
}


output "configs" {
  value = local.config_strings
  # sensitive = true
}

output "password" {
  value     = random_password.password
  sensitive = true
}

# variable "service_configuration" {
#   default = [
#     {
#       serviceName     = "possums-data-store"
#       mongoCluster    = "animals-mongo"
#       mongoDatabase   = "marsupials-dev"
#       mongoCollection = ["possums"]
#     },
#     {
#       serviceName     = "numbats-data-store"
#       mongoCluster    = "animals-mongo"
#       mongoDatabase   = "marsupials-dev"
#       mongoCollection = ["numbats"]
#     },
#     {
#       serviceName     = "marsupial-data-store"
#       mongoCluster    = "animals-mongo"
#       mongoDatabase   = "marsupials-prod"
#       mongoCollection = ["numbats", "possums"]
#     },
#   ]
# }
