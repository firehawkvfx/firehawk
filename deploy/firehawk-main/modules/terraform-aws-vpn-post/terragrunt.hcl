include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../terraform-aws-vpn",
    "../terraform-aws-bastion",
    "../terraform-aws-vault-client"
    ]
}

skip = true
