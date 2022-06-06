output "security_group_id" {
  value = length(aws_security_group.bastion) > 0 ? aws_security_group.bastion[0].id : null
}