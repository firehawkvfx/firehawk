# Creates SQS queue used for a vpn service to poll and establish a connection.

resource "aws_sqs_queue" "remote_in_vpn" { # the queue that your remote vpn host will poll for certificates
  kms_master_key_id                 = "alias/aws/sqs"
  name_prefix                       = "remote_in_vpn_${lookup(var.common_tags, "resourcetier", "0")}${lookup(var.common_tags, "pipelineid", "0")}_"
  kms_data_key_reuse_period_seconds = 300
  fifo_queue                        = true
  content_based_deduplication       = true
  visibility_timeout_seconds        = 30
  message_retention_seconds         = 300 # vpn creds will be erased within 5 mins if not consumed
  tags                              = merge(tomap({ "Name" : "remote_in_vpn" }), var.common_tags)
}

resource "aws_ssm_parameter" "remote_in_vpn_url" {
  name      = "/firehawk/resourcetier/${var.resourcetier}/sqs_remote_in_vpn_url"
  type      = "SecureString"
  overwrite = true
  value     = aws_sqs_queue.remote_in_vpn.url
  tags      = merge(tomap({ "Name" : "remote_in_vpn" }), var.common_tags)
}