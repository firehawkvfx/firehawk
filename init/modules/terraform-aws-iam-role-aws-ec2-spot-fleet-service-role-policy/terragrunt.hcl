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
    execute  = [
      "bash", "auto_import.sh" # Attempt to import the resource in case it already exists, since we cannot know if the user's account has already created this role for Deadline
      ]
  }
}