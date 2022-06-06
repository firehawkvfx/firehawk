output "remote_in_vpn_url" {
  value = try(data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.remote_in_vpn_url, null)
}
output "bastion_public_dns" {
  value = try( "centos@${data.terraform_remote_state.terraform_aws_bastion.outputs.public_dns}" , null)
}
output "vault_client_private_dns" {
  value = try( "centos@${data.terraform_remote_state.terraform_aws_vault_client.outputs.consul_private_dns}" , null)
}