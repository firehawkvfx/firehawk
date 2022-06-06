output "security_group_id_consul_cluster" {
  value = length(module.vault) > 0 ? module.vault[0].security_group_id_consul_cluster : ""
}
