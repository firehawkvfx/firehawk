include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  ca_public_key_file_path = var.ca_public_key_file_path
  public_key_file_path = var.public_key_file_path
  private_key_file_path = var.private_key_file_path
}

# inputs = local.common_vars.inputs
inputs = merge(
  local.common_vars.inputs,
  {
    ca_public_key_file_path = local.ca_public_key_file_path
    public_key_file_path    = local.public_key_file_path
    private_key_file_path   = local.private_key_file_path
  }
)

terraform { # After SSL certs have been generated, isntall them to the current instance. 
  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "install-consul-vault-client", 
      "--vault-module-version", "v0.15.1",  
      "--vault-version", "1.6.1", 
      "--consul-module-version", "v0.8.0", 
      "--consul-version", "1.9.2", 
      "--build", "amazonlinux2", 
      "--cert-file-path", local.ca_public_key_file_path
      ]
  }
  after_hook "after_hook_2" {
    commands = ["apply"]
    execute  = ["bash", "instructions"]
  }
}