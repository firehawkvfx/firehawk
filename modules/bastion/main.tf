#----------------------------------------------------------------
# This module creates all resources necessary for am Ansible Bastion instance in AWS
#----------------------------------------------------------------

variable "common_tags" {}

resource "aws_security_group" "bastion" {
  count       = var.create_vpc ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  description = "Bastion Security Group"

  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

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
    cidr_blocks = [var.vpn_cidr, var.remote_subnet_cidr, "172.27.236.0/24"]
    description = "all incoming traffic from remote access ip"
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

locals {
  extra_tags = { 
    role  = "bastion"
    route = "public"
  }
}
resource "aws_eip" "bastionip" {
  count    = var.create_vpc ? 1 : 0
  vpc      = true
  instance = aws_instance.bastion[count.index].id
  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)
}


data "aws_ami_ids" "centos_v7" {
  owners = ["679593333241"] # the softnas account id
  filter {
    name   = "description"
    values = ["CentOS Linux 7 x86_64 HVM EBS ENA 2002_01"]
  }
}

variable "allow_prebuilt_bastion_centos_ami" {
  default = false
}

variable "bastion_centos_ami_option" { # Where multiple data aws_ami_ids queries are available, this allows us to select one.
  default = "centos_v7"
}

locals {
  keys = ["centos_v7"] # Where multiple data aws_ami_ids queries are available, this is the full list of options.
  empty_list = list("")
  values = ["${element( concat(data.aws_ami_ids.centos_v7.ids, local.empty_list ), 0 )}"] # the list of ami id's
  bastion_centos_consumption_map = zipmap( local.keys , local.values )
}

locals { # select the found ami to use based on the map lookup
  base_ami = lookup(local.bastion_centos_consumption_map, var.bastion_centos_ami_option)
}

data "aws_ami_ids" "prebuilt_bastion_centos_ami_list" { # search for a prebuilt tagged ami with the same base image.  if there is a match, it can be used instead, allowing us to skip provisioning.
  owners = ["self"]
  filter {
    name   = "tag:base_ami"
    values = ["${local.base_ami}"]
  }
  filter {
    name = "name"
    values = ["bastion_centos_prebuilt_*"]
  }
}

locals {
  prebuilt_bastion_centos_ami_list = data.aws_ami_ids.prebuilt_bastion_centos_ami_list.ids
  first_element = element( data.aws_ami_ids.prebuilt_bastion_centos_ami_list.*.ids, 0)
  mod_list = concat( local.prebuilt_bastion_centos_ami_list , list("") )
  aquired_ami      = "${element( local.mod_list , 0)}" # aquired ami will use the ami in the list if found, otherwise it will default to the original ami.
  use_prebuilt_bastion_centos_ami = var.allow_prebuilt_bastion_centos_ami && length(local.mod_list) > 1 ? true : false
  ami = local.use_prebuilt_bastion_centos_ami ? local.aquired_ami : local.base_ami
}

output "base_ami" {
  value = local.base_ami
}

output "prebuilt_bastion_centos_ami_list" {
  value = local.prebuilt_bastion_centos_ami_list
}

output "first_element" {
  value = local.first_element
}

output "aquired_ami" {
  value = local.aquired_ami
}

output "use_prebuilt_bastion_centos_ami" {
  value = local.use_prebuilt_bastion_centos_ami
}

output "ami" {
  value = local.ami
}

resource "aws_instance" "bastion" {
  count         = var.create_vpc ? 1 : 0
  ami           = local.ami
  instance_type = var.instance_type
  key_name      = var.aws_key_name
  subnet_id     = element(concat(var.public_subnet_ids, list("")), 0)

  vpc_security_group_ids = [local.security_group_id]

  root_block_device {
    delete_on_termination = true
  }
  tags = merge(map("Name", format("%s", var.name)), var.common_tags, local.extra_tags)

  # `admin_user` and `admin_pw` need to be passed in to the appliance through `user_data`, see docs -->
  # https://docs.openvpn.net/how-to-tutorialsguides/virtual-platforms/amazon-ec2-appliance-ami-quick-start-guide/
  user_data = <<USERDATA

USERDATA

}

locals {
  public_ip = element(concat(aws_eip.bastionip.*.public_ip, list("")), 0)
  private_ip = element(concat(aws_instance.bastion.*.private_ip, list("")), 0)
  id = element(concat(aws_instance.bastion.*.id, list("")), 0)
  security_group_id = element(concat(aws_security_group.bastion.*.id, list("")), 0)
  bastion_address = var.route_public_domain_name ? "bastion.${var.public_domain_name}":"${local.public_ip}"
}


resource "null_resource" "provision_bastion" {
  count    = var.create_vpc ? 1 : 0
  depends_on = [
    aws_instance.bastion,
    aws_eip.bastionip,
    aws_route53_record.bastion_record,
  ]

  triggers = {
    instanceid = local.id
    bastion_address = local.bastion_address
  }

  provisioner "remote-exec" {
    connection {
      user        = "centos"
      host        = local.public_ip
      private_key = var.private_key
      type        = "ssh"
      timeout     = "10m"
    }

    inline = ["set -x && sudo yum install -y python python3"]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser
      echo "inventory $TF_VAR_inventory/hosts"
      cat $TF_VAR_inventory/hosts
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-public-host.yaml -v --extra-vars "public_ip=${local.public_ip} public_address=${local.bastion_address} bastion_address=${local.bastion_address} set_bastion=true"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "host_name=bastion host_ip=${local.public_ip} insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_aws_private_key_path"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/get-file.yaml -v --extra-vars "source=/var/log/messages dest=$TF_VAR_firehawk_path/tmp/log/cloud-init-output-bastion.log variable_user=centos variable_host=bastion"; exit_test
EOT

  }
}

locals {
  bastion_dependency = element(concat(null_resource.provision_bastion.*.id, list("")), 0)
}

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_record" {
  count   = var.route_public_domain_name && var.create_vpc ? 1 : 0
  zone_id = element(concat(list(var.route_zone_id), list("")), 0)
  name    = element(concat(list("bastion.${var.public_domain_name}"), list("")), 0)
  type    = "A"
  ttl     = 300
  records = [local.public_ip]
}

resource "null_resource" "start-bastion" {
  count = ( !var.sleep && var.create_vpc) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "aws ec2 start-instances --instance-ids ${local.id}"
  }
}

resource "null_resource" "shutdown-bastion" {
  count = var.sleep && var.create_vpc ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      aws ec2 stop-instances --instance-ids ${local.id}
  
EOT

  }
}

