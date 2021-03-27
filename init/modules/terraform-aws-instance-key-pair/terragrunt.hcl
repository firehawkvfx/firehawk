include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

terraform {
  before_hook "before_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "ensure_ssh_key_exists"]
  }
}