resource "aws_iam_role" "softnas_role" {
  name = local.softnas_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Action": [
              "sts:AssumeRole"
          ],
          "Principal": {
              "Service": [
                  "ec2.amazonaws.com"
              ]
          },
          "Effect": "Allow"
      }
  ]
}
EOF

}

resource "aws_iam_instance_profile" "softnas_profile" {
  name = local.softnas_role_name
  role = aws_iam_role.softnas_role.name
}

resource "aws_iam_role_policy_attachment" "softnas_ssm_attach" {
  role       = aws_iam_role.softnas_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_iam_role_policy" "softnas_policy" {
  name = local.softnas_role_name
  role = aws_iam_role.softnas_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "Stmt1444200186000",
          "Effect": "Allow",
          "Action": [
              "ec2:ModifyInstanceAttribute",
              "ec2:DescribeInstances",
              "ec2:CreateVolume",
              "ec2:DeleteVolume",
              "ec2:CreateSnapshot",
              "ec2:DeleteSnapshot",
              "ec2:CreateTags",
              "ec2:DeleteTags",
              "ec2:AttachVolume",
              "ec2:DetachVolume",
              "ec2:DescribeInstances",
              "ec2:DescribeVolumes",
              "ec2:DescribeSnapshots",
              "aws-marketplace:MeterUsage",
              "ec2:DescribeRouteTables",
              "ec2:DescribeAddresses",
              "ec2:DescribeTags",
              "ec2:DescribeInstances",
              "ec2:ModifyNetworkInterfaceAttribute",
              "ec2:ReplaceRoute",
              "ec2:CreateRoute",
              "ec2:DeleteRoute",
              "ec2:AssociateAddress",
              "ec2:DisassociateAddress",
              "s3:CreateBucket",
              "s3:Delete*",
              "s3:Get*",
              "s3:List*",
              "s3:Put*"
          ],
          "Resource": [
              "*"
          ]
      }
  ]
}
EOF

}

locals {
  softnas_role_name = "SoftNAS_HA_IAM_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  softnas_mode_ami = "${var.softnas_mode}_${var.aws_region}"
  name = "softnas_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  extra_tags = {
    role = "softnas"
    route = "private"
  }
}

resource "random_uuid" "test" {
}

resource "aws_security_group" "softnas" {
  count = var.softnas_storage ? 1 : 0

  name        = "softnas_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "SoftNAS security group"
  tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "DNS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "DNS"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "icmp"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "ssh"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "https"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [ var.vpc_cidr ]
    description = "all incoming traffic from remote vpn"
  }

  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = [ var.vpc_cidr ]
    description = ""
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [ var.vpc_cidr ]
    description = "NFS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [ var.vpc_cidr ]
    description = "NFS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [ var.vpc_cidr ]
    description = "rquotad, nlockmgr, mountd, status"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

resource "aws_security_group" "softnas_vpn" {
  count = var.softnas_storage ? 1 : 0
  depends_on = [var.vpn_private_ip]

  name        = "softnas_vpn_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "SoftNAS VPN security group for remote subnet"

  tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "all incoming traffic"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 53
    to_port     = 53
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "DNS"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "icmp"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "ssh"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "https"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "all incoming traffic from remote vpn"
  }

  ingress {
    protocol    = "udp"
    from_port   = 49152
    to_port     = 65535
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = ""
  }

  ingress {
    protocol    = "tcp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "udp"
    from_port   = 111
    to_port     = 111
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "NFS"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 892
    to_port     = 892
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2010
    to_port     = 2010
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2014
    to_port     = 2014
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  ingress {
    protocol    = "udp"
    from_port   = 2049
    to_port     = 2049
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "rquotad, nlockmgr, mountd, status"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    description = "all outgoing traffic"
  }
}

variable "allow_prebuilt_softnas_ami" {
}

data "aws_ami_ids" "burrst_softnas" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["SoftNAS - 4.4.3"]
  }
}

data "aws_ami_ids" "burrst_softnas_byol" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["SoftNAS BYOL - 4.4.3"]
  }
}

variable "softnas_ami_option" {
  default = "burrst_softnas"
}

locals {
  keys = ["burrst_softnas","burrst_softnas_byol"]
  empty_list = list("")
  values = ["${element( concat(data.aws_ami_ids.burrst_softnas.ids, local.empty_list ), 0 )}", "${element( concat( data.aws_ami_ids.burrst_softnas_byol.ids, local.empty_list ), 0 )}"]
  softnas_platinum_consumption_map = zipmap( local.keys , local.values )
}

locals { # select the found ami to use based on the map lookup
  base_ami = lookup(local.softnas_platinum_consumption_map, var.softnas_ami_option)
}

data "aws_ami_ids" "prebuilt_softnas_ami_list" { # search for a prebuilt tagged ami with the same base image.  if there is a match, it can be used instead, allowing us to skip updates.
  owners = ["self"]
  filter {
    name   = "tag:base_ami"
    values = ["${local.base_ami}"]
  }
  # filter {
  #   name   = "tag:base_instance_type"
  #   values = ["${local.instance_type}"] # If instance type is not the same as used to build ami there may be problems, so we tag the ami with the same instance type.
  # }
  filter {
    name = "name"
    values = ["softnas_prebuilt_*"]
  }
}

locals {
  prebuilt_softnas_ami_list = data.aws_ami_ids.prebuilt_softnas_ami_list.ids
  first_element = element( data.aws_ami_ids.prebuilt_softnas_ami_list.*.ids, 0)
  mod_list = concat( local.prebuilt_softnas_ami_list , list("") )
  aquired_ami      = "${element( local.mod_list , 0)}" # aquired ami will use the ami in the list if found, otherwise it will default to the original ami.
  use_prebuilt_softnas_ami = var.allow_prebuilt_softnas_ami && length(local.mod_list) > 1 ? true : false
  ami = local.use_prebuilt_softnas_ami ? local.aquired_ami : local.base_ami
  instance_type = var.instance_type[var.softnas_mode]
}

output "base_ami" {
  value = local.base_ami
}

output "prebuilt_softnas_ami_list" {
  value = local.prebuilt_softnas_ami_list
}

output "first_element" {
  value = local.first_element
}

output "aquired_ami" {
  value = local.aquired_ami
}

output "use_prebuilt_softnas_ami" {
  value = local.use_prebuilt_softnas_ami
}

output "ami" {
  value = local.ami
}

resource "aws_network_interface" "nas1eth0" {
  count = var.softnas_storage ? 1 : 0
  subnet_id     = element(concat(var.private_subnets, list("")), 0)
  private_ips     = [var.softnas1_private_ip1]

  tags = merge(map("Name", format("%s", "primary_network_interface_pipeid${lookup(var.common_tags, "pipelineid", "0")}")), var.common_tags, local.extra_tags)
}

locals {
  network_interface_id = element(concat(aws_network_interface.nas1eth0.*.id, list("")), 0)
}

resource "aws_instance" "softnas1" {
  count = var.softnas_storage ? 1 : 0
  depends_on = [ aws_instance.softnas1 ]

  ami   = local.ami

  instance_type = local.instance_type

  ebs_optimized = true

  iam_instance_profile = aws_iam_instance_profile.softnas_profile.name

  network_interface {
    device_index         = 0
    network_interface_id = local.network_interface_id
    # delete_on_termination = true
  }

  root_block_device {
    volume_size = "100"
    volume_type = "gp2"
    delete_on_termination = true
    # if specifying a snapshot, do not specify encryption.
    #encryption = false
  }

  key_name = var.key_name
  user_data = <<USERDATA
#cloud-config
hostname: nas1
fqdn: nas1
manage_etc_hosts: false
USERDATA

  tags = merge(map("Name", format("%s", local.name)), var.common_tags, local.extra_tags)
}

resource "aws_network_interface_sg_attachment" "sg_attachment" {
  count = var.softnas_storage ? 1 : 0
  security_group_id    = element( concat( aws_security_group.softnas.*.id, list("") ), 0)
  network_interface_id = local.network_interface_id
}

resource "aws_network_interface_sg_attachment" "sg_attachment_vpn" { # This attachment occurs only after the vpn is available.  Prior to this, the attachment would be meaningless.
  count = var.softnas_storage ? 1 : 0
  depends_on = [var.vpn_private_ip]
  security_group_id    = element( concat( aws_security_group.softnas_vpn.*.id, list("") ), 0)
  network_interface_id = local.network_interface_id
}

# When using ssd tiering, you must manually create the ebs volumes and specify the ebs id's in your secrets.  Then they can be locally restored automatically and attached to the instance.

locals {
  id = element(concat(aws_instance.softnas1.*.id, list("")), 0)
  provision_softnas         = local.use_prebuilt_softnas_ami ? false : true # when using an aquired ami, we will not create another ami as this would replace it.
  skip_packages = local.use_prebuilt_softnas_ami # when using an aquired ami, we will not create another ami as this would replace it.
  private_ip = "${element(concat(aws_instance.softnas1.*.private_ip, list("")), 0)}"
}

resource "null_resource" "wait_softnas_up" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [ aws_instance.softnas1, local.private_ip ]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}",
    skip_update = var.skip_update,
    ami = local.ami,
  }

  # some time is required before the ecdsa key file exists.
  # some time is required before the ecdsa key file exists.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # sleep 300 is required because ecdsa key wont exist for a while, and you can't continue without it.
    inline = [
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 10",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.softnas1[0].private_ip}",
      "which python",
      "python --version",
      "if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then sudo rm -fv /etc/udev/rules.d/70-persistent-net.rules; fi", # this file may need to be removed in order to create an image that will work.
    ]
  }
}

resource "random_id" "ami_init_unique_name" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.wait_softnas_up,
    local.ami,
  ]
  keepers = { # Generate a new id each time we switch to a new instance id, or the base_ami cahanges.  this doesn't mean a new ami is generated.
    ami_id = local.id
    base_ami = local.base_ami
    ami = local.ami
  }
  byte_length = 8
}

# This init ami is for testing to verify the base image can be used with other instances.  In some versions of softnas this stage has failed.
resource "null_resource" "create_ami_init" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.wait_softnas_up,
  ]
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    base_ami = local.base_ami
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = ["echo 'booted'"]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      # ami creation is unnecesary since softnas ami update.  will be needed in future again if softnas updates slow down deployment.
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-ami.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} ami_name=softnas_init_${local.ami} base_ami=${local.ami} description=softnas1_${aws_instance.softnas1.*.id[count.index]}_${random_id.ami_init_unique_name[0].hex}"
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}
EOT
  }
}
locals {
  create_ami_resource_id = concat(null_resource.create_ami_init.*.id, list(""))
}


resource "null_resource" "provision_softnas" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [aws_instance.softnas1, null_resource.wait_softnas_up, null_resource.create_ami_init, var.init_aws_local_workstation]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    skip_update = var.skip_update
    ami = local.ami
  }

  # some time is required before the ecdsa key file exists.
  # some time is required before the ecdsa key file exists.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    # sleep 300 is required because ecdsa key wont exist for a while, and you can't continue without it.
    inline = [
      "while [ ! -f /etc/ssh/ssh_host_ecdsa_key.pub ]",
      "do",
      "  sleep 10",
      "done",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "cat /etc/ssh/ssh_host_rsa_key.pub",
      "cat /etc/ssh/ssh_host_ecdsa_key.pub",
      "ssh-keyscan ${aws_instance.softnas1[0].private_ip}",
      "which python",
      "python --version",
      "if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then sudo rm -fv /etc/udev/rules.d/70-persistent-net.rules; fi", # this file may need to be removed in order to create an image that will work.
    ]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-private-host.yaml -v --extra-vars "private_ip=${aws_instance.softnas1[0].private_ip} bastion_ip=${var.bastion_ip}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=softnas0 host_ip=${aws_instance.softnas1[0].private_ip} group_name=role_softnas insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_local_key_path"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/get-file.yaml -v --extra-vars "source=/var/log/cloud-init-output.log dest=$TF_VAR_firehawk_path/tmp/log/cloud-init-output-softnas.log variable_user=ec2-user variable_host=role_softnas"; exit_test

      # Initialise
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_init_pip.yaml -v --extra-vars "variable_host=role_softnas variable_connect_as_user=$TF_VAR_softnas_ssh_user skip_packages=${local.skip_packages}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_init.yaml -v --extra-vars "skip_packages=${local.skip_packages}"; exit_test

      # remove any mounts on local workstation first since they will have been broken if another softnas instance was just destroyed to create this one.
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        echo "ENSURE REMOTE MOUNTS ON LOCAL NODES ARE REMOVED BEFORE CREATING NEW VOLUME"
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
      if [[ "$TF_VAR_softnas_skip_update" == true ]]; then
        echo "...Skip softnas update"
      else
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_update.yaml -v; exit_test
        echo "Finished Update"
      fi
      # cli is only needed if sync operations with s3 will be run on this instance.
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli.yaml -v --extra-vars "variable_user=ec2-user variable_host=role_softnas"; exit_test
      # #ansible-playbook -i "$TF_VAR_inventory" ansible/aws-cli-ec2.yaml -v --extra-vars "variable_user=ec2-user variable_host=role_softnas"; exit_test
  
EOT

  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = ["echo 'booted after init'"]
  }
}

# when testing, the local can be set to disable ami creation in a dev environment only - for faster iteration.
locals {
  create_ami         = local.use_prebuilt_softnas_ami ? false : true # when using an aquired ami, we will not create another ami as this would replace it.
}

resource "random_id" "ami_unique_name" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.provision_softnas,
  ]
  keepers = { # Generate a new id each time we switch to a new instance id, or the base_ami cahanges.  this doesn't mean a new ami is generated.
    ami_id = local.id
    base_ami = local.base_ami
  }
  byte_length = 8
}

# At this point in time, AMI's created by terraform are destroyed with terraform destroy.  we desire the ami to be persistant for faster future redeployment, so we create the ami with ansible instead.
resource "null_resource" "create_ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0
  depends_on = [
    aws_instance.softnas1,
    null_resource.provision_softnas,
  ]
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    base_ami = local.base_ami
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = [
      "echo 'booted'",
      "if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then sudo rm -fv /etc/udev/rules.d/70-persistent-net.rules; fi", # this file may need to be removed in order to create an image that will work.
      ]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      ansible-playbook -i "$TF_VAR_inventory" ansible/aws-ami.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} ami_name=softnas_prebuilt_${local.ami} base_ami=${local.ami} description=softnas1_${aws_instance.softnas1.*.id[count.index]}_${random_id.ami_unique_name[0].hex} instance_type=${local.instance_type}"
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}
EOT
  }
}

# Start instance so that s3 disks can be attached
resource "null_resource" "start-softnas-after-create-ami" {
  count = local.create_ami && var.softnas_storage ? 1 : 0

  #depends_on         = ["aws_volume_attachment.softnas1_ebs_att"]
  depends_on = [
    null_resource.provision_softnas,
    null_resource.create_ami,
  ]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}"
  }
}

# If ebs volumes are attached, don't automatically import the pool. manual intervention may be required.
locals {
  import_pool = true
}

# Once an AMI is built above, then we test the connection to the instance via a bastion below.
# When connection to softnas is established, we know the instance has booted.  We continue to provision an s3 extender disk below.
# this creates an s3 bucket if it doesn't already exist.  if there is a bucket with the same disk_device number, same nas name, and same domain,
# then the existing bucket will be mounted instead and existing data wil be available.  you may need to login to the softnas web ui to import the existing pool and volume,
# but the disk should be mounted correctly.
# Domains can be used to differentiate dev environments from production.
# for example, dev.example.com vs prod.example.com are different namespaces for two different buckets with otherwise identical properties to coexist in the same aws account.
# if an existing bucket is detected, s3_disk_size_max_value and encrypt_s3 are overidden by the settings on the bucket, and commandline variables ignored.
# the s3 encryption password is stored in your encrypted vault in ansible/host_vars/all/vault

# IMPORTANT: if creating a new disk, the disk_device should be the next number available to the instance.
# eg if these are already moujnted, /dev/s3-0, /dev/s3-1, /dev/s3-2, then the disk_device for the next bucket should be "3".

output "softnas1_instanceid" {
  value = aws_instance.softnas1.*.id
}

output "softnas1_private_ip" {
  value = aws_instance.softnas1.*.private_ip
}

# there is currently too much activity here, but due to the way dependencies work in tf 0.11 its better to keep it in one block.
# in tf .12 we should split these up and handle dependencies properly.
resource "null_resource" "provision_softnas_volumes" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [
    null_resource.provision_softnas,
    null_resource.start-softnas-after-create-ami,
    null_resource.create_ami,
  ]

  # "null_resource.start-softnas-after-ebs-attach"
  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["echo 'booted'"]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      export common_tags='${ jsonencode( merge(var.common_tags, local.extra_tags) ) }'; exit_test
      echo "common_tags: $common_tags"

      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_softnas variable_connect_as_user=$TF_VAR_softnas_ssh_user variable_user=deployuser variable_uid=$TF_VAR_deployuser_uid"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/newuser_deadlineuser.yaml -v --extra-vars "variable_host=role_softnas variable_connect_as_user=$TF_VAR_softnas_ssh_user variable_user=deadlineuser"; exit_test

      # hotfix script to speed up instance start and shutdown
      # ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_install_acpid.yaml -v; exit_test

      # ensure all old mounts onsite are removed if they exist.
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        echo "CONFIGURE REMOTE MOUNTS ON LOCAL NODES"
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml -v --extra-vars "variable_host=workstation1 variable_user=deployuser hostname=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
      # mount all ebs disks before s3
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_check_able_to_stop.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_disk.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=attach"; exit_test
      # Although we start the instance in ansible, the aws cli can be more reliable to ensure this.
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
  
EOT

  }

  # connect to the instance again to ensure it has booted.
  # connect to the instance again to ensure it has booted.
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }

    inline = ["echo 'booted'"]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      # ensure volumes and pools exist after disks are ensured to exist.
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_pool.yaml -v; exit_test
      # ensure s3 disks exist and are mounted.  the s3 features are disabled currently in favour of migrating to using the aws cli and pdg to sync data
      # ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_s3_disk.yaml -v --extra-vars "pool_name=$(TF_VAR_envtier)pool0 volume_name=$(TF_VAR_envtier)volume0 disk_device=0 s3_disk_size_max_value=${var.s3_disk_size} encrypt_s3=true import_pool=${local.import_pool}"; exit_test
      # exports should be updated here.
      # if btier.json exists in /secrets/$(TF_VAR_envtier)/ebs-volumes/ then the tiers will be imported.
      # ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_backup_btier.yaml -v --extra-vars "restore=true"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_disk_update_exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
  
EOT

  }
}

output "provision_softnas_volumes" {
  value = null_resource.provision_softnas_volumes.*.id
}

# todo : need to report success at correct time after it has started.  see email from steven melnikov at softnas to check how to do this.

# wakeup a node after sleep
resource "null_resource" "start-softnas" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.provision_softnas_volumes]

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh

      export common_tags='${ jsonencode( merge(var.common_tags, local.extra_tags) ) }'; exit_test
      echo "common_tags: $common_tags"

      # create volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_disk.yaml --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=attach"; exit_test
      aws ec2 start-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
  
EOT

  }
}

resource "null_resource" "shutdown-softnas" {
  count = ( var.sleep && var.softnas_storage ) ? 1 : 0

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    #command = "aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.id}"
    command = <<EOT
      . /deployuser/scripts/exit_test.sh

      export common_tags='${ jsonencode( merge(var.common_tags, local.extra_tags) ) }'; exit_test
      echo "common_tags: $common_tags"

      aws ec2 stop-instances --instance-ids ${aws_instance.softnas1.*.id[count.index]}; exit_test
      # delete volatile storage
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_disk.yaml --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]} stop_softnas_instance=true mode=destroy"; exit_test
  
EOT

  }
}

resource "null_resource" "attach_local_mounts_after_start" {
  count      = ( !var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.start-softnas, var.vpn_private_ip, aws_network_interface_sg_attachment.sg_attachment_vpn] # when softnas mounts are attached to onsite network, we require the vpn to be up.

  #,"null_resource.mount_volumes_onsite"]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    startsoftnas = "${join(",", null_resource.start-softnas.*.id)}"
    remote_mounts_on_local = var.remote_mounts_on_local
  }
  provisioner "remote-exec" {
    connection {
      user                = var.softnas_ssh_user
      host                = aws_instance.softnas1[0].private_ip
      bastion_host        = var.bastion_ip
      bastion_user        = "centos"
      private_key         = var.private_key
      bastion_private_key = var.private_key
      type                = "ssh"
      timeout             = "10m"
    }
    inline = [
      "export SHOWCOMMANDS=true; set -x",
      "echo 'connection established'",
    ]
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x

      export common_tags='${ jsonencode( merge(var.common_tags, local.extra_tags) ) }'; exit_test
      echo "common_tags: $common_tags"

      echo "TF_VAR_remote_mounts_on_local= $TF_VAR_remote_mounts_on_local"
      # ensure routes on workstation exist
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        printf "\n$BLUE CONFIGURE REMOTE ROUTES ON LOCAL NODES $NC\n"
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-routes.yaml -v -v --extra-vars "variable_host=workstation1 variable_user=deployuser hostname=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key ethernet_device=$TF_VAR_workstation_ethernet_device"; exit_test
      fi
      # ensure volumes and pools exist after the disks were ensured to exist - this was done before starting instance.
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_pool.yaml -v; exit_test
      #ensure exports are correct
      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/softnas_ebs_disk_update_exports.yaml -v --extra-vars "instance_id=${aws_instance.softnas1.*.id[count.index]}"; exit_test
      # mount volumes to local site when softnas is started
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        printf "\n$BLUE CONFIGURE REMOTE MOUNTS ON LOCAL NODES $NC\n"
        # unmount volumes from local site - same as when softnas is shutdown, we need to ensure no mounts are present since existing mounts pointed to an incorrect environment will be wrong
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
        # now mount current volumes
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml -v -v --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
EOT
  }
}

output "attach_local_mounts_after_start" {
  value = null_resource.attach_local_mounts_after_start.*.id
}

resource "null_resource" "detach_local_mounts_after_stop" {
  count      = ( var.sleep && var.softnas_storage ) ? 1 : 0
  depends_on = [null_resource.shutdown-softnas, var.vpn_private_ip, aws_network_interface_sg_attachment.sg_attachment_vpn]

  triggers = {
    instanceid = "${join(",", aws_instance.softnas1.*.id)}"
    startsoftnas = "${join(",", null_resource.shutdown-softnas.*.id)}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x

      export common_tags='${ jsonencode( merge(var.common_tags, local.extra_tags) ) }'; exit_test
      echo "common_tags: $common_tags"

      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        # unmount volumes from local site when softnas is shutdown.
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/softnas/linux_volume_mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
  
EOT

  }
}

