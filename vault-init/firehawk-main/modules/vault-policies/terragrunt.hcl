include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../vault"
    ]
}

skip = local.skip

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-policies?ref=add-workstation-profile"

  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "scripts/create-token"]
  }
}