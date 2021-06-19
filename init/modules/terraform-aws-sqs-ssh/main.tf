# Creates a series of SQS queues used for a vpn service to poll and establish a connection.  The queue url cannot change once the remote service is running, otherwise it will have to change its configured url dynamically as well.

resource "aws_sqs_queue" "cloud_in_cert" { # the queue that cloud 9 will poll for pub keys.
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
  fifo_queue                        = true
  content_based_deduplication       = true
  tags      = merge(tomap({ "Name" : "cloud_in_cert" }), var.common_tags)
}

resource "aws_ssm_parameter" "cloud_in_cert_url" {
  name      = "/firehawk/resourcetier/${var.resourcetier}/sqs_cloud_in_cert_url"
  type      = "SecureString"
  overwrite = true
  value     = aws_sqs_queue.cloud_in_cert.url
  tags      = merge(tomap({ "Name" : "cloud_in_cert_url" }), var.common_tags)
}

resource "aws_sqs_queue" "remote_in_cert" { # the queue that your remote vpn host will poll for certificates
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
  fifo_queue                        = true
  content_based_deduplication       = true
  tags      = merge(tomap({ "Name" : "remote_in_cert" }), var.common_tags)
}

resource "aws_ssm_parameter" "remote_in_cert_url" {
  name      = "/firehawk/resourcetier/${var.resourcetier}/sqs_remote_in_cert_url"
  type      = "SecureString"
  overwrite = true
  value     = aws_sqs_queue.remote_in_cert.url
  tags      = merge(tomap({ "Name" : "remote_in_cert_url" }), var.common_tags)
}