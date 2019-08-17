#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "pcoipgw" {
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Teradici PCOIP security group"

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
    cidr_blocks = [var.remote_ip_cidr]
    description = "all incoming traffic from remote access ip"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpn_cidr]
    description = "all incoming traffic from remote subnet range"
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
    protocol    = "udp"
    from_port   = 4172
    to_port     = 4172
    cidr_blocks = [var.remote_ip_cidr]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4172
    to_port     = 4172
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

variable "houdini_license_server_address" {
}

variable "private_subnets_cidr_blocks" {
  default = []
}

variable "openfirehawkserver" {
}

variable "remote_subnet_cidr" {
}

resource "aws_security_group" "gateway_centos" {
  name        = "gateway_centos"
  vpc_id      = var.vpc_id
  description = "Gateway Teradici PCOIP security group"

  tags = {
    Name = "gateway_centos"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "all incoming traffic from vpc"
  }

  # todo need to tighten down ports.
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_ip_cidr]
    description = "all incoming traffic from remote access ip"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpn_cidr]
    description = "all incoming traffic from remote subnet range"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.houdini_license_server_address}/32"]
    description = "Houdini License Server"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.openfirehawkserver}/32"]
    description = "Deadline DB"
  }

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.remote_ip_cidr]
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = concat([var.remote_subnet_cidr, var.remote_ip_cidr], var.private_subnets_cidr_blocks )
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
    protocol  = "tcp"
    from_port = 27100
    to_port   = 27100
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
    description = "DeadlineDB MongoDB"
  }
  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
    description = "Deadline And Deadline RCS"
  }
  ingress {
    protocol  = "tcp"
    from_port = 4433
    to_port   = 4433
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
    description = "Deadline RCS TLS HTTPS"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 1714
    to_port     = 1714
    cidr_blocks = ["${var.houdini_license_server_address}/32"]
    description = "Houdini license server"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1714
    to_port     = 1714
    cidr_blocks = ["${var.houdini_license_server_address}/32"]
    description = "Houdini license server"
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

# You may wish to use a custom ami of your own creation.  insert the ami details below
variable "use_custom_ami" {
  default = false
}

variable "custom_ami" {
  default = ""
}

locals {
  skip_update = var.skip_update || var.use_custom_ami
}

resource "aws_eip" "pcoipgw_eip" {
  vpc      = true
  instance = aws_instance.pcoipgw.id

  tags = {
    role  = "workstation_centos"
    route = "public"
  }
}

resource "aws_instance" "pcoipgw" {
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  ami           = var.use_custom_ami ? var.custom_ami : var.ami_map[var.gateway_type]
  instance_type = var.instance_type_map[var.gateway_type]

  key_name  = var.key_name
  subnet_id = element(var.public_subnet_ids, 0)

  vpc_security_group_ids = [aws_security_group.pcoipgw.id, aws_security_group.gateway_centos.id]

  ebs_optimized = true
  root_block_device {
    volume_size           = "30"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name  = "gateway_centos"
    Route = "public"
  }

  #Role  = "workstation_centos"

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = self.public_ip
      private_key = var.private_key
      timeout     = "10m"
    }

    inline = [
      "sleep 60",
    ]
  }
  # provisioner "local-exec" {
  #   command = "${var.pcoip_sleep_after_creation && local.skip_update ? "aws ec2 stop-instances --instance-ids ${aws_instance.pcoipgw.id}" : ""}"
  # }
}

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_record" {
  zone_id = var.route_zone_id
  name    = "gateway.${var.public_domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_eip.pcoipgw_eip.public_ip]
}

resource "null_resource" "pcoipgw" {
  count = local.skip_update ? 0 : 1

  triggers = {
    instanceid = aws_instance.pcoipgw.id
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.pcoipgw.private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # First we install python remotely via the bastion to bootstrap the instance.  We also need this remote-exec to ensure the host is up.
    inline = ["sleep 10 && set -x && sudo yum install -y python"]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory/hosts ansible/ssh-add-public-host.yaml -v --extra-vars "public_ip=${aws_eip.pcoipgw_eip.public_ip} public_hostname=gateway.${var.public_domain_name} set_bastion=false"
      # ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.pcoipgw.private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i ansible/inventory ansible/node-centos-init.yaml -v --extra-vars "variable_host=pcoipgw_eip.0 hostname=gateway.${var.public_domain_name} pcoip=true"
      ansible-playbook -i ansible/inventory ansible/node-centos-houdini.yaml -v --extra-vars "variable_host=pcoipgw_eip.0 hostname=gateway.${var.public_domain_name} firehawk_sync_source=$TF_VAR_firehawk_sync_source"
      # to recover from yum update breaking pcoip we reinstall the nvidia driver and dracut to fix pcoip.
      ansible-playbook -i ansible/inventory ansible/node-centos-pcoip-recover.yaml -v --extra-vars "variable_host=pcoipgw_eip.0 hostname=gateway.${var.public_domain_name}"
  
EOT

  }

  #after dracut, we reboot the instance locally.  annoyingly, a reboot command will cause a terraform error.
  #after dracut, we reboot the instance locally.  annoyingly, a reboot command will cause a terraform error.
  provisioner "local-exec" {
    command = var.pcoip_sleep_after_creation ? "aws ec2 stop-instances --instance-ids ${aws_instance.pcoipgw.id}" : "aws ec2 reboot-instances --instance-ids ${aws_instance.pcoipgw.id}"
  }
  #transfer the gpu driver
  # provisioner "file" {
  #   source      = "${path.module}/gpudriver/NVIDIA-Linux-x86_64-390.96-grid.run"
  #   destination = "/home/centos/NVIDIA-Linux-x86_64-390.96-grid.run"

  #   connection {
  #     user        = "centos"
  #     host        = "${aws_instance.pcoipgw.public_ip}"
  #     private_key = "${var.private_key}"
  #     type        = "ssh"
  #     timeout     = "10m"
  #   }
  # }

  # provisioner "remote-exec" {
  #   connection {
  #     user        = "centos"
  #     host        = "${aws_instance.pcoipgw.public_ip}"
  #     private_key = "${var.private_key}"
  #     type        = "ssh"
  #     timeout     = "10m"
  #   }

  #   inline = [
  #     #"sudo yum update -y",

  #     # these are deadline dependencies
  #     "sudo yum install redhat-lsb libX11 libXext -y",

  #     "sudo yum install libMesaGL1 -y",
  #     "sudo yum install mesa-libGL mesa-libGLU -y",
  #   ]
  # }
}

resource "null_resource" "shutdownpcoipgw" {
  count = var.sleep ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.pcoipgw.id}"
  }
}

