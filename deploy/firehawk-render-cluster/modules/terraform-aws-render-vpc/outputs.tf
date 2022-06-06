output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "consul_client_security_group" {
  value = module.consul_client_security_group.consul_client_sg_id
}

output "resourcetier_all_vpc_cidrs" {
  value = module.resourcetier_all_vpc_cidrs.network_cidr_blocks
}

output "rendervpc_all_subnet_cidrs" {
  value = module.rendervpc_all_subnet_cidrs.network_cidr_blocks
}

output "rendervpc_all_private_subnet_cidrs" {
  value = module.rendervpc_all_private_subnet_cidrs.network_cidr_blocks
}

output "rendervpc_all_public_subnet_cidrs" {
  value = module.rendervpc_all_public_subnet_cidrs.network_cidr_blocks
}

output "rendervpc_all_public_subnet_cidr_list" {
  value = module.rendervpc_all_public_subnet_cidrs.networks[*].cidr_block
}

output "rendervpc_all_private_subnet_cidr_list" {
  value = module.rendervpc_all_private_subnet_cidrs.networks[*].cidr_block
}

output "common_tags" {
  value = var.common_tags
}