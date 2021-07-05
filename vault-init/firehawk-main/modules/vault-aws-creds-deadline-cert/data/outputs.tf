output "cloud_in_cert_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.cloud_in_cert_arn
}
output "remote_in_cert_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.remote_in_cert_arn
}
output "remote_in_deadline_cert_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_deadline_cert.outputs.remote_in_deadline_cert_arn
}
output "vault_aws_secret_backend_path" {
  value = try(data.terraform_remote_state.terraform_aws_secret_backend.outputs.vault_aws_secret_backend_path, null)
}
