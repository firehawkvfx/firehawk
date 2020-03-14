#----------------------------------------------------------------
# This module creates all resources necessary for am Ansible Bastion instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "bastion" {
  count       = var.create_vpc ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Bastion Security Group"

  tags = {
    Name = var.name
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "all incoming traffic from vpc"
  }

  # todo need to replace this with correct protocols for pcoip instead of all ports.description
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpn_cidr, var.remote_subnet_cidr, "172.27.236.0/24"]
    description = "all incoming traffic from remote access ip"
  }

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.remote_ip_cidr]
    description = "ssh"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.remote_ip_cidr]
    description = "https"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = [var.remote_ip_cidr]
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_ip_cidr]
    description = "icmp"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_eip" "bastionip" {
  count    = var.create_vpc ? 1 : 0
  vpc      = true
  instance = aws_instance.bastion[count.index].id

  tags = {
    role  = "bastion"
    route = "public"
  }
}
variable "centos_v7" {
  type = map(string)
  default = {
        "eu-north-1": "ami-5ee66f20",
        "ap-south-1": "ami-02e60be79e78fef21",
        "eu-west-3": "ami-0e1ab783dc9489f34",
        "eu-west-2": "ami-0eab3a90fc693af19",
        "eu-west-1": "ami-0ff760d16d9497662",
        "ap-northeast-2": "ami-06cf2a72dadf92410",
        "ap-northeast-1": "ami-045f38c93733dd48d",
        "sa-east-1": "ami-0b8d86d4bf91850af",
        "ca-central-1": "ami-033e6106180a626d0",
        "ap-southeast-1": "ami-0b4dd9d65556cac22",
        "ap-southeast-2": "ami-08bd00d7713a39e7d",
        "eu-central-1": "ami-04cf43aca3e6f3de3",
        "us-east-1": "ami-02eac2c0129f6376b",
        "us-east-2": "ami-0f2b4fc905b0bd1f1",
        "us-west-1": "ami-074e2d6769f445be5",
        "us-west-2": "ami-01ed306a12b7d1c96"
    }
}

resource "aws_instance" "bastion" {
  count         = var.create_vpc ? 1 : 0
  ami           = lookup(var.centos_v7, var.region)
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = element(var.public_subnet_ids, 0)

  vpc_security_group_ids = [local.security_group_id]

  root_block_device {
    delete_on_termination = true
  }
  
  tags = {
    Name = var.name
  }

  #role = "bastion"
  #route = "public"

  # `admin_user` and `admin_pw` need to be passed in to the appliance through `user_data`, see docs -->
  # https://docs.openvpn.net/how-to-tutorialsguides/virtual-platforms/amazon-ec2-appliance-ami-quick-start-guide/
  user_data = <<USERDATA

USERDATA

}

locals {
  public_ip = element(concat(aws_eip.bastionip.*.public_ip, list("")), 0)
  private_ip = element(concat(aws_instance.bastion.*.private_ip, list("")), 0)
  id = element(concat(aws_instance.bastion.*.id, list("")), 0)
  security_group_id = element(concat(aws_security_group.bastion.*.id, list("")), 0)
  bastion_address = var.route_public_domain_name ? "bastion.${var.public_domain_name}":"${local.public_ip}"
  bastion_dependency = element(concat(null_resource.provision_bastion.*.id, list("")), 0)
}


resource "null_resource" "provision_bastion" {
  count    = var.create_vpc ? 1 : 0
  depends_on = [
    aws_instance.bastion,
    aws_eip.bastionip,
    aws_route53_record.bastion_record,
  ]

  triggers = {
    instanceid = local.id
    bastion_address = local.bastion_address
  }

  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = local.public_ip
      private_key = var.private_key
      type        = "ssh"
      timeout     = "10m"
    }

    inline = ["set -x && sudo yum install -y python"]
  }

  provisioner "local-exec" {
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      set -x
      cd /deployuser
      echo "check keys permissions"
      ls -ltriah /secrets/keys
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-public-host.yaml -v --extra-vars "public_ip=${local.public_ip} public_address=${local.bastion_address} bastion_address=${local.bastion_address} set_bastion=true"; exit_test
EOT

  }
}

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_record" {
  count   = var.route_public_domain_name && var.create_vpc ? 1 : 0
  zone_id = element(concat(list(var.route_zone_id), list("")), 0)
  name    = element(concat(list("bastion.${var.public_domain_name}"), list("")), 0)
  type    = "A"
  ttl     = 300
  records = [local.public_ip]
}

resource "null_resource" "start-bastion" {
  count = ( !var.sleep && var.create_vpc) ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${local.id}"
  }
}

resource "null_resource" "shutdown-bastion" {
  count = var.sleep && var.create_vpc ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      aws ec2 stop-instances --instance-ids ${local.id}
  
EOT

  }
}

