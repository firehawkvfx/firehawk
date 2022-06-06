output "private_ip" {
  value = local.private_ip
}

output "public_ip" {
  value = local.public_ip
}

output "id" {
  value = local.id
}

output "public_dns" {
  value = local.public_dns
}

output "consul_private_dns" {
  value = "${local.id}.node.consul"
}