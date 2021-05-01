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
      "bash", 
      # "ansible-galaxy collection install community.aws",
      # attempt
      "terragrunt state list | grep -m 1 'aws_iam_role.service_role' || terragrunt import aws_iam_role.service_role aws-ec2-spot-fleet-tagging-role || echo 'The iam role will be created by terraform'"
      ]
  }
  # before_hook "before_hook_2" {
  #   commands = ["apply"]
  #   execute  = ["bash", "ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook ./ensure_role_exists.yaml"]
  # }
}