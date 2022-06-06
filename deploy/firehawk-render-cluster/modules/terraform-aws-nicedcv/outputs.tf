output "instance_name" {
  value = local.instance_name
}
output "private_ip" {
  value = module.workstation_amazonlinux2_nicedcv.private_ip
}
output "id" {
  value = module.workstation_amazonlinux2_nicedcv.id
}
output "consul_private_dns" {
  value = module.workstation_amazonlinux2_nicedcv.consul_private_dns
}