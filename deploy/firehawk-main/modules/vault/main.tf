data "aws_region" "current" {}
locals {
  common_tags = var.common_tags
}

data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vaultvpc_id  = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
}
### Configure the current cloud9 instance to connect to vault ###
data "aws_vpc" "primary" { # The primary is the Main VPC containing vault
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  default = false
  id = local.vaultvpc_id
}
module "vault" {
  count = length(local.vaultvpc_id) > 0 ? 1 : 0
  source = "./modules/terraform-aws-vault"

  use_default_vpc    = false
  vpc_tags           = local.common_tags #tags used to find the vpc to deploy into.
  subnet_tags        = tomap({"area": "private"})
  enable_auto_unseal = true
  ssh_key_name       = var.aws_key_name
  # Persist vault data in an S3 bucket when all nodes are shut down.
  enable_s3_backend      = true
  use_existing_s3_bucket = true
  s3_bucket_name         = "vault.${var.bucket_extension}"
  ami_id                 = var.vault_consul_ami_id
  consul_cluster_name    = var.consul_cluster_name
  consul_cluster_tag_key = var.consul_cluster_tag_key
  resourcetier           = var.resourcetier
  common_tags            = var.common_tags
}

data "terraform_remote_state" "provisioner_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "predeploy/modules/terraform-aws-sg-provisioner/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
module "security_group_rules" {
  count = length( try(data.terraform_remote_state.provisioner_security_group.outputs.security_group_id, "") ) > 0 ? 1 : 0
  source                               = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.8.0"
  security_group_id                    = data.terraform_remote_state.provisioner_security_group.outputs.security_group_id
  allowed_inbound_security_group_ids   = length(module.vault) > 0 ? [module.vault[0].security_group_id_consul_cluster] : []
  allowed_inbound_security_group_count = 1
  allowed_inbound_cidr_blocks          = length(local.vaultvpc_id) > 0 ? [data.aws_vpc.primary[0].cidr_block] : [] # TODO test if its possible only inbound sg or cidr block is required.
  # TODO define var.allowed_inbound_security_group_ids, allowed_inbound_security_group_count and var.allowed_inbound_cidr_blocks
}

# need to compare this sg group with DCV instance.
# 
