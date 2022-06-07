include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    vpc_cidr = "fake-cidr1"
    public_subnet_ids = "fake-subnet-id"
  }
}

dependencies {
  paths = [
    "../data"
  ]
}

inputs = merge(
  local.common_vars.inputs,
  {
    "vpc_cidr" : dependency.data.outputs.vpc_cidr,
    "public_subnet_ids" : dependency.data.outputs.public_subnet_ids
  }
)

# terraform {
#   source = "../../../firehawk-main/modules/modules/vault"

#   after_hook "after_hook_1" {
#     commands = ["apply"]
#     execute  = ["bash", "scripts/post-tf-start"]
#   }
# }