output "consul_client_sg_id" {
  depends_on = [aws_security_group_rule.allow_outbound, module.security_group_rules]
  value      = local.security_group_id
}