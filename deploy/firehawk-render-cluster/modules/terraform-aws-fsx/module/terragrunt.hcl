include {
  path = find_in_parent_folders()
}

locals {
  common_vars                  = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  remote_cloud_private_ip_cidr = get_env("TF_VAR_remote_cloud_private_ip_cidr", "")
  onsite_private_subnet_cidr   = get_env("TF_VAR_onsite_private_subnet_cidr", "")
  vpn_cidr                     = get_env("TF_VAR_vpn_cidr", "")
  onsite_public_ip             = get_env("TF_VAR_onsite_public_ip", "")
  remote_cloud_public_ip_cidr  = get_env("TF_VAR_remote_cloud_public_ip_cidr", "")
}

dependency "data" {
  config_path = "../data"
  mock_outputs = {
    rendervpc_cidr = "fake-cidr1"
    private_subnet_cidr_blocks = []
    private_subnet_ids = []
    cloud_fsx_storage = false
    vpc_id = "fakeid"
  }
}

dependencies {
  paths = [
    "../data"
  ]
}

inputs = merge(
  local.common_vars.inputs,
  {
    fsx_storage_enabled = dependency.data.outputs.cloud_fsx_storage
    vpc_id = dependency.data.outputs.vpc_id
    subnet_ids = length( dependency.data.outputs.private_subnet_ids ) > 0 ? [ dependency.data.outputs.private_subnet_ids[0] ] : []
    permitted_cidr_list_private = concat( dependency.data.outputs.private_subnet_cidr_blocks,  [local.remote_cloud_private_ip_cidr, local.onsite_private_subnet_cidr, local.vpn_cidr] )
  }
)

# skip = true
