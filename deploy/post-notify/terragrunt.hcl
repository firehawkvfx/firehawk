include {
  path = find_in_parent_folders()
}

# locals {
#   common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
# }

# inputs = local.common_vars.inputs

dependencies {
  paths = [
    "../firehawk-main/modules/terraform-aws-vault-client",
    "../firehawk-main/modules/terraform-aws-bastion",
    "../firehawk-render-cluster/modules/terraform-aws-node-houdini/module",
    "../firehawk-render-cluster/modules/terraform-aws-deadline-spot",
    "../firehawk-render-cluster/modules/terraform-aws-vault-client"
    ]
}

terraform {
  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "instructions"]
  }
}