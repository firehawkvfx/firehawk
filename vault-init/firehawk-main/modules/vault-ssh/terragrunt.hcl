include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

inputs = merge(
  local.common_vars.inputs,
  {
    "configure_vault" : local.configure_vault 
  }
)

dependencies {
  paths = [
    "../vault-policies",
    "../vault-aws-creds-vpn-cert/module"
    ]
}

skip = local.skip

terraform {
  source = "../../../../deploy/firehawk-main/modules/vault-ssh"
  # Configure this host for SSH Certificates
  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "modules/firehawk-auth-scripts/known-hosts"]
  }
  after_hook "after_hook_2" { # Sign the cloud 9 user ssh key
    commands = ["apply"]
    execute  = ["bash", "modules/firehawk-auth-scripts/sign-ssh-key"]
  }
}