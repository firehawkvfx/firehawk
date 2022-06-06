include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    user_data_base64 = ""
    rendervpc_id     = ""
    vaultvpc_id      = ""
  }
}

inputs = merge(
  local.common_vars.inputs,
  {
    user_data    = dependency.data.outputs.user_data_base64
    rendervpc_id = dependency.data.outputs.rendervpc_id
    vaultvpc_id  = dependency.data.outputs.vaultvpc_id
  }
)

dependencies {
  paths = [
    "../data"
  ]
}

# skip = true
