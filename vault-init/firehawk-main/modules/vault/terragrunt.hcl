include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../vault"
    ]
}

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault?ref=test-pull-request-236"

  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "scripts/post-tf-run-consul"]
  }
  after_hook "after_hook_2" {
    commands = ["apply"]
    execute  = ["bash", "scripts/post-tf-vault-service-arrival"]
  }
  after_hook "after_hook_3" {
    commands = ["apply"]
    execute  = ["bash", "scripts/initialize-vault"]
  }
}

# skip = true