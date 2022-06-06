output "remote_in_deadline_cert_url" {
  value = try(data.terraform_remote_state.terraform_aws_sqs_deadline_cert.outputs.remote_in_deadline_cert_url, null)
}
output "bastion_public_dns" {
  value = try( "centos@${data.terraform_remote_state.terraform_aws_bastion.outputs.public_dns}" , null)
}
output "vault_client_private_dns" {
  value = try( "centos@${data.terraform_remote_state.terraform_aws_vault_client.outputs.consul_private_dns}" , null)
}
output "deadline_db_instance_id" {
  value = try(data.terraform_remote_state.terraform_aws_deadline_db.outputs.id, null)
}

