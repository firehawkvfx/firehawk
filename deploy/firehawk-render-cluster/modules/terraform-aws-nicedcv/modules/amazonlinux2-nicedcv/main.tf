# A vault client host with consul registration and signed host keys from vault.

data "aws_region" "current" {}
resource "aws_security_group" "workstation_amazonlinux2_nicedcv" {
  count       = var.create_vpc ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Vault client security group"
  tags        = merge(tomap({"Name": var.name}), var.common_tags, local.extra_tags)

  # this should be further restricted in a production environment
  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = var.permitted_cidr_list_private
    security_groups = var.security_group_ids
    description     = "all incoming traffic from vpc, vpn dhcp, and remote subnet"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks     = var.permitted_cidr_list_private
    security_groups = var.security_group_ids
    description     = "SSH"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 8200
    to_port         = 8200
    cidr_blocks     = var.permitted_cidr_list
    security_groups = var.security_group_ids
    description     = "Vault Web UI Forwarding"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8443
    to_port     = 8443
    cidr_blocks = var.permitted_cidr_list_private
    description = "NICE DCV graphical server"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Vault Web UI Forwarding"
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = var.permitted_cidr_list
    description = "ICMP ping traffic"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}
data "aws_s3_bucket" "software_bucket" {
  bucket = "software.${var.bucket_extension}"
}
resource "aws_s3_object" "update_scripts" {
  for_each = fileset("${path.module}/scripts/", "*")
  bucket   = data.aws_s3_bucket.software_bucket.id
  key      = each.value
  source   = "${path.module}/scripts/${each.value}"
  etag     = filemd5("${path.module}/scripts/${each.value}")
}
locals {
  resourcetier           = var.common_tags["resourcetier"]
  client_cert_file_path  = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
  client_cert_vault_path = "${local.resourcetier}/deadline/client_cert_files${local.client_cert_file_path}"
}
data "template_file" "user_data_auth_client" {
  template = format("%s%s%s",
    file("${path.module}/user-data-iam-auth-ssh-host-consul.sh"),
    file("${path.module}/user-data-install-deadline-worker-cert.sh"),
    file("${path.module}/user-data-nice-dcv.sh")
  )
  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    aws_internal_domain      = var.aws_internal_domain
    aws_external_domain      = "" # External domain is not used for internal hosts.
    example_role_name        = "workstation-vault-role"

    deadlineuser_name                = "deadlineuser"
    deadline_version                 = var.deadline_version
    installers_bucket                = "software.${var.bucket_extension}"
    resourcetier                     = var.common_tags["resourcetier"]
    deadline_installer_script_repo   = "https://github.com/firehawkvfx/packer-firehawk-amis.git"
    deadline_installer_script_branch = "deadline-immutable" # TODO This must become immutable - version it

    client_cert_file_path  = local.client_cert_file_path
    client_cert_vault_path = local.client_cert_vault_path
  }
}
data "terraform_remote_state" "workstation_profile" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-workstation/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "aws_instance" "workstation_amazonlinux2_nicedcv" {
  count                  = var.create_vpc ? 1 : 0
  ami                    = var.workstation_amazonlinux2_nicedcv_ami_id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name # The PEM key is disabled for use in production, can be used for debugging.  Instead, signed SSH certificates should be used to access the host.
  subnet_id              = tolist(var.private_subnet_ids)[0]
  tags                   = merge(tomap({"Name": var.name}), var.common_tags, local.extra_tags)
  user_data              = data.template_file.user_data_auth_client.rendered
  iam_instance_profile   = data.terraform_remote_state.workstation_profile.outputs.instance_profile_name
  vpc_security_group_ids = local.vpc_security_group_ids
  root_block_device {
    delete_on_termination = true
  }
}
locals {
  extra_tags = {
    role  = "workstation_amazonlinux2_nicedcv"
    route = "private"
  }
  private_ip                                         = element(concat(aws_instance.workstation_amazonlinux2_nicedcv.*.private_ip, tolist([""])), 0)
  id                                                 = element(concat(aws_instance.workstation_amazonlinux2_nicedcv.*.id, tolist([""])), 0)
  workstation_amazonlinux2_nicedcv_security_group_id = element(concat(aws_security_group.workstation_amazonlinux2_nicedcv.*.id, tolist([""])), 0)
  vpc_security_group_ids                             = [local.workstation_amazonlinux2_nicedcv_security_group_id]
}
