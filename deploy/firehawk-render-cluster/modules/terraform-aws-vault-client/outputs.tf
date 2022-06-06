output "private_ip" {
  value = module.vault_client.private_ip
}

output "id" {
  value = module.vault_client.id
}

output "consul_private_dns" {
  value = module.vault_client.consul_private_dns
}
