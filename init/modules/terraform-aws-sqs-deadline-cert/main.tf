# Creates SQS queue used for a deadline_cert service to poll and establish a connection.

resource "aws_sqs_queue" "remote_in_deadline_cert" { # the queue that your remote deadline_cert host will poll for certificates
  kms_master_key_id                 = "alias/aws/sqs"
  name_prefix                       = "remote_in_deadline_cert_${lookup(var.common_tags, "resourcetier", "0")}${lookup(var.common_tags, "pipelineid", "0")}_"
  kms_data_key_reuse_period_seconds = 300
  fifo_queue                        = true
  content_based_deduplication       = true
  visibility_timeout_seconds        = 0
  message_retention_seconds         = 900 # 15 mins
  tags                              = merge(tomap({ "Name" : "remote_in_vpn" }), var.common_tags)
}

resource "aws_ssm_parameter" "remote_in_deadline_cert_url" {
  name      = "/firehawk/resourcetier/${var.resourcetier}/sqs_remote_in_deadline_cert_url"
  type      = "SecureString"
  overwrite = true
  value     = aws_sqs_queue.remote_in_deadline_cert.url
  tags      = merge(tomap({ "Name" : "remote_in_deadline_cert" }), var.common_tags)
}