output "instance_name" {
  value = local.instance_name
}
output "private_ip" {
  value = module.bastion.private_ip
}
output "public_ip" {
  value = module.bastion.public_ip
}
output "id" {
  value = module.bastion.id
}
output "public_dns" {
  value = module.bastion.public_dns
}
output "consul_private_dns" {
  value = module.bastion.consul_private_dns
}
