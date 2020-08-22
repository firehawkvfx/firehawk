#----------------------------------------------------------------
# This module creates all resources necessary for a PCOIP instance in AWS
#----------------------------------------------------------------

locals {
  extra_tags = {
    route = "private"
    role  = "node_centos"
  }
}

resource "aws_security_group" "node_centos" {
  count       = var.aws_nodes_enabled ? 1 : 0

  name        = var.name
  vpc_id      = var.vpc_id
  description = "Centos And Teradici PCOIP security group"

  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "all incoming traffic from vpc"
  }

  # if all incoming from the onsite subnet is allowed, the rules below aren't required.

  # For OpenVPN Client Web Server & Admin Web UI

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibilty in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    cidr_blocks = var.private_subnets_cidr_blocks
    description = "ssh"
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
    cidr_blocks = var.private_subnets_cidr_blocks
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
    cidr_blocks = var.private_subnets_cidr_blocks
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
    cidr_blocks = var.private_subnets_cidr_blocks
    description = "Deadline RCS TLS HTTPS"
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_security_group" "node_centos_vpn" {
  count       = var.aws_nodes_enabled ? 1 : 0
  depends_on = [var.vpn_private_ip]

  name        = "vpn_${var.name}"
  vpc_id      = var.vpc_id
  description = "Centos VPN security group"

  tags = merge(map("Name", format("%s", "vpn_${var.name}")), var.common_tags, local.extra_tags)
}
resource "aws_security_group_rule" "remote_ip_all_incoming" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.remote_ip_cidr]
  description = "all incoming traffic from remote access ip"
}
resource "aws_security_group_rule" "vpn_cidr_all_incoming" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.vpn_cidr]
  description = "all incoming traffic from remote subnet range vpn dhcp"
}
resource "aws_security_group_rule" "remote_subnet_all_incoming" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [var.remote_subnet_cidr]
  description = "all incoming traffic from remote subnet range"
}
resource "aws_security_group_rule" "ssh" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 22
  to_port   = 22
  cidr_blocks = [var.remote_subnet_cidr, var.remote_ip_cidr]
  description = "ssh"
}
resource "aws_security_group_rule" "https" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [var.remote_ip_cidr]
  description = "https"
}
resource "aws_security_group_rule" "deadline_mongo" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 27100
  to_port   = 27100
  cidr_blocks = [var.remote_subnet_cidr]
  description = "DeadlineDB MongoDB"
}
resource "aws_security_group_rule" "deadline_rcs_tcp_http" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 8080
  to_port   = 8080
  cidr_blocks = [var.remote_subnet_cidr]
  description = "Deadline And Deadline RCS"
}
resource "aws_security_group_rule" "deadline_rcs_tcp_https" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol  = "tcp"
  from_port = 4433
  to_port   = 4433
  cidr_blocks = [var.remote_subnet_cidr]
  description = "Deadline RCS TLS HTTPS"
}
resource "aws_security_group_rule" "houdini_license_server_tcp" {
  count       = var.aws_nodes_enabled && var.houdini_license_server_address != "none" ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "tcp"
  from_port   = 1714
  to_port     = 1714
  cidr_blocks = ["${var.houdini_license_server_address}/32"]
  description = "Houdini license server"
}
resource "aws_security_group_rule" "houdini_license_server_udp" {
  count       = var.aws_nodes_enabled && var.houdini_license_server_address != "none" ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "udp"
  from_port   = 1714
  to_port     = 1714
  cidr_blocks = ["${var.houdini_license_server_address}/32"]
  description = "Houdini license server"
}
resource "aws_security_group_rule" "udp" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "udp"
  from_port   = 1194
  to_port     = 1194
  cidr_blocks = [var.remote_ip_cidr]
}
resource "aws_security_group_rule" "icmp" {
  count       = var.aws_nodes_enabled ? 1 : 0
  security_group_id = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  type              = "ingress"
  protocol    = "icmp"
  from_port   = 8
  to_port     = 0
  cidr_blocks = [var.remote_ip_cidr]
  description = "icmp"
}




variable "dependency" {
}

resource "null_resource" "dependency_deadlinedb" {
  triggers = {
    dependency = var.dependency
  }
}

data "aws_subnet" "private_subnet" {
  count = var.aws_nodes_enabled ? length(var.private_subnet_ids) : 0
  id    = var.private_subnet_ids[count.index]
}

variable "volume_size" {}

data "aws_ami_ids" "centos_v7" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["CentOS Linux 7 x86_64 HVM EBS ENA 2002_01"]
  }
}

variable "allow_prebuilt_node_centos_ami" {
  default = false
}

variable "node_centos_ami_option" { # Where multiple data aws_ami_ids queries are available, this allows us to select one.
  default = "centos_v7"
}

locals {
  keys = ["centos_v7"] # Where multiple data aws_ami_ids queries are available, this is the full list of options.
  empty_list = list("")
  values = ["${element( concat(data.aws_ami_ids.centos_v7.ids, local.empty_list ), 0 )}"] # the list of ami id's
  node_centos_consumption_map = zipmap( local.keys , local.values )
}

locals { # select the found ami to use based on the map lookup
  base_ami = lookup(local.node_centos_consumption_map, var.node_centos_ami_option)
}

data "aws_ami_ids" "prebuilt_node_centos_ami_list" { # search for a prebuilt tagged ami with the same base image.  if there is a match, it can be used instead, allowing us to skip provisioning.
  owners = ["self"]
  filter {
    name   = "tag:base_ami"
    values = ["${local.base_ami}"]
  }
  filter {
    name = "name"
    values = ["node_centos_prebuilt_*"]
  }
}

locals {
  prebuilt_node_centos_ami_list = data.aws_ami_ids.prebuilt_node_centos_ami_list.ids
  first_element = element( data.aws_ami_ids.prebuilt_node_centos_ami_list.*.ids, 0)
  mod_list = concat( local.prebuilt_node_centos_ami_list , list("") )
  aquired_ami      = "${element( local.mod_list , 0)}" # aquired ami will use the ami in the list if found, otherwise it will default to the original ami.
  use_prebuilt_node_centos_ami = var.allow_prebuilt_node_centos_ami && length(local.mod_list) > 1 ? true : false
  ami = local.use_prebuilt_node_centos_ami ? local.aquired_ami : local.base_ami
}

output "base_ami" {
  value = local.base_ami
}

output "prebuilt_node_centos_ami_list" {
  value = local.prebuilt_node_centos_ami_list
}

output "first_element" {
  value = local.first_element
}

output "aquired_ami" {
  value = local.aquired_ami
}

output "use_prebuilt_node_centos_ami" {
  value = local.use_prebuilt_node_centos_ami
}

output "ami" {
  value = local.ami
}

resource "aws_network_interface" "eth0" {
  count = var.aws_nodes_enabled ? 1 : 0
  subnet_id     = element(concat(var.private_subnet_ids, list("")), count.index)
                              
  private_ips     = [cidrhost(element(concat(data.aws_subnet.private_subnet, list("")), count.index).cidr_block, 20)]
  # private_ips     = [cidrhost("${data.aws_subnet.private_subnet[count.index].cidr_block}", 20)]

  tags = merge(map("Name", format("%s", "primary_network_interface_pipeid${lookup(var.common_tags, "pipelineid", "0")}")), var.common_tags, local.extra_tags)
}

locals {
  network_interface_id = element(concat(aws_network_interface.eth0.*.id, list("")), 0)
  instanceid = element(concat(aws_instance.node_centos.*.id, list("")), 0)
}

resource "aws_instance" "node_centos" {
  count                = var.aws_nodes_enabled ? 1 : 0
  iam_instance_profile = var.instance_profile_name

  ami           = var.use_custom_ami ? var.custom_ami : local.ami
  instance_type = var.instance_type

  ebs_optimized = true

  root_block_device {
    volume_size = var.volume_size
    volume_type = "gp2"
    delete_on_termination = true
  }

  network_interface {
    device_index         = 0
    network_interface_id = local.network_interface_id
    # delete_on_termination = true
  }

  key_name               = var.aws_key_name
  tags = merge(map("Name", format("%s", "node_centos_pipeid${lookup(var.common_tags, "pipelineid", "0")}")), var.common_tags, local.extra_tags)

  # cloud init resets network delay settings if configured outside of cloud-init
  user_data = <<USERDATA
#cloud-config
network:
 - config: disabled
USERDATA
}

resource "aws_network_interface_sg_attachment" "node_centos_sg_attachment" {
  count                = var.aws_nodes_enabled ? 1 : 0
  security_group_id    = element( concat( aws_security_group.node_centos.*.id, list("") ), 0)
  network_interface_id = local.network_interface_id
}

resource "aws_network_interface_sg_attachment" "node_centos_sg_attachment_vpn" { # This attachment occurs only after the vpn is available.  Prior to this, the attachment would be meaningless.
  count                = var.aws_nodes_enabled ? 1 : 0
  depends_on = [var.vpn_private_ip]
  security_group_id    = element( concat( aws_security_group.node_centos_vpn.*.id, list("") ), 0)
  network_interface_id = local.network_interface_id
}

resource "null_resource" "provision_node_centos" {
  count = var.aws_nodes_enabled ? 1 : 0
  depends_on = [aws_instance.node_centos, var.bastion_ip, aws_network_interface_sg_attachment.node_centos_sg_attachment ]
  
  triggers = {
    instanceid = local.instanceid
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }

  provisioner "remote-exec" {
    connection {
      user                = "centos"
      host                = aws_instance.node_centos[0].private_ip
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
      "sudo yum install -y python python3",
      "ssh-keyscan ${aws_instance.node_centos[0].private_ip}",
    ]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.node_centos[0].private_ip} bastion_ip=${var.bastion_ip}"; exit_test

      # if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
      #   # check db
      #   echo "test db centos 1"
      #   ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      # fi

      # ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "variable_host=firehawkgateway variable_user=deployuser private_ip=${aws_instance.node_centos[0].private_ip} bastion_ip=${var.bastion_ip}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=node0 host_ip=${aws_instance.node_centos[0].private_ip} group_name=role_node_centos insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_aws_private_key_path python_interpreter='/usr/bin/python3' package_python_interpreter='/usr/bin/python2.7'"; exit_test

      # ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-init-users.yaml -v --extra-vars "set_hostname=false"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_init_pip.yaml -v --extra-vars "variable_host=role_node_centos variable_connect_as_user=centos"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_node_centos variable_connect_as_user=centos variable_user=deployuser variable_uid=$TF_VAR_deployuser_uid set_selinux=disabled"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_node_centos variable_connect_as_user=centos variable_user=deadlineuser set_selinux=disabled"; exit_test

      # install cli for centos user, and lustre packages
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws_cli_ec2_install.yaml -v --extra-vars "variable_host=role_node_centos variable_user=centos reboot_after_lustre_install=true" --skip-tags "user_access"; exit_test

      # install cli for deadlineuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws_cli_ec2_install.yaml -v --extra-vars "variable_host=role_node_centos variable_user=centos variable_become_user=deadlineuser" --skip-tags "user_access"; exit_test
EOT

  }
}

resource "null_resource" "install_houdini" {
  count = var.aws_nodes_enabled ? 1 : 0

  depends_on = [ null_resource.provision_node_centos ]

  triggers = {
    instanceid = local.instanceid
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id} # ensure instance is started

      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "houdini_build=$TF_VAR_houdini_build" --tags "install_houdini"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v; exit_test
      fi
EOT

  }
}

resource "null_resource" "install_deadline_worker" {
  count = var.aws_nodes_enabled ? 1 : 0

  depends_on = [ null_resource.provision_node_centos, null_resource.dependency_deadlinedb, aws_network_interface_sg_attachment.node_centos_sg_attachment_vpn, null_resource.install_houdini, var.vpn_private_ip ]

  triggers = {
    instanceid = local.instanceid
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id} # ensure instance is started

      if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
        # check db
        echo "test db centos 1"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        echo "Install deadline worker on remote node"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-worker-install.yaml -v --skip-tags "multi-slave" --extra-vars "variable_host=role_node_centos variable_connect_as_user=centos variable_user=deadlineuser"; exit_test

        # check db
        echo "test db centos 6"
        ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
      fi

      if [[ "$TF_VAR_install_houdini" == true ]]; then
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/configure_hserver.yaml -v --extra-vars "houdini_build=$TF_VAR_houdini_build"; exit_test
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-ffmpeg.yaml -v; exit_test

        if [[ "$TF_VAR_install_deadline_worker" == true ]]; then
          ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_module.yaml -v --extra-vars "houdini_build=$TF_VAR_houdini_build" --tags "install_deadline_db"; exit_test
          echo "test db centos"
          ansible-playbook -i "$TF_VAR_inventory" ansible/deadline-db-check.yaml -v; exit_test
        fi
      fi

EOT

  }
}

resource "null_resource" "fsx_mounts" {
  count = ! var.sleep && var.aws_nodes_enabled && var.fsx_storage ? 1 : 0

  depends_on = [ var.fsx_private_ip, null_resource.install_deadline_worker ]

  triggers = {
    instanceid = local.instanceid
    fsx_private_ip = var.fsx_private_ip
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id} # ensure instance is started

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml -vvv --extra-vars "fsx_ip=${var.fsx_private_ip}" --skip-tags "local_install local_install_onsite_mounts" --tags "cloud_install"; exit_test
EOT

  }
}

resource "null_resource" "dependency_softnas" {
  
  count = var.softnas_storage ? 1 : 0

  triggers = {
    softnas_private_ip1             = join(",", var.softnas_private_ip1)
    provision_softnas_volumes       = join(",", var.provision_softnas_volumes)
    attach_local_mounts_after_start = join(",", var.attach_local_mounts_after_start)
  }
}

resource "null_resource" "softnas_mounts" {
  count = var.aws_nodes_enabled && var.softnas_storage ? 1 : 0

  depends_on = [ null_resource.dependency_softnas, null_resource.install_deadline_worker ]

  triggers = {
    instanceid = local.instanceid
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id} # ensure instance is started

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_volume_mounts.yaml -v --skip-tags "local_install local_install_onsite_mounts" --tags "cloud_install"; exit_test
EOT

  }
}

resource "null_resource" "houdini_test" {
  count = var.aws_nodes_enabled && ( var.softnas_storage || var.fsx_storage ) ? 1 : 0

  depends_on = [ null_resource.fsx_mounts, null_resource.softnas_mounts, null_resource.install_deadline_worker ]

  triggers = {
    instanceid = local.instanceid
    install_deadline_worker = var.install_deadline_worker
    install_houdini = var.install_houdini
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id} # ensure instance is started

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_openfirehawk_houdini_tools_sync.yaml -v --extra-vars "variable_user=deadlineuser"; exit_test # sync houdini tools after all mounts are available

      echo "TF_VAR_install_houdini: $TF_VAR_install_houdini"
      echo "TF_VAR_houdini_test_connection: $TF_VAR_houdini_test_connection"

      if [[ "$TF_VAR_install_houdini" == true ]] && [[ "$TF_VAR_houdini_test_connection" == true ]]; then
        # last step before building ami we run a unit test to ensure houdini runs.  We also cleanup any uneeded data afterwards, including tmp folders
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/houdini/houdini_unit_test.yaml -v --extra-vars "variable_user=deadlineuser execute=true"; exit_test
      fi

      # stop the instance to ensure ami is created from a stable state
      aws ec2 stop-instances --instance-ids ${aws_instance.node_centos[0].id}; exit_test
      aws ec2 wait instance-stopped --instance-ids ${aws_instance.node_centos[0].id}; exit_test
EOT

  }
}

# to replace the ami after further provisioning, use:
# terraform taint module.node.random_id.ami_unique_name[0]
# terraform taint aws_ami_from_instance.node_centos[0]
# or you can destroy the instance with
# terraform taint module.node.aws_instance.node_centos[0]
# and then terraform apply
# you will also need to delete existing spot fleets from the AWS console, and get deadline to restart pulse and perform housecleaning to roll out the new ami into future spot fleets.


resource "random_id" "ami_unique_name" {
  count = var.aws_nodes_enabled ? 1 : 0
  keepers = {
    # Generate a new id each time we switch to a new instance id
    ami_id = aws_instance.node_centos[0].id
    # Currently fsx wont have a persistent IP after wake, so the image is updated after the fstab file is updated with the new ip.
    fsx_mounts = null_resource.fsx_mounts[0].id
    fsx_private_ip = var.fsx_private_ip
  }
  byte_length = 8
}

resource "aws_ami_from_instance" "node_centos" {
  count              = var.aws_nodes_enabled ? 1 : 0
  depends_on         = [null_resource.provision_node_centos, random_id.ami_unique_name, null_resource.fsx_mounts, null_resource.softnas_mounts, null_resource.houdini_test]
  name               = "node_centos_houdini_${local.instanceid}_${random_id.ami_unique_name[0].hex}"
  source_instance_id = local.instanceid
  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

}

#wakeup after ami
resource "null_resource" "start-node-after-ami" {
  count = var.aws_nodes_enabled ? 1 : 0
  triggers = {
    ami_id = aws_ami_from_instance.node_centos[0].id
  }

  depends_on = [aws_ami_from_instance.node_centos]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }
}

# wakeup a node after sleep.  ensure the softnas instaqnce has finished creating its volumes otherwise mounts will not work - dependency_softnas
resource "null_resource" "start-node" {
  count      = ! var.sleep && var.aws_nodes_enabled && var.wakeable ? 1 : 0
  depends_on = [null_resource.dependency_softnas]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 start-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }
}

resource "null_resource" "shutdown-node" {
  count = var.sleep && var.aws_nodes_enabled ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 stop-instances --instance-ids ${aws_instance.node_centos[0].id}"
  }
}

