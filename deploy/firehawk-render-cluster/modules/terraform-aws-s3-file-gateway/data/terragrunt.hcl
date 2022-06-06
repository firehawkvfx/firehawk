include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

inputs = merge(
  local.common_vars.inputs,
  {
    s3_bucket_name = get_env("TF_VAR_rendering_bucket", "")
  }
)

dependencies {
  paths = [
    "../../terraform-aws-render-vpc-routes",
    "../../terraform-aws-s3-file-gateway-sg"
    ]
}

# skip = true