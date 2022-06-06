# The user data for initialising render nodes.  This may be used in spot fleets or on demand instance types. base 64 encoding is preffered for output.

locals {
  resourcetier           = var.common_tags["resourcetier"]
  client_cert_file_path  = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
  client_cert_vault_path = "${local.resourcetier}/deadline/client_cert_files${local.client_cert_file_path}"
}

data "aws_ssm_parameter" "onsite_storage" {
  name = "/firehawk/resourcetier/${local.resourcetier}/onsite_storage"
}
data "aws_ssm_parameter" "onsite_nfs_export" {
  name = "/firehawk/resourcetier/${local.resourcetier}/onsite_nfs_export"
}
data "aws_ssm_parameter" "onsite_nfs_mount_target" {
  name = "/firehawk/resourcetier/${local.resourcetier}/onsite_nfs_mount_target"
}

data "aws_ssm_parameter" "cloud_s3_gateway" {
  name = "/firehawk/resourcetier/${local.resourcetier}/cloud_s3_gateway"
}
data "aws_ssm_parameter" "cloud_s3_gateway_mount_target" {
  name = "/firehawk/resourcetier/${local.resourcetier}/cloud_s3_gateway_mount_target"
}

data "aws_ssm_parameter" "cloud_fsx_storage" {
  name = "/firehawk/resourcetier/${local.resourcetier}/cloud_fsx_storage"
}
data "aws_ssm_parameter" "cloud_fsx_mount_target" {
  name = "/firehawk/resourcetier/${local.resourcetier}/cloud_fsx_mount_target"
}

data "aws_ssm_parameter" "prod_mount_target" {
  name = "/firehawk/resourcetier/${local.resourcetier}/prod_mount_target"
}
data "aws_ssm_parameter" "houdini_license_server_enabled" {
  name = "/firehawk/resourcetier/${local.resourcetier}/houdini_license_server_enabled"
}
data "aws_ssm_parameter" "houdini_license_server_address" {
  name = "/firehawk/resourcetier/${local.resourcetier}/houdini_license_server_address"
}

data "aws_ssm_parameter" "sesi_client_id" {
  name = "/firehawk/resourcetier/${local.resourcetier}/sesi_client_id"
}

data "template_file" "user_data_auth_client" {
  template = format("%s%s",
    file("${path.module}/user-data-iam-auth-ssh-host-consul.sh"),
    file("${path.module}/user-data-install-deadline-worker-cert.sh")
  )
  vars = {
    onsite_storage          = data.aws_ssm_parameter.onsite_storage.value
    onsite_nfs_export       = data.aws_ssm_parameter.onsite_nfs_export.value       # eg "192.168.92.11:/prod3"
    onsite_nfs_mount_target = data.aws_ssm_parameter.onsite_nfs_mount_target.value # eg "/onsite_prod"
    prod_mount_target       = data.aws_ssm_parameter.prod_mount_target.value       # eg "/prod"

    cloud_s3_gateway = data.aws_ssm_parameter.cloud_s3_gateway.value
    cloud_s3_gateway_dns_name = var.nfs_cloud_file_gateway_private_ip
    cloud_s3_gateway_mount_name = var.nfs_cloud_file_gateway_share_path
    cloud_s3_gateway_mount_target = data.aws_ssm_parameter.cloud_s3_gateway_mount_target.value

    cloud_fsx_storage       = data.aws_ssm_parameter.cloud_fsx_storage.value
    cloud_fsx_mount_target  = data.aws_ssm_parameter.cloud_fsx_mount_target.value # eg "/cloud_prod"
    cloud_fsx_dns_name      = var.fsx_dns_name
    fsx_mount_name          = var.fsx_mount_name

    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    aws_internal_domain      = var.aws_internal_domain
    aws_external_domain      = "" # External domain is not used for internal hosts.
    example_role_name        = "rendernode-vault-role"

    deadlineuser_name                = "deadlineuser"
    deadline_version                 = var.deadline_version
    installers_bucket                = "software.${var.bucket_extension}"
    resourcetier                     = local.resourcetier
    deadline_installer_script_repo   = "https://github.com/firehawkvfx/packer-firehawk-amis.git"
    deadline_installer_script_branch = "deadline-immutable" # TODO This must become immutable - version it

    client_cert_file_path  = local.client_cert_file_path
    client_cert_vault_path = local.client_cert_vault_path

    houdini_license_server_enabled = data.aws_ssm_parameter.houdini_license_server_enabled.value
    houdini_license_server_address = data.aws_ssm_parameter.houdini_license_server_address.value
    houdini_major_version          = "19.0" # TODO: this should be aquired from an AMI tag.  This should also be passed to the ansible template in the image build.
    sesi_client_id = data.aws_ssm_parameter.sesi_client_id.value # the sesi client id is required to use the SESI Cloud license
  }
}
