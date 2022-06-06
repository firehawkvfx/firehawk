include {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_env("TF_VAR_firehawk_path", "")}/modules/terraform-aws-vpn"
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
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

inputs = merge(
  local.common_vars.inputs,
  {
    "vpc_id" : dependency.data.outputs.vpc_id
    "security_group_ids" : [ dependency.data.outputs.vpn_security_group ]
    "sqs_remote_in_vpn" : dependency.data.outputs.remote_in_vpn_url
    "host1" : "${dependency.data.outputs.bastion_public_dns}"
    "host2" : "${dependency.data.outputs.vault_client_private_dns}"
  }
)