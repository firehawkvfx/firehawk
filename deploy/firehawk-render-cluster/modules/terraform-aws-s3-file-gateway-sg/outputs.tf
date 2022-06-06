output "storage_gateway_sg_id" {
    value = aws_security_group.storage_gateway.id
}

output "deployment_storage_gateway_access_sg_id" {
    value = aws_security_group.deployment_storage_gateway_access.id
}