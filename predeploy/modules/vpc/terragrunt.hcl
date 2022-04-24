include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}
dependencies {
  paths = [
    "../private-tls-cert" # no costs should be incurred if there is an invalid certificate
    ]
}

inputs = merge(
  local.common_vars.inputs,
  {
    "enable_nat_gateway" : true 
  }
)