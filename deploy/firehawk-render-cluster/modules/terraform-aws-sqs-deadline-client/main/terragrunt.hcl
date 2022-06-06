include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    remote_in_deadline_cert_url = null
    bastion_public_dns = ""
    vault_client_private_dns = ""
    deadline_db_instance_id = ""
  }
}

dependencies {
  paths = ["../data"]
}

inputs = merge(
  local.common_vars.inputs,
  {
    "instance_id" : dependency.data.outputs.deadline_db_instance_id
    "sqs_remote_in_deadline_cert_url" : dependency.data.outputs.remote_in_deadline_cert_url
    "host1" : "${dependency.data.outputs.bastion_public_dns}"
    "host2" : "${dependency.data.outputs.vault_client_private_dns}"
  }
)