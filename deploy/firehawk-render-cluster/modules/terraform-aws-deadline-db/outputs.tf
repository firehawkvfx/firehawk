output "instance_name" {
  value = local.instance_name
}
output "private_ip" {
  value = module.deadline_db_instance.private_ip
}
output "id" {
  value = module.deadline_db_instance.id
}
output "consul_private_dns" {
  value = module.deadline_db_instance.consul_private_dns
}