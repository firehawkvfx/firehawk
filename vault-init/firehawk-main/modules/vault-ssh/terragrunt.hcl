include {
  path = find_in_parent_folders()
}

locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  configure_vault = lower(get_env("TF_VAR_configure_vault", "false"))=="true" ? true : false
  skip = ( local.configure_vault ? false : true )
}

inputs = merge(
  local.common_vars.inputs,
  {
    "configure_vault" : local.configure_vault 
  }
)

dependencies {
  paths = [
    "../vault-policies"
    ]
}

skip = local.skip

terraform {
  source = "github.com/firehawkvfx/firehawk-main.git//modules/vault-ssh?ref=bug-consul-init"
  # Configure this host for SSH Certificates
  after_hook "after_hook_1" {
    commands = ["apply"]
    execute  = ["bash", "modules/known-hosts/known_hosts.sh"]
  }
  after_hook "after_hook_2" { # Sign the cloud 9 user ssh key
    commands = ["apply"]
    execute  = ["bash", "modules/sign-ssh-key/sign_ssh_key.sh"]
  }
  after_hook "after_hook_3" { # Retrieve remote user ssh key
    commands = ["apply"]
    execute  = ["bash", "modules/ssm-values/ssm_retrieve_public_key.sh"]
  }
  after_hook "after_hook_4" { # Sign the remote user ssh key
    commands = ["apply"]
    execute  = ["bash", "modules/sign-ssh-key/sign_ssh_key.sh", "--public-key",  "/home/ec2-user/.ssh/remote_host/id_rsa.pub"]
  }
  after_hook "after_hook_5" { # post ssh cert as parameter
    commands = ["apply"]
    execute  = ["bash", "modules/ssm-values/ssm_post_public_cert.sh"]
  }
}