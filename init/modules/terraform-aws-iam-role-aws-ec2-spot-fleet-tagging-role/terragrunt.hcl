include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = local.common_vars.inputs

# terragrunt import aws_iam_role.service_role aws-ec2-spot-fleet-tagging-role

terraform {
  before_hook "before_hook_1" {
    commands = ["apply"]
    execute  = [
      "bash", "auto_import.sh" # attempt to import the resource in case it already exists
      ]
  }

  # "ansible-galaxy collection install community.aws",

  # before_hook "before_hook_2" {
  #   commands = ["apply"]
  #   execute  = ["bash", "ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook ./ensure_role_exists.yaml"]
  # }
}