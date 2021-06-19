output "cloud_in_cert_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.cloud_in_cert_arn
}
output "remote_in_cert_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_ssh.outputs.remote_in_cert_arn
}
output "remote_in_vpn_arn" {
  value = data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.remote_in_vpn_arn
}