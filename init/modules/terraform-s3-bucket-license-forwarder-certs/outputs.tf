output "s3_bucket_arn" {
  value       = aws_s3_bucket.license_forwarder_cert_bucket.arn
  description = "The ARN of the license forwarder certs bucket"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.license_forwarder_cert_bucket.name
  description = "The name of the license forwarder certs bucket"
}