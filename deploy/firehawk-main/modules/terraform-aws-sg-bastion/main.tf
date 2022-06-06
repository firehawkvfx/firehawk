data "aws_region" "current" {}
data "terraform_remote_state" "vaultvpc" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/vpc/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
locals {
  vpc_id  = length( try(data.terraform_remote_state.vaultvpc.outputs.vpc_id, "") ) > 0 ? data.terraform_remote_state.vaultvpc.outputs.vpc_id : ""
}

data "aws_vpc" "thisvpc" {
  count = length(local.vpc_id)>0 ? 1 : 0
  default = false
  id = local.vpc_id
}

resource "aws_security_group" "bastion" {
  count = length(local.vpc_id)>0 ? 1 : 0
  name        = var.name
  vpc_id      = local.vpc_id
  description = "Bastion Security Group"
  tags        = merge(tomap({"Name": var.name}), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_vpc.thisvpc[0].cidr_block]
    description = "All incoming traffic from vpc"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8200
    to_port     = 8200
    cidr_blocks = local.permitted_cidr_list
    description = "Vault UI forwarding"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = local.permitted_cidr_list
    description = "SSH"
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = local.permitted_cidr_list
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

locals {
  extra_tags = {
    role  = "bastion"
    route = "public"
  }
  permitted_cidr_list = ["${var.onsite_public_ip}/32", var.remote_cloud_public_ip_cidr, var.remote_cloud_private_ip_cidr]
}