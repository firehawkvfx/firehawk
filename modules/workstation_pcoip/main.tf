#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

locals {
  extra_tags = {
    route = "private"
    role  = "workstation_centos"
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

resource "aws_security_group" "workstation_pcoip" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0

  name        = var.name
  vpc_id      = var.vpc_id
  description = "Workstation - Teradici PCOIP security group"

  tags = merge(map("Name", format("%s", "pcoip_${var.name}")), var.common_tags, local.extra_tags)

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
    cidr_blocks = [var.remote_ip_cidr, var.remote_subnet_cidr]
    description = "https"
  }
  ingress {
    protocol    = "udp"
    from_port   = 1194
    to_port     = 1194
    cidr_blocks = [var.remote_ip_cidr, var.remote_subnet_cidr]
  }

  ingress {
    protocol    = "udp"
    from_port   = 4172
    to_port     = 4172
    cidr_blocks = [var.remote_ip_cidr, var.remote_subnet_cidr]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 4172
    to_port     = 4172
    cidr_blocks = [var.remote_ip_cidr, var.remote_subnet_cidr]
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_ip_cidr, var.remote_subnet_cidr]
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

resource "aws_security_group" "workstation_centos" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0

  name        = "gateway_centos_${var.name}"
  vpc_id      = var.vpc_id
  description = "Workstation - Security group"

  tags = merge(map("Name", format("%s", "gateway_centos_${var.name}")), var.common_tags, local.extra_tags)

}
resource "aws_security_group_rule" "vpc_all_incoming" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.vpc_cidr]
  description = "all incoming traffic from vpc"
}
resource "aws_security_group_rule" "remote_ip_all_incoming" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.remote_ip_cidr]
  description = "all incoming traffic from remote access ip"
}
resource "aws_security_group_rule" "vpn_cidr_all_incoming" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.vpn_cidr]
  description = "all incoming traffic from remote subnet range"
}
resource "aws_security_group_rule" "deadline_db_all_incoming" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["${var.openfirehawkserver}/32"]
  description = "Deadline DB"
}
resource "aws_security_group_rule" "ssh" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 22
  to_port   = 22
  cidr_blocks = concat([var.remote_subnet_cidr, var.remote_ip_cidr], var.private_subnets_cidr_blocks)
  description = "ssh"
}
resource "aws_security_group_rule" "remote_ip_https" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [var.remote_ip_cidr]
  description = "https"
}
resource "aws_security_group_rule" "deadline_mongo" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 27100
  to_port   = 27100
  cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
  description = "DeadlineDB MongoDB"
}
resource "aws_security_group_rule" "deadline_rcs_http" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 8080
  to_port   = 8080
  cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
  description = "Deadline And Deadline RCS"
}
resource "aws_security_group_rule" "deadline_rcs_https" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 4433
  to_port   = 4433
  cidr_blocks = concat([var.remote_subnet_cidr], var.private_subnets_cidr_blocks)
  description = "Deadline RCS TLS HTTPS"
}
resource "aws_security_group_rule" "remote_ip_udp" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "udp"
  from_port   = 1194
  to_port     = 1194
  cidr_blocks = [var.remote_ip_cidr]
}
resource "aws_security_group_rule" "remote_ip_icmp" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "icmp"
  from_port   = 8
  to_port     = 0
  cidr_blocks = [var.remote_ip_cidr]
  description = "icmp"
}
resource "aws_security_group_rule" "all_outgoing" {
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
  description = "all outgoing traffic"
}
resource "aws_security_group_rule" "houdini_lincense_server_all_incoming" {
  count         = var.aws_nodes_enabled && var.workstation_enabled && var.houdini_license_server_address != "none" ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["${var.houdini_license_server_address}/32"]
  description = "Houdini License Server"
}
resource "aws_security_group_rule" "houdini_license_server_tcp" {
  count         = var.aws_nodes_enabled && var.workstation_enabled && var.houdini_license_server_address != "none" ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "tcp"
  from_port   = 1714
  to_port     = 1714
  cidr_blocks = ["${var.houdini_license_server_address}/32"]
  description = "Houdini license server"
}
resource "aws_security_group_rule" "houdini_license_server_udp" {
  count         = var.aws_nodes_enabled && var.workstation_enabled && var.houdini_license_server_address != "none" ? 1 : 0
  security_group_id = element( concat( aws_security_group.workstation_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "udp"
  from_port   = 1714
  to_port     = 1714
  cidr_blocks = ["${var.houdini_license_server_address}/32"]
  description = "Houdini license server"
}


variable "provision_softnas_volumes" {
  default = []
}

variable "attach_local_mounts_after_start" {
  default = []
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

variable "softnas_private_ip1" {
  default = []
}

# This null resource creates a dependency on the completed volume provisioning from the softnas instance, and the existance of the bastion host.
resource "null_resource" "dependency_softnas_and_bastion" {
  triggers = {
    softnas_private_ip1             = join(",", var.softnas_private_ip1)
    bastion_ip                      = var.bastion_ip
    provision_softnas_volumes       = join(",", var.provision_softnas_volumes)
    attach_local_mounts_after_start = join(",", var.attach_local_mounts_after_start)
  }
}

variable "dependency" {
}

resource "null_resource" "dependency_deadlinedb" {
  triggers = {
    dependency = var.dependency
  }
}

# These filters below aquire the ami for your region.  If they are not working in your region try running:
# aws ec2 describe-images --image-ids {image id}
# and then progress to filtering from that information instead of the image id:
# aws ec2 describe-images --filters "Name=name,Values=OpenVPN Access Server 2.7.5-*"
# ... and update the filters appropriately
# We dont use image id's directly because they dont work in multiple regions.
data "aws_ami" "pcoip_ami" {
  count = 1
  most_recent      = true
  owners = ["679593333241"] # the account id
  filter {
    name   = "name"
    values = ["graphics-agent-centos-7-aws-market-*-b1758282-066c-42d6-820c-0ddfe8d07132-*"] # the * replaces part of the serial that varies by region.
  }
}

variable "allow_prebuilt_teradici_pcoip_ami" {
  default = false
}

variable "teradici_pcoip_ami_option" { # Where multiple data aws_ami queries are available, this allows us to select one.
  default = "pcoip_ami"
}

locals {
  keys = ["pcoip_ami"] # Where multiple data aws_ami queries are available, this is the full list of options.
  empty_list = list("")
  values = ["${element( concat(data.aws_ami.pcoip_ami.*.id, local.empty_list ), 0 )}"] # the list of ami id's
  teradici_pcoip_consumption_map = zipmap( local.keys , local.values )
}

locals { # select the found ami to use based on the map lookup
  base_ami = lookup(local.teradici_pcoip_consumption_map, var.teradici_pcoip_ami_option)
}

data "aws_ami_ids" "prebuilt_teradici_pcoip_ami_list" { # search for a prebuilt tagged ami with the same base image.  if there is a match, it can be used instead, allowing us to skip provisioning.
  owners = ["self"]
  filter {
    name   = "tag:base_ami"
    values = ["${local.base_ami}"]
  }
  filter {
    name = "name"
    values = ["teradici_pcoip_prebuilt_*"]
  }
}

locals {
  prebuilt_teradici_pcoip_ami_list = data.aws_ami_ids.prebuilt_teradici_pcoip_ami_list.ids
  first_element = element( data.aws_ami_ids.prebuilt_teradici_pcoip_ami_list.*.ids, 0)
  mod_list = concat( local.prebuilt_teradici_pcoip_ami_list , list("") )
  aquired_ami      = "${element( local.mod_list , 0)}" # aquired ami will use the ami in the list if found, otherwise it will default to the original ami.
  use_prebuilt_teradici_pcoip_ami = var.allow_prebuilt_teradici_pcoip_ami && length(local.mod_list) > 1 ? true : false
  ami = local.use_prebuilt_teradici_pcoip_ami ? local.aquired_ami : local.base_ami
}

output "base_ami" {
  value = local.base_ami
}

output "prebuilt_teradici_pcoip_ami_list" {
  value = local.prebuilt_teradici_pcoip_ami_list
}

output "first_element" {
  value = local.first_element
}

output "aquired_ami" {
  value = local.aquired_ami
}

output "use_prebuilt_teradici_pcoip_ami" {
  value = local.use_prebuilt_teradici_pcoip_ami
}

output "ami" {
  value = local.ami
}


resource "aws_instance" "workstation_pcoip" {
  #instance type and ami are determined by the gateway type variable for if you want a graphical or non graphical instance.
  depends_on    = [null_resource.dependency_softnas_and_bastion]
  count         = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  ami           = var.use_custom_ami ? var.custom_ami : local.ami
  iam_instance_profile = var.instance_profile_name
  instance_type = var.instance_type_map[var.gateway_type]

  key_name  = var.aws_key_name
  subnet_id = element(concat(var.private_subnet_ids, list("")), count.index)

  vpc_security_group_ids = concat(aws_security_group.workstation_pcoip.*.id, aws_security_group.workstation_centos.*.id)

  ebs_optimized = true
  root_block_device {
    volume_size           = "30"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = merge(map("Name", format("%s", "${var.name}")), var.common_tags, local.extra_tags)

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "centos"
      host        = self.private_ip
      private_key = var.private_key
      timeout     = "10m"
    }

    inline = [
      "sleep 60",
    ]
  }
}

variable "public_domain_name" {
}

resource "null_resource" "workstation_pcoip" {
  depends_on = [aws_instance.workstation_pcoip]
  count      = ! local.skip_update && var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0

  triggers = {
    instanceid = aws_instance.workstation_pcoip[0].id
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.workstation_pcoip[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # First we install python remotely via the bastion to bootstrap the instance.  We also need this remote-exec to ensure the host is up.
    inline = [
      "sleep 10",
      "export SHOWCOMMANDS=true; set -x",
      "sudo cloud-init status --wait",
      "sudo yum install -y python",
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 2",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.workstation_pcoip[0].private_ip}",
    ]
  }

  # add ssh keys and initialise users
  # add ssh keys and initialise users
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.workstation_pcoip[0].private_ip} bastion_ip=${var.bastion_ip}"
      # ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=firehawkgateway variable_user=deployuser private_ip=${aws_instance.workstation_pcoip[0].private_ip} bastion_ip=${var.bastion_ip}"
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=cloud_workstation1.firehawkvfx.com host_ip=${aws_instance.workstation_pcoip[0].private_ip} group_name=role_workstation_centos insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_aws_private_key_path"

EOT

  }
  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.workstation_pcoip[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # ensure connection is healthy
    inline = [
      "sleep 10",
      "export SHOWCOMMANDS=true; set -x",
      "echo 'remote connection ok'",
    ]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh

      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_init_pip.yaml -v --extra-vars "variable_host=role_workstation_centos variable_connect_as_user=centos"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_workstation_centos variable_connect_as_user=centos hostname=cloud_workstation1.firehawkvfx.com pcoip=true set_hostname=true variable_user=deployuser variable_uid=$TF_VAR_deployuser_uid set_selinux=disabled"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_workstation_centos variable_connect_as_user=centos variable_user=deadlineuser pcoip=true set_selinux=disabled"; exit_test
      
      # install cli for centos user
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_workstation_centos variable_user=centos" --skip-tags "user_access"; exit_test
      # install cli for deadlineuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2-install.yaml -v --extra-vars "variable_host=role_workstation_centos variable_user=centos variable_become_user=deadlineuser" --skip-tags "user_access"; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.firehawkvfx.com pcoip=true" --skip-tags "local_install local_install_onsite_mounts"; exit_test

      ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-pcoip-recover.yaml -v --extra-vars "variable_host=role_workstation_centos hostname=cloud_workstation1.firehawkvfx.com pcoip=true"; exit_test
EOT
  } # If possible to test ui connection, it should be done here, and if not working, also before this provisioning step, since a yum update will break PCOIP.

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 reboot-instances --instance-ids ${aws_instance.workstation_pcoip[0].id}"
  }
}

resource "null_resource" "install_houdini" {
  count      = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0

  depends_on = [ null_resource.workstation_pcoip ]

  triggers = {
    instanceid = aws_instance.workstation_pcoip[0].id
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.workstation_pcoip[0].id} # ensure instance is started

      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "variable_host=role_workstation_centos houdini_build=$TF_VAR_houdini_build" --tags "install_houdini"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v --extra-vars "variable_host=role_workstation_centos"; exit_test
      fi
EOT
  }
}

resource "null_resource" "install_deadline_worker" {
  count      = var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0
  # will need to mirror node centos aws_network_interface_sg_attachment.node_centos_sg_attachment_vpn if provisioning immediately asynchronously.
  depends_on = [ null_resource.workstation_pcoip, null_resource.dependency_deadlinedb, null_resource.install_houdini, var.vpn_private_ip ]

  triggers = {
    instanceid = aws_instance.workstation_pcoip[0].id
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.workstation_pcoip[0].id} # ensure instance is started

      if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
        # check db
        echo "test db centos 1"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        echo "Install deadline worker on remote node"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-worker-install.yaml -v --skip-tags "multi-slave" --extra-vars "variable_host=role_workstation_centos variable_connect_as_user=centos variable_user=deadlineuser"; exit_test

        # check db
        echo "test db centos 6"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      fi

      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/configure_hserver.yaml -v --extra-vars "variable_host=role_workstation_centos houdini_build=$TF_VAR_houdini_build"; exit_test
        # ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v; exit_test

        if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
          ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "variable_host=role_workstation_centos houdini_build=$TF_VAR_houdini_build" --tags "install_deadline_db"; exit_test
          echo "test db centos"
          ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        fi
      fi
EOT
  }
}


resource "null_resource" "shutdown_workstation_pcoip" {
  count = var.sleep && var.aws_nodes_enabled && var.workstation_enabled ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.workstation_pcoip[0].id}"
  }
}

