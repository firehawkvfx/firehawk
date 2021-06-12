output "cloud_in_cert" {
  value = data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.cloud_in_cert
}
output "remote_in_cert" {
  value = data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.remote_in_cert
}
output "remote_in_vpn" {
  value = data.terraform_remote_state.terraform_aws_sqs_vpn.outputs.remote_in_vpn
}