#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "workstation_pcoip" {
  name        = "${var.name}"
  vpc_id      = "${var.vpc_id}"
  description = "Workstation - Teradici PCOIP security group"

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
    cidr_blocks = ["${var.remote_ip_cidr}", "${var.remote_subnet_cidr}"]
    description = "https"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = ["${var.remote_ip_cidr}", "${var.remote_subnet_cidr}"]
  }

  ingress {
    protocol    = "udp"
    from_port   = 4172
    to_port     = 4172
    cidr_blocks = ["${var.remote_ip_cidr}", "${var.remote_subnet_cidr}"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4172
    to_port     = 4172
    cidr_blocks = ["${var.remote_ip_cidr}", "${var.remote_subnet_cidr}"]
  }
    
  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = ["${var.remote_ip_cidr}", "${var.remote_subnet_cidr}"]
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

variable "houdini_license_server_address" {}
variable "private_subnets_cidr_blocks" {
  default = []
}

variable "openfirehawkserver" {}
variable "remote_subnet_cidr" {} 


resource "aws_security_group" "workstation_centos" {
  name        = "gateway_centos"
  vpc_id      = "${var.vpc_id}"
  description = "Workstation - Security group"

  tags {
    Name = "gateway_centos"
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


# You may wish to use a custom ami of your own creation.  insert the ami details below
variable "use_custom_ami" {
  default = false
}

variable "custom_ami" {
  default = ""
}

locals {
  skip_update = "${(var.skip_update || var.use_custom_ami)}"
}

variable "softnas_private_ip1" {
  default = []
}

variable "provision_softnas_volumes" {
  default = []
}

# This null resource creates a dependency on the completed volume provisioning from the softnas instance, and the existance of the bastion host.
resource "null_resource" "dependency_softnas_and_bastion" {
  triggers {
    softnas_private_ip1 = "${join(",", var.softnas_private_ip1)}"
    bastion_ip = "${var.bastion_ip}"
    provision_softnas_volumes = "${join(",", var.provision_softnas_volumes)}"
  }
}

resource "aws_instance" "workstation_pcoip" {
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  depends_on = ["null_resource.dependency_softnas_and_bastion"]
  count = "${var.site_mounts && var.workstation_enabled ? 1 : 0}"
  ami           = "${var.use_custom_ami ? var.custom_ami : lookup(var.ami_map, var.gateway_type)}"
  instance_type = "${lookup(var.instance_type_map, var.gateway_type)}"

  key_name  = "${var.key_name}"
  subnet_id = "${element(var.private_subnet_ids, count.index)}"

  vpc_security_group_ids = ["${aws_security_group.workstation_pcoip.id}", "${aws_security_group.workstation_centos.id}"]

  ebs_optimized = true
  root_block_device {
    volume_size = "30"
    volume_type = "gp2"
    delete_on_termination = true
  }

  tags {
    Name  = "workstation_centos"
    Route = "private"
    Role  = "workstation_centos"
  }

  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = "${self.private_ip}"
      private_key = "${var.private_key}"
      timeout     = "10m"
    }

    inline = [
      # Sleep 60 seconds until AMI is ready
      "sleep 60",
    ]
  }
}

variable "public_domain_name" {}

resource "null_resource" "workstation_pcoip" {
  depends_on = ["aws_instance.workstation_pcoip"]
  count = "${local.skip_update==false && var.site_mounts && var.workstation_enabled ? 1 : 0}"

  triggers {
    instanceid = "${ aws_instance.workstation_pcoip.id }"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = "${aws_instance.workstation_pcoip.private_ip}"
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
      # wait until ssh keys exist before commencing provisioning.
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 2",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.workstation_pcoip.private_ip}"
    ]
  }

  # add ssh keys and initialise users
  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.workstation_pcoip.private_ip} bastion_ip=${var.bastion_ip}"
  EOT
  }
  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = "${aws_instance.workstation_pcoip.private_ip}"
      bastion_host        = "${var.bastion_ip}"
      private_key         = "${var.private_key}"
      bastion_private_key = "${var.private_key}"
      type                = "ssh"
      timeout             = "10m"
    }
    # ensure connection is healthy
    inline = [
      "sleep 10",
      "set -x",
      "echo 'remote connection ok'"
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/node-centos-init-users.yaml -v --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.$TF_VAR_public_domain pcoip=true"
      # ansible-playbook -i ansible/inventory ansible/node-centos-init-deadline.yaml -v --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.$TF_VAR_public_domain pcoip=true"
      ansible-playbook -i ansible/inventory ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_workstation_centos variable_user=deadlineuser"
      ansible-playbook -i ansible/inventory ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_workstation_centos variable_user=centos"
      ansible-playbook -i ansible/inventory ansible/node-centos-mounts.yaml --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.$TF_VAR_public_domain pcoip=true" --skip-tags "local_install local_install_onsite_mounts" --tags "cloud_install"
      # to configure deadline scripts-
      ansible-playbook -i ansible/inventory ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=role_workstation_centos variable_user=centos"
      # configure houdini and submission scripts
      ansible-playbook -i ansible/inventory ansible/node-centos-houdini.yaml -v --extra-vars "variable_host=role_workstation_centos sesi_username=$TF_VAR_sesi_username sesi_password=$TF_VAR_sesi_password houdini_build=$TF_VAR_houdini_build firehawk_sync_source=$TF_VAR_firehawk_sync_source"
      ansible-playbook -i ansible/inventory ansible/node-centos-ffmpeg.yaml -v --extra-vars "variable_host=role_workstation_centos"
      # to recover from yum update breaking pcoip we reinstall the nvidia driver and dracut to fix pcoip.
      ansible-playbook -i ansible/inventory ansible/node-centos-pcoip-recover.yaml -v --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.$TF_VAR_public_domain pcoip=true"
  EOT
  }
  #after dracut, we reboot the instance locally.  A reboot command will otherwise cause a terraform error.
  provisioner "local-exec" {
    command = "${var.pcoip_sleep_after_creation ? "aws ec2 stop-instances --instance-ids ${aws_instance.workstation_pcoip.id}" : "aws ec2 reboot-instances --instance-ids ${aws_instance.workstation_pcoip.id}"}"
  }
}

resource "null_resource" "shutdown_workstation_pcoip" {
  count = "${var.sleep && var.site_mounts && var.workstation_enabled ? 1 : 0}"

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.workstation_pcoip.id}"
  }
}
