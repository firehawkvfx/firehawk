# Common tags are provided as an environment variable and depend on 'source update_var.sh' being run in cloud9.
locals {
  common_tags = var.common_tags
}
module "vpc" {
  # source                       = "./modules/terraform-aws-vpc"
  source                       = "../../../firehawk-main/modules/vpc/modules/terraform-aws-vpc"
  enable_nat_gateway           = true
  vpc_name                     = local.common_tags["vpcname"]
  vpc_cidr                     = module.rendervpc_all_subnet_cidrs.base_cidr_block
  public_subnets               = module.rendervpc_all_public_subnet_cidrs.networks[*].cidr_block
  private_subnets              = module.rendervpc_all_private_subnet_cidrs.networks[*].cidr_block
  sleep                        = var.sleep
  # remote_cloud_public_ip_cidr  = var.remote_cloud_public_ip_cidr
  # remote_cloud_private_ip_cidr = var.remote_cloud_private_ip_cidr
  common_tags                  = local.common_tags
}

module "consul_client_security_group" {
  source      = "github.com/firehawkvfx/consul-client-security-group.git?ref=v0.0.3"
  common_tags = local.common_tags
  create_vpc  = true
  vpc_id      = module.vpc.vpc_id

  allowed_inbound_cidr_blocks = [module.resourcetier_all_vpc_cidrs.base_cidr_block, var.remote_cloud_private_ip_cidr, var.remote_cloud_public_ip_cidr]

}
module "resourcetier_all_vpc_cidrs" { # all vpcs contained in the combined_vpcs_cidr (current resource tier dev or green or blue or main)
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.combined_vpcs_cidr
  networks = [
    {
      name     = "deployervpc"
      new_bits = 9
    },
    {
      name     = "vaultvpc"
      new_bits = 9
    },
    {
      name     = "rendervpc"
      new_bits = 1
    }
  ]
}
module "rendervpc_all_subnet_cidrs" { # all private/public subnet ranges 
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.resourcetier_all_vpc_cidrs.network_cidr_blocks["rendervpc"]
  networks = [
    {
      name     = "privatesubnets"
      new_bits = 1
    },
    {
      name     = "publicsubnets"
      new_bits = 1
    }
  ]
}
module "rendervpc_all_private_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.rendervpc_all_subnet_cidrs.network_cidr_blocks["privatesubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("privatesubnet%s", i), new_bits = 2 }
  ]
}
module "rendervpc_all_public_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.rendervpc_all_subnet_cidrs.network_cidr_blocks["publicsubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("publicsubnet%s", i), new_bits = 2 }
  ]
}
