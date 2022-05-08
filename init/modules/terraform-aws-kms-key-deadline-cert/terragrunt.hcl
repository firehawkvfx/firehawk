include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  resourcetier = lookup(local.common_vars.inputs.common_tags["resourcetier"])
}

inputs = merge(
  local.common_vars.inputs,
  {
    name_prefix = "deadline-cert",
    description = "The KMS key use to aquire the deadline certificate."
    ssm_parameter_name_kms_key_id = "/firehawk/resourcetier/${local.resourcetier}/deadline_cert_kms_key_id"
    secrets_manager_parameter = "/firehawk/resourcetier/${local.resourcetier}/file_deadline_cert_content"
  }
)
prevent_destroy = true