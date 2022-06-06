#----------------------------------------------------------------
# This module creates all resources necessary for am Ansible Bastion instance in AWS
#----------------------------------------------------------------
data "aws_region" "current" {}
data "terraform_remote_state" "provisioner_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "predeploy/modules/terraform-aws-sg-provisioner/terraform.tfstate"
    region = data.aws_region.current.name
  }
}

resource "aws_security_group" "bastion_graphical" {
  count       = var.create_vpc ? 1 : 0
  name        = var.name
  vpc_id      = var.vpc_id
  description = "bastion_graphical Security Group"

  tags = merge(tomap({ "Name" : var.name }), var.common_tags, local.extra_tags)

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr]
    description = "all incoming traffic from vpc"
  }
  ingress {
    protocol        = "tcp"
    from_port       = 8443
    to_port         = 8443
    cidr_blocks     = [var.remote_ip_graphical_cidr]
    security_groups = [local.deployer_sg_id]
    description     = "NICE DCV graphical server"
  }

  ingress {
    protocol        = "tcp"
    from_port       = 22
    to_port         = 22
    cidr_blocks     = [var.remote_ip_graphical_cidr]
    security_groups = [local.deployer_sg_id]
    description     = "ssh"
  }
  ingress {
    protocol        = "icmp"
    from_port       = 8
    to_port         = 0
    cidr_blocks     = [var.remote_ip_graphical_cidr]
    security_groups = [local.deployer_sg_id]
    description     = "icmp"
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
    role  = "bastion_graphical"
    route = "public"
  }
  deployer_sg_id = data.terraform_remote_state.provisioner_security_group.outputs.security_group_id
}
resource "aws_eip" "bastion_graphicalip" {
  count    = var.create_vpc ? 1 : 0
  vpc      = true
  instance = aws_instance.bastion_graphical[count.index].id
  tags     = merge(tomap({ "Name" : var.name }), var.common_tags, local.extra_tags)
}

resource "aws_instance" "bastion_graphical" {
  count         = var.create_vpc ? 1 : 0
  ami           = var.bastion_graphical_ami_id
  instance_type = var.instance_type
  key_name      = var.aws_key_name
  subnet_id     = element(concat(var.public_subnet_ids, tolist([""])), 0)

  vpc_security_group_ids = local.vpc_security_group_ids

  root_block_device {
    delete_on_termination = true
  }
  tags = merge(tomap({ "Name" : var.name }), var.common_tags, local.extra_tags)

  user_data            = data.template_file.user_data_consul_client.rendered
  iam_instance_profile = aws_iam_instance_profile.example_instance_profile.name

}

# ---------------------------------------------------------------------------------------------------------------------
# CREATES A ROLE THAT IS ATTACHED TO THE INSTANCE
# The arn of this AWS role is what the Vault server will use create the Vault Role
# so it can validate login requests from resources with this role
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_iam_instance_profile" "example_instance_profile" {
  path = "/"
  role = aws_iam_role.example_instance_role.name
}

resource "aws_iam_role" "example_instance_role" {
  name_prefix        = "${var.name}-role"
  assume_role_policy = data.aws_iam_policy_document.example_instance_role.json
}

data "aws_iam_policy_document" "example_instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Adds policies necessary for running consul
module "consul_iam_policies_for_client" {
  source = "github.com/hashicorp/terraform-aws-consul.git//modules/consul-iam-policies?ref=v0.8.0"

  iam_role_id = aws_iam_role.example_instance_role.id
}

# ---------------------------------------------------------------------------------------------------------------------
# THE USER DATA SCRIPT THAT WILL RUN ON THE INSTANCE
# This script will run consul, which is used for discovering vault cluster
# And perform the login operation
# ---------------------------------------------------------------------------------------------------------------------

data "template_file" "user_data_consul_client" {
  template = file("${path.module}/user-data-consul-client.sh")

  vars = {
    consul_cluster_tag_key   = var.consul_cluster_tag_key
    consul_cluster_tag_value = var.consul_cluster_name
  }
}

locals {
  public_ip                           = element(concat(aws_eip.bastion_graphicalip.*.public_ip, tolist([""])), 0)
  private_ip                          = element(concat(aws_instance.bastion_graphical.*.private_ip, tolist([""])), 0)
  id                                  = element(concat(aws_instance.bastion_graphical.*.id, tolist([""])), 0)
  bastion_graphical_security_group_id = element(concat(aws_security_group.bastion_graphical.*.id, tolist([""])), 0)
  # bastion_graphical_vpn_security_group_id = element(concat(aws_security_group.bastion_graphical_vpn.*.id, tolist([""])), 0)
  # vpc_security_group_ids = var.create_vpn ? [local.bastion_graphical_security_group_id, local.bastion_graphical_vpn_security_group_id] : [local.bastion_graphical_security_group_id]
  vpc_security_group_ids    = [local.bastion_graphical_security_group_id]
  bastion_graphical_address = var.route_public_domain_name ? "bastion_graphical.${var.public_domain_name}" : local.public_ip
}


resource "null_resource" "provision_bastion_graphical" {
  count = (!var.sleep && var.create_vpc) ? 1 : 0
  depends_on = [
    aws_instance.bastion_graphical,
    aws_eip.bastion_graphicalip,
    aws_route53_record.bastion_graphical_record,
  ]

  triggers = {
    instanceid                = local.id
    bastion_graphical_address = local.bastion_graphical_address
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      cd $TF_VAR_firehawk_path
      echo "PWD: $PWD"
      . scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-clean-public-host.yaml -v --extra-vars "variable_hosts=ansible_control variable_user=ec2-user public_ip=${local.public_ip} public_address=${local.public_ip}"; exit_test
EOT
  }

  provisioner "remote-exec" {
    connection {
      user        = "ec2-user"
      host        = local.public_ip
      private_key = var.private_key
      type        = "ssh"
      timeout     = "10m"
    }
    inline = [
      "echo 'Instance is up.'",
      "set -x && sudo yum install -y python python3", # this line is only required if not included in the ami already.  Should only do this if instance isnt tagged as bootstrapped.
    ]
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      cd $TF_VAR_firehawk_path
      echo "PWD: $PWD"
      . scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      echo "inventory $TF_VAR_inventory/hosts"
      cat $TF_VAR_inventory/hosts
      ansible-playbook -i "$TF_VAR_inventory" ansible/ssh-add-public-host.yaml -v --extra-vars "variable_hosts=ansible_control variable_user=ec2-user public_ip=${local.public_ip} public_address=${local.public_ip} bastion_address=${var.bastion_ip} set_bastion=false"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/inventory-add.yaml -v --extra-vars "variable_user=ec2-user variable_group=ec2-user host_name=bastion_graphical host_ip=${local.public_ip} insert_ssh_key_string=ansible_ssh_private_key_file=$TF_VAR_aws_private_key_path"; exit_test
      ansible-playbook -i "$TF_VAR_inventory" ansible/get-file.yaml -v --extra-vars "variable_host=bastion_graphical variable_user=ec2-user source=/var/log/messages dest=$TF_VAR_firehawk_path/tmp/log/cloud-init-output-bastion_graphical.log variable_user=ec2-user variable_host=bastion_graphical"; exit_test
EOT
  }
}

locals {
  bastion_graphical_dependency = element(concat(null_resource.provision_bastion_graphical.*.id, tolist([""])), 0)
}

variable "route_zone_id" {
}

variable "public_domain_name" {
}

resource "aws_route53_record" "bastion_graphical_record" {
  count   = var.route_public_domain_name && var.create_vpc ? 1 : 0
  zone_id = element(concat(list(var.route_zone_id), tolist([""])), 0)
  name    = element(concat(list("bastion_graphical.${var.public_domain_name}"), tolist([""])), 0)
  type    = "A"
  ttl     = 300
  records = [local.public_ip]
}

resource "null_resource" "start_bastion" {
  depends_on = [aws_instance.bastion_graphical]
  count      = (!var.sleep && var.create_vpc) ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "aws ec2 start-instances --instance-ids ${local.id}"
  }
}

resource "null_resource" "shutdown_bastion" {
  count = var.sleep && var.create_vpc ? 1 : 0

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      aws ec2 stop-instances --instance-ids ${local.id}
EOT
  }
}

