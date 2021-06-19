output "cloud_in_cert_arn" {
  value = try(data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.cloud_in_cert_arn, null)
}
output "remote_in_cert_arn" {
  value = try(data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.remote_in_cert_arn, null)
}
output "remote_in_vpn_arn" {
  value = try(data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.remote_in_vpn_arn, null)
}
output "vault_aws_secret_backend_path" {
  value = try(data.terraform_remote_state.terraform_aws_secret_backend.outputs.vault_aws_secret_backend_path, null)
}
