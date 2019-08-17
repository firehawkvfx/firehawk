#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

resource "aws_security_group" "node_centos" {
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
    description = "all incoming traffic from remote subnet range vpn dhcp"
  }

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr]
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
    cidr_blocks = concat([var.remote_subnet_cidr, var.remote_ip_cidr], var.private_subnets_cidr_blocks)
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

variable "provision_softnas_volumes" {
  default = []
}

resource "null_resource" "dependency_softnas_and_bastion" {
  triggers = {
    softnas_private_ip1       = join(",", var.softnas_private_ip1)
    bastion_ip                = var.bastion_ip
    provision_softnas_volumes = join(",", var.provision_softnas_volumes)
  }
}

resource "aws_instance" "node_centos" {
  count      = var.site_mounts ? 1 : 0
  depends_on = [null_resource.dependency_softnas_and_bastion]

  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  ami           = var.use_custom_ami ? var.custom_ami : var.ami_map[var.region]
  instance_type = var.instance_type

  #ebs_optimized = true

  root_block_device {
    volume_size = "16"
    volume_type = "standard"
  }
  key_name               = var.key_name
  subnet_id              = element(var.private_subnet_ids, count.index)
  vpc_security_group_ids = [aws_security_group.node_centos.id]
  tags = {
    Name  = "node_centos"
    Route = "private"
    Role  = "node_centos"
  }
}

resource "null_resource" "provision_node_centos" {
  count      = var.site_mounts ? 1 : 0
  depends_on = [aws_instance.node_centos]

  triggers = {
    instanceid = aws_instance.node_centos[0].id
  }

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.node_centos[0].private_ip
      bastion_host        = var.bastion_ip
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # First we install python remotely via the bastion to bootstrap the instance.  We also need this remote-exec to ensure the host is up.
    inline = [
      "sleep 10",
      "set -x",
      "sudo yum install -y python",
      "ssh-keyscan ${aws_instance.node_centos[0].private_ip}",
    ]
  }

  provisioner "local-exec" {
    command = <<EOT
      set -x
      cd /vagrant
      ansible-playbook -i ansible/inventory ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.node_centos[0].private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i ansible/inventory ansible/node-centos-init-users.yaml -v
      ansible-playbook -i ansible/inventory ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_node_centos variable_user=deadlineuser"
      ansible-playbook -i ansible/inventory ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_node_centos variable_user=centos"
      ansible-playbook -i ansible/inventory ansible/node-centos-mounts.yaml -v --skip-tags "local_install local_install_onsite_mounts" --tags "cloud_install"
      ansible-playbook -i ansible/inventory ansible/localworkstation-deadlineuser.yaml --tags "onsite-install" --extra-vars "variable_host=role_node_centos variable_user=centos"
      ansible-playbook -i ansible/inventory ansible/node-centos-houdini.yaml -v --extra-vars "sesi_username=$TF_VAR_sesi_username sesi_password=$TF_VAR_sesi_password houdini_build=$TF_VAR_houdini_build firehawk_sync_source=$TF_VAR_firehawk_sync_source"
      ansible-playbook -i ansible/inventory ansible/node-centos-ffmpeg.yaml -v
  
EOT

  }
}

resource "random_id" "ami_unique_name" {
  count = var.site_mounts ? 1 : 0
  keepers = {
    # Generate a new id each time we switch to a new instance id
    ami_id = aws_instance.node_centos[0].id
  }
  byte_length = 8
}

resource "aws_ami_from_instance" "node_centos" {
  count              = var.site_mounts ? 1 : 0
  depends_on         = [null_resource.provision_node_centos]
  name               = "node_centos_houdini_${aws_instance.node_centos[0].id}_${random_id.ami_unique_name[0].hex}"
  source_instance_id = aws_instance.node_centos[0].id
}

#wakeup a node after sleep
resource "null_resource" "start-node" {
  count = var.sleep == false && var.site_mounts ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }
}

resource "null_resource" "shutdown-node" {
  count = var.sleep && var.site_mounts ? 1 : 0

  provisioner "local-exec" {
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }
}

