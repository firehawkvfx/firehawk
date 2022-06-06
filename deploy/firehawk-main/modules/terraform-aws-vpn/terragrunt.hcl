include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../vault",
    # "../vault-configuration",
    "../terraform-aws-sg-vpn"
    ]
}

skip=true # Currently thre vpn for the main vpc is disabled in favour of deploying the vpn in the render vpc subnet.