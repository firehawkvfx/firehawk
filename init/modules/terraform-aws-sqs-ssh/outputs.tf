output "cloud_in_cert_url" {
  value = aws_sqs_queue.cloud_in_cert.url
}
output "cloud_in_cert_arn" {
  value = aws_sqs_queue.cloud_in_cert.arn
}
output "remote_in_cert_url" {
  value = aws_sqs_queue.remote_in_cert.url
}
output "remote_in_cert_arn" {
  value = aws_sqs_queue.remote_in_cert.arn
}