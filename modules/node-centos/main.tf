#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "node_centos" {
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

  # todo need to tighten down ports.
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.remote_ip_cidr}"]
    description = "all incoming traffic from remote access ip"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["${var.vpn_cidr}"]
    description = "all incoming traffic from remote subnet range"
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

# You may wish to use a custom ami that incorporates your own configuration.  Insert the ami details below if you wish to use this.
variable "use_custom_ami" {
  default = false
}

variable "custom_ami" {
  default = ""
}

resource "aws_instance" "node_centos" {
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  ami           = "${var.use_custom_ami ? var.custom_ami : lookup(var.ami_map, var.region)}"
  instance_type = "${var.instance_type}"

  key_name  = "${var.key_name}"
  subnet_id = "${element(var.private_subnet_ids, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.node_centos.id}"]

  tags {
    Name = "node_centos"
  }
}

#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = "${self.public_ip}"
#       private_key = "${var.private_key}"
#       timeout     = "10m"
#     }


#     inline = [
#       # Sleep 60 seconds until AMI is ready
#       "sleep 60",
#     ]
#   }
# }


# resource "null_resource" "update-node" {
#   count = "${var.skip_update ? 0 : 1}"


#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = "${aws_instance.node_centos.public_ip}"
#       private_key = "${var.private_key}"
#       timeout     = "10m"
#     }


#     inline = [
#       # Sleep 60 seconds until AMI is ready
#       "sudo yum update -y",


#       "sudo yum reboot",
#     ]
#   }
# }


# resource "null_resource" "shutdown-node" {
#   count = "${var.sleep ? 1 : 0}"


#   provisioner "local-exec" {
#     command = "aws ec2 stop-instances --instance-ids ${aws_instance.node_centos.id}"
#   }
# }

