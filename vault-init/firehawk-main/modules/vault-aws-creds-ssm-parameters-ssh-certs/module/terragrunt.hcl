include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    cloud_in_cert = "fake_url"
    remote_in_cert = "fake_url"
    remote_in_vpn = "fake_url"
  }
}

dependencies {
  paths = ["../data"]
}

skip = local.skip

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-aws-creds-ssm-parameters-ssh-certs?ref=v0.0.20"
}

inputs = merge(
  local.common_vars.inputs,
  {
    "configure_vault" : local.configure_vault 
    "sqs_send_arns" : [ dependency.data.outputs.cloud_in_cert ]
    "sqs_recieve_arns" : [ dependency.data.outputs.remote_in_cert, dependency.data.outputs.remote_in_vpn ]
  }
)