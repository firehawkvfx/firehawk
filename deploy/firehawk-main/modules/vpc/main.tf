locals {
  common_tags = var.common_tags
}
module "vpc" {
  source             = "./modules/terraform-aws-vpc"
  vpc_name           = local.common_tags["vpcname"]
  enable_nat_gateway = var.enable_nat_gateway
  vpc_cidr           = module.vaultvpc_all_subnet_cidrs.base_cidr_block
  public_subnets     = module.vaultvpc_all_public_subnet_cidrs.networks[*].cidr_block
  private_subnets    = module.vaultvpc_all_private_subnet_cidrs.networks[*].cidr_block
  sleep              = var.sleep
  common_tags        = local.common_tags
}

module "consul_client_security_group" {
  source      = "./modules/consul-client-security-group"
  common_tags = local.common_tags
  create_vpc  = true
  vpc_id      = module.vpc.vpc_id
}

# Terraform will automatically configure multiple VPCs and subnets within this CIDR range for any resourcetier ( dev / green / blue / main ).
data "aws_ssm_parameter" "combined_vpcs_cidr" {
  name = "/firehawk/resourcetier/${var.resourcetier}/combined_vpcs_cidr"
}

module "resourcetier_all_vpc_cidrs" { # all vpcs contained in the combined_vpcs_cidr (current resource tier dev or green or blue or main)
  source = "hashicorp/subnets/cidr"

  base_cidr_block = data.aws_ssm_parameter.combined_vpcs_cidr.value
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

module "vaultvpc_all_subnet_cidrs" { # all private/public subnet ranges 
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.resourcetier_all_vpc_cidrs.network_cidr_blocks["vaultvpc"]
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

module "vaultvpc_all_private_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["privatesubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("privatesubnet%s", i), new_bits = 2 }
  ]
}

module "vaultvpc_all_public_subnet_cidrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = module.vaultvpc_all_subnet_cidrs.network_cidr_blocks["publicsubnets"]
  networks = [
    for i in range(var.vault_vpc_subnet_count) : { name = format("publicsubnet%s", i), new_bits = 2 }
  ]
}
