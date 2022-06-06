data "aws_region" "current" {}
data "terraform_remote_state" "rendervpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-render-vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vpc_id = try(data.terraform_remote_state.rendervpc.outputs.vpc_id, "")
}
data "aws_vpc" "thisvpc" {
  count = length(local.vpc_id) > 0 ? 1 : 0
  default = false
  tags    = var.common_tags
}
data "terraform_remote_state" "provisioner_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "predeploy/modules/terraform-aws-sg-provisioner/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  name                = "${lookup(local.common_tags, "vpcname", "default")}_openvpn_ec2_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  permitted_cidr_list = [var.combined_vpcs_cidr, var.vpn_cidr, var.onsite_private_subnet_cidr]
  remote_vpn_ip_cidr  = "${var.onsite_public_ip}/32"
  common_tags         = var.common_tags
  extra_tags = {
    role  = "vpn"
    route = "public"
  }
  deployer_sg_id = data.terraform_remote_state.provisioner_security_group.outputs.security_group_id
}
resource "aws_security_group" "openvpn" {
  count = length(local.vpc_id) > 0 ? 1 : 0
  name        = local.name
  vpc_id      = local.vpc_id
  description = "OpenVPN security group"
  tags        = merge(tomap({"Name": local.name}), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = local.permitted_cidr_list
    description = "all incoming traffic from vault and render vpc, vpn dhcp cidr range, and remote subnet"
  }

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    security_groups = [local.deployer_sg_id]
    description     = "ssh"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [local.remote_vpn_ip_cidr]
    description = "https"
  }
  # see  https://openvpn.net/vpn-server-resources/amazon-web-services-ec2-tiered-appliance-quick-start-guide/
  ingress {
    protocol    = "tcp"
    from_port   = 943
    to_port     = 943
    cidr_blocks = [local.remote_vpn_ip_cidr]
    description = "admin ui"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 945
    to_port     = 945
    cidr_blocks = [local.remote_vpn_ip_cidr]
    description = "admin ui"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = [local.remote_vpn_ip_cidr]
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [local.remote_vpn_ip_cidr]
    description = "icmp"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [local.remote_vpn_ip_cidr]
    description = "all outgoing traffic to vpn client remote ip"
  }
  # egress {
  #   protocol    = "-1"
  #   from_port   = 0
  #   to_port     = 0
  #   cidr_blocks = [var.vpc_cidr]
  #   description = "all outgoing traffic to vpc"
  # }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic to anywhere"
  }
}
