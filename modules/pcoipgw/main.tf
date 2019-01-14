#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "pcoipgw" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"
  description = "Teradici PCOIP security group"

  tags {
    Name = "${var.name}"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpc_cidr}"]
    description = "all incoming traffic from vpc"
  }

  # todo need to replace this with correct protocols for pcoip instead of all ports.description
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.remote_ip_cidr}"]
    description = "all incoming traffic from remote access ip"
  }

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["${var.remote_ip_cidr}"]
    description = "ssh"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["${var.remote_ip_cidr}"]
    description = "https"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["${var.remote_ip_cidr}"]
  }
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = ["${var.remote_ip_cidr}"]
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

resource "aws_instance" "pcoipgw" {
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  ami           = "${lookup(var.ami_map, var.gateway_type)}"
  instance_type = "${lookup(var.instance_type_map, var.gateway_type)}"

  key_name  = "${var.key_name}"
  subnet_id = "${element(var.public_subnet_ids, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.pcoipgw.id}"]

  tags {
    Name = "${var.gateway_type}"
  }

  # this segment is not currently configured for centos. user name and pw need to be setup in userdata.
  # `admin_user` and `admin_pw` need to be passed in to the appliance through `user_data`, see docs -->
  # https://docs.openvpn.net/how-to-tutorialsguides/virtual-platforms/amazon-ec2-appliance-ami-quick-start-guide/
  #user_data = <<USERDATA
  #USERDATA

  #first sleep for some time before instance is ready after boot.
  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${self.public_ip}"
      private_key = "${var.private_key}"
      timeout     = "10m"
    }

    inline = [
      # Sleep 60 seconds until AMI is ready
      "sleep 60",
    ]
  }
  #transfer the gpu driver
  provisioner "file" {
    source      = "${path.module}/gpudriver/NVIDIA-Linux-x86_64-390.96-grid.run"
    destination = "/home/centos/NVIDIA-Linux-x86_64-390.96-grid.run"

    connection {
      user        = "centos"
      host        = "${aws_instance.pcoipgw.public_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }
  }
  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${aws_instance.pcoipgw.public_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [
      "sudo yum update -y",
    ]
  }
  provisioner "local-exec" {
    command = "aws ec2 reboot-instances --instance-ids ${self.id} & sleep 10"
  }
  #update yum will break pcoip, so it is reconfigured at this point.
  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${aws_instance.pcoipgw.public_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [
      "uptime",
      "sudo systemctl restart pcoip.service",
      "sudo /bin/sh NVIDIA-Linux-x86_64-390.96-grid.run --dkms -s --install-libglvnd",
      "sudo dracut -fv",
    ]
  }
  #after dracut, we reboot the instance locally.  annoyingly, a reboot command will cause a terraform error.
  provisioner "local-exec" {
    command = "aws ec2 reboot-instances --instance-ids ${self.id}"
  }
}
