output "cloud_in_cert" {
  value = aws_sqs_queue.cloud_in_cert.url
}
output "remote_in_cert" {
  value = aws_sqs_queue.remote_in_cert.url
}
output "remote_in_vpn" {
  value = aws_sqs_queue.remote_in_vpn.url
}