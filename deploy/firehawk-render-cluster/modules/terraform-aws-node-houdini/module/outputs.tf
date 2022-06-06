output "instance_name" {
  value = local.instance_name
}
output "private_ip" {
  value = length(module.node_centos7_houdini) > 0 ? coalesce(module.node_centos7_houdini[0].private_ip, "") : ""
}
output "id" {
  value = length(module.node_centos7_houdini) > 0 ? coalesce(module.node_centos7_houdini[0].id, "") : ""
}
output "consul_private_dns" {
  value = length(module.node_centos7_houdini) > 0 ? coalesce(module.node_centos7_houdini[0].consul_private_dns, "") : ""
}
