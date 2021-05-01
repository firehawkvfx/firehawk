include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

terraform {
  # source = "github.com/firehawkvfx/firehawk-main.git//modules/vault?ref=v0.0.9"

  before_hook "before_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "ansible-galaxy collection install community.aws"]
  }
  before_hook "before_hook_2" {
    commands = ["apply"]
    execute  = ["bash", "ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook ./ensure_role_exists.yaml"]
  }
  # after_hook "after_hook_3" {
  #   commands = ["apply"]
  #   execute  = ["bash", "scripts/initialize-vault"]
  }
}