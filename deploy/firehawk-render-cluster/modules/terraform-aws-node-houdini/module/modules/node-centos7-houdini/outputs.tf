output "private_ip" {
  value = length(aws_instance.node_centos7_houdini) > 0 ? aws_instance.node_centos7_houdini[0].private_ip : null
}

output "id" {
  value = length(aws_instance.node_centos7_houdini) > 0 ? aws_instance.node_centos7_houdini[0].id : null
}

output "consul_private_dns" {
  # value = "${local.id}.node.consul"
  value = length(aws_instance.node_centos7_houdini) > 0 ? "${aws_instance.node_centos7_houdini[0].id}.node.consul" : null
}