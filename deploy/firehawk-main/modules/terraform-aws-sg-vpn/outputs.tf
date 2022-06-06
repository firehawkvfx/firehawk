output "security_group_id" {
  value = length(aws_security_group.openvpn) > 0 ? aws_security_group.openvpn[0].id : ""
}
