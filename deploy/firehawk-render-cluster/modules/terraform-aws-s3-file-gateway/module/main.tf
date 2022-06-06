# This module originated from https://github.com/davebuildscloud/terraform_file_gateway/blob/master/terraform
terraform {
  required_providers {
    aws = "~> 3.8" # specifically because this fix can simplify work arounds - https://github.com/hashicorp/terraform-provider-aws/pull/14314
  }
}
locals {
  name = "s3_gateway_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  extra_tags = {
    role  = "fsx"
    route = "private"
  }
}
locals {
  cloud_s3_gateway_enabled = (!var.sleep && var.cloud_s3_gateway_enabled) ? 1 : 0
}
data "aws_ssm_parameter" "gateway_ami" {
  name = "/aws/service/storagegateway/ami/FILE_S3/latest"
}
locals {
  instance_tags = merge(var.common_tags, {
    Name = var.instance_name
    role = "filegateway"
  })
}
resource "aws_instance" "gateway" { # To troubleshoot, the ssh with username 'admin@ip_address'
  count         = var.cloud_s3_gateway_enabled ? 1 : 0
  ami           = data.aws_ssm_parameter.gateway_ami.value
  instance_type = var.instance_type
  tags          = local.instance_tags

  # Refer to AWS File Gateway documentation for minimum system requirements.
  ebs_optimized = true
  subnet_id     = length(local.subnet_ids) > 0 ? local.subnet_ids[0] : null

  ebs_block_device {
    device_name           = "/dev/xvdf"
    volume_size           = var.ebs_cache_volume_size
    volume_type           = "gp2"
    delete_on_termination = true
  }

  key_name = var.key_name

  vpc_security_group_ids = [
    var.storage_gateway_sg_id
  ]
}

locals {
  subnet_ids = var.use_public_subnet ? var.public_subnet_ids : var.private_subnet_ids
  # instance_id         = length(aws_instance.gateway) > 0 ? aws_instance.gateway[0].id : null
  private_ip          = length(aws_instance.gateway) > 0 ? aws_instance.gateway[0].private_ip : null
  public_ip           = length(aws_instance.gateway) > 0 ? aws_instance.gateway[0].public_ip : null
  file_gateway_id     = length(aws_storagegateway_gateway.storage_gateway_resource) > 0 ? aws_storagegateway_gateway.storage_gateway_resource[0].id : null
  nfs_file_share_path = length(aws_storagegateway_nfs_file_share.same_account) > 0 ? aws_storagegateway_nfs_file_share.same_account[0].path : null
  smb_file_share_path = length(aws_storagegateway_smb_file_share.smb_share) > 0 ? aws_storagegateway_smb_file_share.smb_share[0].path : null
}

resource "aws_ssm_parameter" "nfs_file_share_path" {
  name      = "/firehawk/resourcetier/${var.resourcetier}/cloud_nfs_filegateway_export"
  type      = "String"
  overwrite = true
  value     = "${local.private_ip}:${local.nfs_file_share_path}"
  tags      = merge(tomap({ "Name" : "cloud_nfs_filegateway_export" }), var.common_tags)
}

resource "aws_storagegateway_gateway" "storage_gateway_resource" {
  depends_on = [aws_instance.gateway]

  count              = var.cloud_s3_gateway_enabled ? 1 : 0
  gateway_ip_address = var.use_public_subnet ? local.public_ip : local.private_ip
  gateway_name       = var.gateway_name
  gateway_timezone   = var.gateway_time_zone
  gateway_type       = "FILE_S3"
  smb_guest_password = "MYSMBPASSWORD"
}

data "aws_storagegateway_local_disk" "cache" {
  count       = var.cloud_s3_gateway_enabled ? 1 : 0
  disk_path   = "/dev/xvdf"
  disk_node   = "/dev/xvdf"
  gateway_arn = local.file_gateway_id
}

resource "aws_storagegateway_cache" "storage_gateway_cache_resource" {
  count       = var.cloud_s3_gateway_enabled ? 1 : 0
  disk_id     = length(data.aws_storagegateway_local_disk.cache) > 0 ? data.aws_storagegateway_local_disk.cache[0].id : null
  gateway_arn = local.file_gateway_id
}

# resource "aws_route53_record" "gateway_A_record" {
#   zone_id = data.aws_route53_zone.zone_name.zone_id
#   name    = var.gateway_name
#   type    = "A"
#   ttl     = "3600"
#   records = ["${aws_instance.gateway.private_ip}"]
# }

resource "aws_storagegateway_nfs_file_share" "same_account" {
  count        = ((var.cloud_s3_gateway_export_type == "NFS") && var.cloud_s3_gateway_enabled) ? 1 : 0
  client_list  = var.permitted_cidr_list_private
  gateway_arn  = local.file_gateway_id
  role_arn     = aws_iam_role.role.arn
  location_arn = var.aws_s3_bucket_arn

  squash = "NoSquash" # see https://forums.aws.amazon.com/thread.jspa?messageID=886347&tstart=0 and https://docs.aws.amazon.com/storagegateway/latest/userguide/managing-gateway-file.html#edit-nfs-client

  nfs_file_share_defaults {
    directory_mode = "0777"
    file_mode      = "0666"
    group_id       = var.group_id
    owner_id       = var.owner_id
  }
}

resource "aws_storagegateway_smb_file_share" "smb_share" {
  count          = ((var.cloud_s3_gateway_export_type == "SMB") && var.cloud_s3_gateway_enabled) ? 1 : 0
  authentication = "GuestAccess"
  gateway_arn    = local.file_gateway_id
  location_arn   = var.aws_s3_bucket_arn
  role_arn       = aws_iam_role.role.arn
}
