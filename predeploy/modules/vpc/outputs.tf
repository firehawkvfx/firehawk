output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "consul_client_security_group" {
  value = module.consul_client_security_group.consul_client_sg_id
}

output "vpc_cidr" {
  value = module.deployervpc_all_subnet_cidrs.base_cidr_block
}

output "resourcetier_all_vpc_cidrs" {
  value = module.resourcetier_all_vpc_cidrs.network_cidr_blocks
}

output "deployervpc_all_subnet_cidrs" {
  value = module.deployervpc_all_subnet_cidrs.network_cidr_blocks
}

output "deployervpc_all_private_subnet_cidrs" {
  value = module.deployervpc_all_private_subnet_cidrs.network_cidr_blocks
}

output "deployervpc_all_public_subnet_cidrs" {
  value = module.deployervpc_all_public_subnet_cidrs.network_cidr_blocks
}

output "deployervpc_all_public_subnet_cidr_list" {
  value = module.deployervpc_all_public_subnet_cidrs.networks[*].cidr_block
}

output "deployervpc_all_private_subnet_cidr_list" {
  value = module.deployervpc_all_private_subnet_cidrs.networks[*].cidr_block
}