output "s3_bucket_arn" {
  value       = aws_s3_bucket.license_forwarder_cert_bucket.arn
  description = "The ARN of the license forwarder certs bucket"
}

output "s3_bucket_name" {
  depends_on = [aws_s3_bucket.license_forwarder_cert_bucket]
  value       = local.bucket_name
  # value = aws_s3_bucket.license_forwarder_cert_bucket.bucket_domain_name
  description = "The name of the license forwarder certs bucket"
}