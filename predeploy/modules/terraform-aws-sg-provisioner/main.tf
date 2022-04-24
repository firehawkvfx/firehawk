data "aws_vpc" "thisvpc" {
  default = false
  tags    = var.common_tags
}

resource "aws_security_group" "provisioner" {
  name        = var.name
  vpc_id      = data.aws_vpc.thisvpc.id
  description = "Provisioner Security Group"
  tags        = merge(tomap({"Name": var.name}), var.common_tags, local.extra_tags)
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
    role  = "provisioner"
    route = "public"
  }
}