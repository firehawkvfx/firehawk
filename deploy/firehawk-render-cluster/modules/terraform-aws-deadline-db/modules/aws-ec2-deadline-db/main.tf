# A vault client host with consul registration and signed host keys from vault.

data "aws_region" "current" {}

resource "aws_security_group" "deadline_license_forwarder" {
  count       = var.create_vpc ? 1 : 0
  name        = "deadline_license_forwarder_sg"
  vpc_id      = var.vpc_id
  description = "Deadline DB security group"
  tags        = local.common_tags
  ingress {
    protocol    = "tcp"
    from_port   = 17004
    to_port     = 17005
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Launcher Listening Port, Deadline Auto Config Port, Deadline Worker / Slave Startup Port"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 1715
    to_port     = 1716
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Hserver port for UBL - Engine & Mantra"
  }
}

# resource "aws_security_group" "consul_clients" {
#   name        = "Consul clients security group"
#   description = "Security group for Consul Clients"
#   vpc_id      = var.vpc_id
# }

# module "security_group_rules" {
#   source = "git::git@github.com:hashicorp/terraform-aws-consul.git//modules/consul-client-security-group-rules?ref=v0.0.2"
#   security_group_id = resource.aws_security_group.security_group_id
# }
resource "aws_security_group" "deadline_db_instance" { # see https://docs.thinkboxsoftware.com/products/deadline/10.0/1_User%20Manual/manual/considerations.html
  count       = var.create_vpc ? 1 : 0
  name        = "deadline_db_sg"
  vpc_id      = var.vpc_id
  description = "Deadline DB security group"
  tags        = local.common_tags
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = var.permitted_cidr_list_private
    description = "all incoming traffic from vpc, vpn dhcp, and remote subnet"
  }
  # ingress {
  #   protocol    = "-1"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = ["0.0.0.0/0"]
  #   description = "WARNING: TESTING ONLY"
  # }
  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = var.security_group_ids
    description     = "SSH"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 17000
    to_port     = 17003
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Launcher Listening Port, Deadline Auto Config Port, Deadline Worker / Slave Startup Port"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 27100
    to_port     = 27100
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Deadline DB port"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Deadline RCS port"
  }
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = 8082
  #   to_port     = 8082
  #   cidr_blocks = var.permitted_cidr_list
  #   # security_groups = var.security_group_ids
  #   description = "Deadline Web Service port"
  # }
  ingress {
    protocol    = "tcp"
    from_port   = 4433
    to_port     = 4433
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Deadline TLS port"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = var.permitted_cidr_list
    # security_groups = var.security_group_ids
    description = "Deadline UBL port"
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
data "template_file" "user_data_auth_client" {
  template = format(
    "%s%s%s%s",
    file("${path.module}/user-data-iam-auth-ssh-host-consul.sh"),
    file("${path.module}/user-data-install-deadline-db.sh"),
    file("${path.module}/user-data-vault-store-file.sh"),
    file("${path.module}/user-data-register-consul-service.sh"),
  )
  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
    aws_internal_domain      = var.aws_internal_domain
    aws_external_domain      = "" # External domain is not used for internal hosts.
    example_role_name        = "deadline-db-vault-role"

    resourcetier      = local.resourcetier
    db_host_name      = "deadlinedb.service.consul"
    installers_bucket = "software.${var.bucket_extension}"
    ubl_certs_bucket  = "ublcerts.${var.bucket_extension_vault}"
    deadlineuser_name = "deadlineuser" # Create this user and install software as this user.
    deadline_version  = var.deadline_version
    consul_service    = "deadlinedb"

    client_cert_file_path  = local.client_cert_file_path
    client_cert_vault_path = local.client_cert_vault_path
  }
}
data "terraform_remote_state" "deadline_db_profile" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "init/modules/terraform-aws-iam-profile-deadline-db/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "aws_subnet" "private" {
  id = var.private_subnet_ids[0]
}
locals {
  private_subnet_cidr_block                    = data.aws_subnet.private.cidr_block
  private_ip                                   = cidrhost(local.private_subnet_cidr_block, var.host_number)
  resourcetier                                 = var.common_tags["resourcetier"]
  id                                           = length(aws_instance.deadline_db_instance) > 0 ? aws_instance.deadline_db_instance[0].id : null
  deadline_db_instance_security_group_id       = length(aws_security_group.deadline_db_instance) > 0 ? aws_security_group.deadline_db_instance[0].id : null
  deadline_license_forwarder_security_group_id = length(aws_security_group.deadline_license_forwarder) > 0 ? aws_security_group.deadline_license_forwarder[0].id : null
  client_cert_file_path                        = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
  client_cert_vault_path                       = "${local.resourcetier}/deadline/client_cert_files${local.client_cert_file_path}"
  common_tags                                  = merge(tomap({ "Name" : var.name }), var.common_tags, local.extra_tags)
  extra_tags = {
    role  = "deadline_db_instance"
    route = "private"
  }
}
resource "aws_instance" "deadline_db_instance" {
  depends_on             = [aws_s3_object.update_scripts]
  count                  = var.create_vpc ? 1 : 0
  private_ip             = local.private_ip # Deadline DB is not configured for HA
  ami                    = var.deadline_db_ami_id
  instance_type          = var.instance_type
  key_name               = var.aws_key_name # The PEM key is disabled for use in production, can be used for debugging.  Instead, signed SSH certificates should be used to access the host.
  subnet_id              = data.aws_subnet.private.id
  tags                   = local.common_tags
  user_data              = data.template_file.user_data_auth_client.rendered
  iam_instance_profile   = data.terraform_remote_state.deadline_db_profile.outputs.instance_profile_name
  vpc_security_group_ids = [local.deadline_db_instance_security_group_id, local.deadline_license_forwarder_security_group_id]
  root_block_device {
    delete_on_termination = true
  }
}
