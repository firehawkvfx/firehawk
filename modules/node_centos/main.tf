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

variable "provision_softnas_volumes" {}

resource "null_resource" "dependency_softnas_bastion" {
  triggers {
    softnas_private_ip1 = "${var.softnas_private_ip1}"
    bastion_ip = "${var.bastion_ip}"
    provision_softnas_volumes = "${var.provision_softnas_volumes}"
  }
}
resource "aws_instance" "node_centos" {
  depends_on = ["null_resource.dependency_softnas_bastion"]
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  ami           = "${var.use_custom_ami ? var.custom_ami : lookup(var.ami_map, var.region)}"
  instance_type = "${var.instance_type}"

  #ebs_optimized = true

  root_block_device {
    volume_size = "16"
    volume_type = "standard"
  }
  key_name               = "${var.key_name}"
  subnet_id              = "${element(var.private_subnet_ids, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.node_centos.id}"]
  tags {
    Name  = "node_centos"
    Route = "private"
    Role  = "node_centos"
  }
}

resource "null_resource" "provision_node_centos" {
  depends_on = ["aws_instance.node_centos"]

  triggers {
    instanceid = "${ aws_instance.node_centos.id }"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = "${aws_instance.node_centos.private_ip}"
      bastion_host        = "${var.bastion_ip}"
      private_key         = "${var.private_key}"
      bastion_private_key = "${var.private_key}"
      type                = "ssh"
      timeout             = "10m"
    }
    # First we install python remotely via the bastion to bootstrap the instance.  We also need this remote-exec to ensure the host is up.
    inline = [
      "sleep 10",
      "set -x",
      "sudo yum install -y python",
      "ssh-keyscan ${aws_instance.node_centos.private_ip}"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.node_centos.private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i ansible/inventory ansible/node-centos-init-users.yaml -v
      ansible-playbook -i ansible/inventory ansible/node-centos-init-deadline.yaml -v
      ansible-playbook -i ansible/inventory ansible/node-centos-mounts.yaml -v
      ansible-playbook -i ansible/inventory ansible/node-centos-houdini.yaml -v
  EOT
  }
}

resource "random_id" "ami_unique_name" {
  keepers = {
    # Generate a new id each time we switch to a new instance id
    ami_id = "${aws_instance.node_centos.id}"
  }
  byte_length = 8
}

resource "aws_ami_from_instance" "node_centos" {
  depends_on         = ["null_resource.provision_node_centos"]
  name               = "node_centos_houdini_${aws_instance.node_centos.id}_${random_id.ami_unique_name.hex}"
  source_instance_id = "${aws_instance.node_centos.id}"
}

#wakeup a node after sleep
resource "null_resource" "start-node" {
  count = "${var.sleep ? 0 : 1}"

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos.id}"
  }
}

# resource "null_resource" "update_node" {
#   depends_on = ["aws_instance.node_centos"]

#   triggers {
#     instanceid = "${ aws_instance.node_centos.id }"
#   }

#   # todo: this wont provision unless vpn client routes to deadline db onsite are established.  read tf_aws_vpn notes for more configuration instructions.
#   #start vpn and generate a public key from private key.
#   provisioner "local-exec" {
#     command = <<EOT
#       #~/openvpn_config/startvpn.sh
#       ${path.module}/../tf_aws_openvpn/startvpn.sh
#       sleep 10
#       ping -c5 '${aws_instance.node_centos.private_ip}'
#       ssh-keygen -y -f ${var.local_key_path} > ~/temp_public_key
#   EOT
#   }

#   provisioner "file" {
#     connection {
#       user        = "centos"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     source      = "~/temp_public_key"
#     destination = "~/temp_public_key"
#   }

#   #remove public key from local system after copy to instance
#   provisioner "local-exec" {
#     command = <<EOT
#       rm -frv ~/temp_public_key
#   EOT
#   }

#   #provision the deadline user https://aws.amazon.com/premiumsupport/knowledge-center/new-user-accounts-linux-instance/
#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [<<EOT
# #provision the desired timezone.
# sudo cp ${var.time_zone_info_path_linux} /etc/localtime
# #create dealine user and password.  its important for the deadline user to have the same uid across any system where the user exists.
# sudo useradd -u ${var.deadline_user_uid} ${var.deadline_user}
# sudo passwd -d ${var.deadline_user}
# sudo mkdir /home/${var.deadline_user}/.ssh
# #sudo touch /home/${var.deadline_user}/.ssh/authorized_keys
# #move public key to defined authorised key, will replace anything in here if it exists.
# sudo mv ~/temp_public_key /home/${var.deadline_user}/.ssh/authorized_keys
# #set ownership, write permission for deadline user to folder, and read & write for owner to authorized keys file per amazon documentation.
# sudo chown -R ${var.deadline_user}:${var.deadline_user} /home/${var.deadline_user}/.ssh
# sudo chmod 700 /home/${var.deadline_user}/.ssh
# sudo chmod 600 /home/${var.deadline_user}/.ssh/authorized_keys
# EOT
#     ]
#   }

#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [<<EOT
# #give sudo priveledges after key is added
# sudo usermod -aG wheel ${var.deadline_user}
# sudo systemctl restart sshd.service
# sudo mkdir -p /opt/Thinkbox/certs

# sudo chown -R ${var.deadline_user}:${var.deadline_user} /opt/Thinkbox/certs
# sudo chmod 700 /opt/Thinkbox/certs
# echo 'uid is-'
# id -u ${var.deadline_user}
# echo 'gid is-'
# id -g ${var.deadline_user}
# EOT
#     ]
#   }

#   # now we can connect as the deadlineuser
#   connection {
#     user        = "${var.deadline_user}"
#     host        = "${aws_instance.node_centos.private_ip}"
#     private_key = "${var.private_key}"
#     type        = "ssh"
#     timeout     = "10m"
#   }

#   provisioner "file" {
#     source      = "${var.deadline_certificates_location}/Deadline10RemoteClient.pfx"
#     destination = "/opt/Thinkbox/certs/Deadline10RemoteClient.pfx"
#   }
#   #copy the deadline installer to the rendernode 
#   provisioner "file" {
#     source      = "${path.module}/file_package/${var.deadline_installers_filename}"
#     destination = "/var/tmp/${var.deadline_installers_filename}"
#   }
#   provisioner "remote-exec" {
#     connection {
#       user        = "${var.deadline_user}"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [
#       "sudo chmod 600 /opt/Thinkbox/certs/Deadline10RemoteClient.pfx",
#       "sudo chmod 700 /var/tmp/${var.deadline_installers_filename}",
#     ]
#   }
#   provisioner "remote-exec" {
#     connection {
#       user        = "centos"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [<<EOT
# #create dealine user and password
# #sudo useradd -u ${var.deadline_user_uid} ${var.deadline_user}
# #echo '${var.deadline_user_password}' | sudo passwd ${var.deadline_user} --stdin
# #give sudo priveledges
# #sudo usermod -aG wheel ${var.deadline_user}

# #read here to improve automounting mound cifs smb processes https://wiki.centos.org/TipsAndTricks/WindowsShares

# sudo mkdir /etc/deadline
# cat << EOF | sudo tee --append /etc/deadline/secret.txt
# username=${var.deadline_user}
# password=${var.deadline_user_password}
# EOF
# #ensure secret is readable only by root
# sudo chmod 400 /etc/deadline/secret.txt
# set -x
# ${var.skip_update ? " \n" : "sudo yum update -y"}

# #These are deadline dependencies
# sudo yum install redhat-lsb -y
# sudo yum install samba-client samba-common cifs-utils -y
# sudo yum install nfs-utils nfs-utils-lib -y
# sudo yum install epel-release -y
# sudo yum install nload nmap -y
# sudo yum install tree -y
# #bzip2 is needed to install deadline client.
# sudo yum install bzip2 -y
# #mount repository automatically over the vpn.  if you don't have routing configured, this won't work
# sudo mkdir -p /mnt/repo
# sudo mkdir -p ${var.softnas_mount_path}
# sudo mkdir /prod
# cat << EOF | sudo tee --append /etc/fstab
# ### DYNAMIC MOUNTS START ###
# //${var.deadline_samba_server_address}/DeadlineRepository /mnt/repo cifs    credentials=/etc/deadline/secret.txt,_netdev,uid=${var.deadline_user_uid} 0 0
# ${var.softnas_private_ip1}:${var.softnas_export_path} ${var.softnas_mount_path} nfs4 rsize=8192,wsize=8192,timeo=14,intr,_netdev 0 0
# ${var.softnas_mount_path} /prod none defaults,bind 0 0
# ### DYNAMIC MOUNTS END ###
# EOF
# cat << EOF | sudo tee --append /etc/hosts
# ${var.deadline_samba_server_address}  ${var.deadline_samba_server_hostname}
# EOF
# sudo mount -a
# sudo tree /mnt -L 3
# EOT
#     ]
#   }
#   provisioner "remote-exec" {
#     connection {
#       user        = "${var.deadline_user}"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [<<EOT
# set -x
# cd /var/tmp
# sudo ./${var.deadline_installers_filename} --mode unattended --debuglevel 2 --prefix ${var.deadline_prefix} --connectiontype Remote --noguimode true --licensemode UsageBased --launcherdaemon true --slavestartup 1 --daemonuser ${var.deadline_user} --enabletls true --tlsport 4433 --httpport 8080 --proxyrootdir ${var.deadline_proxy_root_dir} --proxycertificate ${var.deadline_proxy_certificate} --proxycertificatepassword ${var.deadline_proxy_certificate_password}
# EOT
#     ]
#   }

#   #sudo mount -t cifs -o username=${var.deadline_user},password=${var.deadline_user_password} //${var.deadline_samba_server_address}/DeadlineRepository /mnt/repo

#   #a reboot command in the shell of the instance will cause a terraform error.  We do it locally instead.
#   provisioner "local-exec" {
#     command = "aws ec2 reboot-instances --instance-ids ${aws_instance.node_centos.id} && sleep 60"
#   }
# }

# resource "null_resource" "install_houdini" {
#   depends_on = ["null_resource.update_node"]

#   triggers {
#     instanceid = "${ aws_instance.node_centos.id }"
#   }

#   provisioner "local-exec" {
#     command = <<EOT
#       #~/openvpn_config/startvpn.sh
#       ${path.module}/../tf_aws_openvpn/startvpn.sh
#       set -x
#       sleep 60
#       #ping ${aws_instance.node_centos.private_ip}
#   EOT
#   }

#   # now we can connect as the deadlineuser
#   connection {
#     user        = "${var.deadline_user}"
#     host        = "${aws_instance.node_centos.private_ip}"
#     private_key = "${var.private_key}"
#     type        = "ssh"
#     timeout     = "10m"
#   }

#   #copy the deadline installer to the rendernode 
#   provisioner "file" {
#     source      = "${path.module}/file_package/${var.houdini_installer_filename}"
#     destination = "/var/tmp/${var.houdini_installer_filename}"
#   }

#   provisioner "remote-exec" {
#     connection {
#       user        = "${var.deadline_user}"
#       host        = "${aws_instance.node_centos.private_ip}"
#       private_key = "${var.private_key}"
#       type        = "ssh"
#       timeout     = "10m"
#     }

#     inline = [<<EOT
# set -x
# sudo chmod 600 /var/tmp/${var.houdini_installer_filename}
# #these are needed for houdini to start https://rajivpandit.wordpress.com/category/fx-pipeline/page/8/
# sudo yum install -y mesa-libGLw
# sudo yum install -y libXp libXp-devel 
# cd /var/tmp
# sudo tar -xvf /var/tmp/${var.houdini_installer_filename}
# sudo mkdir houdini_installer
# sudo tar -xvf ${var.houdini_installer_filename} -C houdini_installer --strip-components 1
# cd houdini_installer
# #sudo ./houdini.install --auto-install --accept-EULA --install-houdini --install-license --no-local-licensing --install-hfs-symlink
# sudo ./houdini.install --auto-install --accept-EULA --install-houdini --no-local-licensing --install-hfs-symlink
# cd /opt/hfs17.0
# sudo sed -i '/licensingMode = sesinetd/s/^# //g' /opt/hfs17.0/houdini/Licensing.opt
# sudo cat /opt/hfs17.0/houdini/Licensing.opt
# /opt/hfs17.0/bin/hserver
# #source houdini_setup
# /opt/hfs17.0/bin/hserver -S ${var.houdini_license_server_address}
# EOT
#     ]
#   }
# }

# resource "random_id" "ami_unique_name" {
#   keepers = {
#     # Generate a new id each time we switch to a new instance id
#     ami_id = "${aws_instance.node_centos.id}"
#   }

#   byte_length = 8
# }

# resource "aws_ami_from_instance" "node_centos" {
#   depends_on         = ["null_resource.install_houdini"]
#   name               = "node_centos_houdini_${aws_instance.node_centos.id}_${random_id.ami_unique_name.hex}"
#   source_instance_id = "${aws_instance.node_centos.id}"
# }

resource "null_resource" "shutdown-node" {
  count = "${var.sleep ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.node_centos.id}"
  }
}
