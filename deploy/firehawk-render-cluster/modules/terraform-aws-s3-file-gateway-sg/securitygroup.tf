# This module originated from https://github.com/davebuildscloud/terraform_file_gateway/blob/master/terraform

resource "aws_security_group" "storage_gateway" {
  name        = "${var.gateway_name}-security-group"
  description = "Allow inbound NFS traffic"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "deployment_storage_gateway_access" {
  name        = "${var.gateway_name}-access"
  description = "Attach this group to your instances to get access to the storage gateway via NFS."
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "ingress_80" {
  description       = "For activation"
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 80
  type              = "ingress"
  cidr_blocks       = concat(var.permitted_cidr_list_private, var.permitted_cidr_list_provisioner)
}

resource "aws_security_group_rule" "smb_ingress_445" {
  description       = "SMB"
  from_port         = 445
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 445
  type              = "ingress"
  cidr_blocks       = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_443" {
  description       = "HTTPS"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_1026_to_1028" { # see https://aws.amazon.com/premiumsupport/knowledge-center/sg-resolve-activation-vpc-endpoint/
  description       = "ingress_1026_to_1028"
  from_port         = 1026
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 1028
  type              = "ingress"
  cidr_blocks       = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_1031" { # see https://aws.amazon.com/premiumsupport/knowledge-center/sg-resolve-activation-vpc-endpoint/
  description       = "ingress_1031"
  from_port         = 1031
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 1031
  type              = "ingress"
  cidr_blocks       = var.permitted_cidr_list_private
}

# resource "aws_security_group_rule" "ingress_2222" { # see https://aws.amazon.com/premiumsupport/knowledge-center/sg-resolve-activation-vpc-endpoint/
#   description       = "ingress_2222"
#   from_port         = 2222
#   protocol          = "tcp"
#   security_group_id = aws_security_group.storage_gateway.id
#   to_port           = 2222
#   type              = "ingress"
#   cidr_blocks       = var.permitted_cidr_list_private
# }

resource "aws_security_group_rule" "ingress_22" { # see https://aws.amazon.com/premiumsupport/knowledge-center/sg-resolve-activation-vpc-endpoint/
  description       = "ingress_22"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 22
  type              = "ingress"
  cidr_blocks       = concat(var.permitted_cidr_list_private, var.permitted_cidr_list_provisioner)
}

resource "aws_security_group_rule" "ingress_all" {
  description       = "WARNING: FOR TESTING AND DEBUGGING ONLY."
  from_port         = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 65535
  type              = "ingress"
  cidr_blocks       = concat(var.permitted_cidr_list_private, var.permitted_cidr_list_provisioner)
}

# resource "aws_security_group_rule" "ingress_all_anywhere" {
#   description       = "WARNING: FOR TESTING AND DEBUGGING ONLY."
#   from_port         = 0
#   protocol          = "ALL"
#   security_group_id = aws_security_group.storage_gateway.id
#   to_port           = 0
#   type              = "ingress"
#   cidr_blocks       = ["0.0.0.0/0"]
# }

resource "aws_security_group_rule" "ingress_icmp" {
  description       = "ICMP Ping"
  from_port         = 8
  protocol          = "icmp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 0
  type              = "ingress"
  cidr_blocks       = concat(var.permitted_cidr_list_private, var.permitted_cidr_list_provisioner)
}

resource "aws_security_group_rule" "egress_all" {
  description       = "egress"
  from_port         = 0
  protocol          = "ALL"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 65535
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_2049_tcp_product" {
  description       = "For NFS and NFSv3"
  from_port         = 2048
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 2049
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_2049_udp_product" {
  description       = "For NFS and NFSv3"
  from_port         = 2048
  protocol          = "udp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 2049
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_111_tcp_product" {
  description       = "For NFS"
  from_port         = 111
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 111
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_111_udp_product" {
  description       = "For NFS"
  from_port         = 111
  protocol          = "udp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 111
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_20048_tcp_product" {
  description       = "For NFS"
  from_port         = 20048
  protocol          = "tcp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 20048
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}

resource "aws_security_group_rule" "ingress_20048_udp_product" {
  description       = "For NFS"
  from_port         = 20048
  protocol          = "udp"
  security_group_id = aws_security_group.storage_gateway.id
  to_port           = 20048
  type              = "ingress"
  # source_security_group_id = aws_security_group.deployment_storage_gateway_access.id
  cidr_blocks = var.permitted_cidr_list_private
}
