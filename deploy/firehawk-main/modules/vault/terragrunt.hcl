include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../vpc",
    "../terraform-aws-vpc-main-cloud9-peering"
    ]
}

terraform {
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
    execute  = ["bash", "scripts/post-tf-vault-login"]
  }
}

# skip = true