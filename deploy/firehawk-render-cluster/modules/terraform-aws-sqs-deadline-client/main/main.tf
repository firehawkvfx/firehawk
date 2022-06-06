data "aws_instance" "verify" {
  count = length( var.instance_id ) > 0 ? 1 : 0
  instance_id = var.instance_id
}

resource "null_resource" "sqs_notify" {
  count = length( data.aws_instance.verify ) > 0 ? 1 : 0 # if a valid instance was found, update the sqs data.

  triggers = {
    instance_dependency = length( data.aws_instance.verify ) > 0 ? data.aws_instance.verify[0].id : null
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      ${path.module}/../../../../firehawk-main/modules/vault-ssh/modules/firehawk-auth-scripts/sqs-send-deadline-payload --resourcetier "${var.resourcetier}"
EOT
  }
}
