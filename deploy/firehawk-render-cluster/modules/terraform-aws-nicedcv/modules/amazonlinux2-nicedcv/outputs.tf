output "private_ip" {
  value = local.private_ip
}

output "id" {
  value = local.id
}

output "consul_private_dns" {
  value = "${local.id}.node.consul"
}