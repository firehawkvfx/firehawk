include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  skip = ( lower(get_env("TF_VAR_init", "false"))=="true" ? "false" : "true" )
  ca_public_key_file_path = get_env("TF_VAR_ca_public_key_file_path", "/home/ec2-user/.ssh/tls/ca.crt.pem")
}

skip = local.skip
inputs = local.common_vars.inputs

terraform { # After SSL certs have been generated, isntall them to the current instance. 
  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "install-consul-vault-client", 
      "--vault-module-version", "v0.13.11",  
      "--vault-version", "1.5.5", 
      "--consul-module-version", "v0.8.0", 
      "--consul-version", "1.8.4", 
      "--build", "amazonlinux2", 
      "--cert-file-path", local.ca_public_key_file_path
      ]
  }
}