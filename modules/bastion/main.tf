#----------------------------------------------------------------
# This module creates all resources necessary for am Ansible Bastion instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "bastion" {
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
  vpc      = true
  instance = aws_instance.bastion.id

  tags = {
    role  = "bastion"
    route = "public"
  }
}

resource "aws_instance" "bastion" {
  ami           = var.ami_map[var.region]
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = element(var.public_subnet_ids, 0)

  vpc_security_group_ids = [aws_security_group.bastion.id]

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

resource "null_resource" "provision_bastion" {
  depends_on = [
    aws_instance.bastion,
    aws_eip.bastionip,
    aws_route53_record.bastion_record,
  ]

  triggers = {
    instanceid = aws_instance.bastion.id
  }

  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = aws_eip.bastionip.public_ip
      private_key = var.private_key
      type        = "ssh"
      timeout     = "10m"
    }

    inline = ["set -x && sudo yum install -y python"]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory/hosts ansible/ssh-add-public-host.yaml -v --extra-vars "public_ip=${aws_eip.bastionip.public_ip} public_hostname=bastion.${var.public_domain_name} set_bastion=true"
  
EOT

  }
}

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_record" {
  zone_id = var.route_zone_id
  name    = "bastion.${var.public_domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.bastionip.public_ip]
}

resource "null_resource" "start-bastion" {
  count = var.sleep ? 0 : 1

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.bastion.id}"
  }
}

resource "null_resource" "shutdown-bastion" {
  count = var.sleep ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      aws ec2 stop-instances --instance-ids ${aws_instance.bastion.id}
  
EOT

  }
}

