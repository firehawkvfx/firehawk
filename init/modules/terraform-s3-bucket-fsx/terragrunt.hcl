include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependencies {
  paths = [
    "../terraform-s3-bucket-logs",
    ]
}

inputs = local.common_vars.inputs
prevent_destroy = true