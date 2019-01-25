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
    cidr_blocks = ["${concat(list("${var.remote_subnet_cidr}", "${var.remote_ip_cidr}"), "${var.private_subnets_cidr_blocks}")}"]
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
    protocol    = "tcp"
    from_port   = 27100
    to_port     = 27100
    cidr_blocks = ["${concat(list("${var.remote_subnet_cidr}"), "${var.private_subnets_cidr_blocks}")}"]
    description = "DeadlineDB MongoDB"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["${concat(list("${var.remote_subnet_cidr}"), "${var.private_subnets_cidr_blocks}")}"]
    description = "Deadline And Deadline RCS"
  }
  ingress {
    protocol    = "tcp"
    from_port   = 4433
    to_port     = 4433
    cidr_blocks = ["${concat(list("${var.remote_subnet_cidr}"), "${var.private_subnets_cidr_blocks}")}"]
    description = "Deadline RCS TLS HTTPS"
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

  # provisioner "remote-exec" {
  #   connection {
  #     user        = "centos"
  #     host        = "${self.private_ip}"
  #     private_key = "${var.private_key}"
  #     timeout     = "10m"
  #   }

  #   inline = [
  #     # Sleep 60 seconds until AMI is ready
  #     "sleep 60",
  #   ]
  # }
}

variable "deadline_user" {
  default = "deadlineuser"
}

variable "deadline_user_password" {}

variable "deadline_user_uid" {}

variable "deadline_samba_server_address" {
  default = "192.169.0.111"
}

#wakeup a node after sleep
resource "null_resource" "start-node" {
  count = "${var.sleep ? 0 : 1}"

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos.id}"
  }
}

resource "null_resource" "update_node" {
  # todo: this wont provision unless vpn client routes to deadline db onsite are established.  read tf_aws_vpn notes for more configuration instructions.
  #start vpn and generate a public key from private key.
  provisioner "local-exec" {
    command = <<EOT
      ~/openvpn_config/startvpn.sh
      sleep 10
      ping -c5 '${aws_instance.node_centos.private_ip}'
      ssh-keygen -y -f ${var.local_key_path} > ~/temp_public_key
  EOT
  }

  provisioner "file" {
    connection {
      user        = "centos"
      host        = "${aws_instance.node_centos.private_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    source      = "~/temp_public_key"
    destination = "~/temp_public_key"
  }

  #remove public key from local system after copy to instance
  provisioner "local-exec" {
    command = <<EOT
      rm -frv ~/temp_public_key
  EOT
  }

  #provision the deadline user https://aws.amazon.com/premiumsupport/knowledge-center/new-user-accounts-linux-instance/
  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${aws_instance.node_centos.private_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [<<EOT
#create dealine user and password.  its important for the deadline user to have the same uid across any system where the user exists.
sudo useradd -u ${var.deadline_user_uid} ${var.deadline_user}
sudo passwd -d ${var.deadline_user}
sudo mkdir /home/${var.deadline_user}/.ssh
#sudo touch /home/${var.deadline_user}/.ssh/authorized_keys
#move public key to defined authorised key, will replace anything in here if it exists.
sudo mv ~/temp_public_key /home/${var.deadline_user}/.ssh/authorized_keys
#set ownership, write permission for deadline user to folder, and read & write for owner to authorized keys file per amazon documentation.
sudo chown -R ${var.deadline_user}:${var.deadline_user} /home/${var.deadline_user}/.ssh
sudo chmod 700 /home/${var.deadline_user}/.ssh
sudo chmod 600 /home/${var.deadline_user}/.ssh/authorized_keys
EOT
    ]
  }

  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${aws_instance.node_centos.private_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [<<EOT
#give sudo priveledges after key is added
sudo usermod -aG wheel ${var.deadline_user}
sudo systemctl restart sshd.service
sudo mkdir -p /opt/Thinkbox/certs

sudo chown -R ${var.deadline_user}:${var.deadline_user} /opt/Thinkbox/certs
sudo chmod 700 /opt/Thinkbox/certs
echo 'uid is-'
id -u ${var.deadline_user}
echo 'gid is-'
id -g ${var.deadline_user}
EOT
    ]
  }

  # now we can connect as the deadlineuser
  connection {
    user        = "${var.deadline_user}"
    host        = "${aws_instance.node_centos.private_ip}"
    private_key = "${var.private_key}"
    type        = "ssh"
    timeout     = "10m"
  }

  #copy the deadline certificates to the render node
  #provisioner "file" {
  #  source      = "${var.deadline_certificates_location}/ca.crt"
  #  destination = "/opt/Thinkbox/certs/ca.crt"
  #}

  provisioner "file" {
    source      = "${var.deadline_certificates_location}/Deadline10RemoteClient.pfx"
    destination = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
  }

  #provisioner "file" {
  #  source      = "${var.deadline_certificates_location}/deadlinedb.firehawkvfx.com.pfx"
  #  destination = "/opt/Thinkbox/certs/deadlinedb.firehawkvfx.com.pfx"
  #}

  #copy the deadline installer to the rendernode 
  provisioner "file" {
    source      = "${path.module}/file_package/${var.deadline_installers_filename}"
    destination = "/var/tmp/${var.deadline_installers_filename}"
  }
  provisioner "remote-exec" {
    connection {
      user        = "${var.deadline_user}"
      host        = "${aws_instance.node_centos.private_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [
      "sudo chmod 600 /opt/Thinkbox/certs/Deadline10RemoteClient.pfx",
      "sudo chmod 700 /var/tmp/${var.deadline_installers_filename}",
    ]

    #"sudo chmod +x /var/tmp/${var.deadline_installers_filename}",
  }
  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${aws_instance.node_centos.private_ip}"
      private_key = "${var.private_key}"
      type        = "ssh"
      timeout     = "10m"
    }

    inline = [<<EOT
#create dealine user and password
#sudo useradd -u ${var.deadline_user_uid} ${var.deadline_user}
#echo '${var.deadline_user_password}' | sudo passwd ${var.deadline_user} --stdin
#give sudo priveledges
#sudo usermod -aG wheel ${var.deadline_user}

#read here to improve automounting mound cifs smb processes https://wiki.centos.org/TipsAndTricks/WindowsShares

sudo mkdir /etc/deadline
cat << EOF | sudo tee --append /etc/deadline/secret.txt
username=${var.deadline_user}
password=${var.deadline_user_password}
EOF
#ensure secret is readable only by root
sudo chmod 400 /etc/deadline/secret.txt
set -x
${var.skip_update ? " \n" : "sudo yum update -y"}

#These are deadline dependencies
sudo yum install redhat-lsb -y
sudo yum install samba-client samba-common cifs-utils -y
sudo yum install nfs-utils nfs-utils-lib -y
#bzip2 is needed to install deadline client.
sudo yum install bzip2 -y
#mount repository automatically over the vpn.  if you don't have routing configured, this won't work
sudo mkdir /mnt/repo
sudo mkdir /mnt/softnas
cat << EOF | sudo tee --append /etc/fstab
//${var.deadline_samba_server_address}/DeadlineRepository /mnt/repo cifs    credentials=/etc/deadline/secret.txt,_netdev,uid=${var.deadline_user_uid} 0 0
${var.softnas_private_ip}:/NAS3/NASVOL3 /mnt/softnas nfs4 rsize=8192,wsize=8192,timeo=14,intr,_netdev 0 0
EOF
cat << EOF | sudo tee --append /etc/hosts
${var.deadline_samba_server_hostname}  ${var.deadline_samba_server_hostname}
EOF
#sudo mount -a
#sudo ls /mnt/repo
EOT
    ]
  }

  #sudo mount -t cifs -o username=${var.deadline_user},password=${var.deadline_user_password} //${var.deadline_samba_server_address}/DeadlineRepository /mnt/repo

  #a reboot command in the shell of the instance will cause a terraform error.  We do it locally instead.
  provisioner "local-exec" {
    command = "aws ec2 reboot-instances --instance-ids ${aws_instance.node_centos.id}"
  }
}

resource "null_resource" "shutdown-node" {
  count = "${var.sleep ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.node_centos.id}"
  }
}
