output "security_group_id" {
  value = length(aws_security_group.node_centos7_houdini) > 0 ? aws_security_group.node_centos7_houdini[0].id : null
}