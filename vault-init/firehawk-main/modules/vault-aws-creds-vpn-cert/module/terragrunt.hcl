include {
  path = find_in_parent_folders()
}

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-aws-creds-ssm-parameters-ssh-certs?ref=v0.0.20"
}

skip = local.skip

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    cloud_in_cert_arn = "fake_arn"
    remote_in_cert_arn = "fake_arn"
    remote_in_vpn_arn = "fake_arn"
  }
}

dependencies {
  paths = ["../data"]
}

inputs = merge(
  local.common_vars.inputs,
  {
    "backend_name" : "aws-creds-vpn-cert"
    "configure_vault" : local.configure_vault 
    "sqs_send_arns" : [ dependency.data.outputs.cloud_in_cert_arn ]
    "sqs_recieve_arns" : [ dependency.data.outputs.remote_in_cert_arn, dependency.data.outputs.remote_in_vpn_arn ]
  }
)