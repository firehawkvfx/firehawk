output "instance_name" {
  value = local.instance_name
}
output "private_route_table_ids" {
  value = local.private_route_table_ids
}
output "public_route_table_ids" {
  value = local.public_route_table_ids
}
output "private_ip" {
  value = module.vpn.private_ip
}
output "public_ip" {
  value = module.vpn.public_ip
}