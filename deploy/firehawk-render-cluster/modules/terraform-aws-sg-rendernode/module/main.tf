locals {
  name = "${lookup(local.common_tags, "vpcname", "default")}_rendernode_ec2_pipeid${lookup(local.common_tags, "pipelineid", "0")}"
  # permitted_cidr_list = [var.combined_vpcs_cidr, var.vpn_cidr, var.onsite_private_subnet_cidr]
  common_tags = var.common_tags
  extra_tags = {
    role  = "rendernode"
    route = "private"
  }
}
resource "aws_security_group" "node_centos7_houdini" {
  count       = length(var.vpc_id) > 0 ? 1 : 0
  name        = local.name
  vpc_id      = var.vpc_id
  description = "Vault client security group"
  tags        = merge(tomap({"Name": local.name}), var.common_tags, local.extra_tags)

  # this should be further restricted in a production environment
  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = var.permitted_cidr_list_private
    security_groups = var.security_group_ids
    description     = "all incoming traffic from vpc, vpn dhcp, and remote subnet"
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
    cidr_blocks     = var.permitted_cidr_list_private
    security_groups = var.security_group_ids
    description     = "SSH"
  }
  # ingress {
  #   protocol        = "tcp"
  #   from_port       = 8200
  #   to_port         = 8200
  #   cidr_blocks     = var.permitted_cidr_list
  #   security_groups = var.security_group_ids
  #   description     = "Vault"
  # }
  ingress {
    protocol    = "tcp"
    from_port   = 27100
    to_port     = 27100
    cidr_blocks = var.permitted_cidr_list_private
    description = "DeadlineDB MongoDB"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = var.permitted_cidr_list_private
    description = "Deadline And Deadline RCS"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 4433
    to_port     = 4433
    cidr_blocks = var.permitted_cidr_list_private
    description = "Deadline RCS TLS HTTPS"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 1714
    to_port     = 1714
    cidr_blocks = var.permitted_cidr_list_private
    description = "Houdini"
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