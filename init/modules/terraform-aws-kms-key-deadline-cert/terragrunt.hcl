include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  resourcetier = local.common_vars.inputs.common_tags["resourcetier"]
}

inputs = merge(
  local.common_vars.inputs,
  {
    name_prefix = "deadline-cert",
    description = "The KMS key use to aquire the deadline certificate."
    kms_key_alias_name = "alias/firehawk/resourcetier/${local.resourcetier}/deadline_cert_kms_key"
    secrets_manager_parameter = "/firehawk/resourcetier/${local.resourcetier}/file_deadline_cert"
  }
)
prevent_destroy = true