include {
  path = find_in_parent_folders()
}

terraform {
  source = "../../../../firehawk-main/modules/terraform-aws-vpn"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  region = local.common_vars.inputs.common_tags["region"]
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    vpc_id = ""
    remote_in_vpn_url = null
    bastion_public_dns = "fakepublicdns"
    vault_client_private_dns = "fakeprivatedns"
    vpn_security_group = null
  }
}

dependencies {
  paths = ["../data"]
}

# TODO remove hardcoded region
inputs = merge(
  local.common_vars.inputs,
  {
    "vpc_id" : dependency.data.outputs.vpc_id,
    "region" : local.region
  }
)