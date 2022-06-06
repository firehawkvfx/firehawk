# This module will configure Deadline's Spot event plugin to scale render nodes based on the queue for deadline groups

data "aws_region" "current" {}
data "aws_ami" "rendernode" {
  most_recent = true
  # If we change the AWS Account in which test are run, update this value.
  owners = ["self"]
  filter {
    name   = "tag:ami_role"
    values = ["firehawk_centos7_rendernode_ami"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = length(var.rendervpc_id) > 0 ? [var.rendervpc_id] : []
  }
  tags = {
    area = "private"
  }
}
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "terraform_remote_state" "rendernode_profile" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension_vault}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-rendernode/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "terraform_remote_state" "rendernode_security_group" { # read the arn with data.terraform_remote_state.packer_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.packer_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-render-cluster/modules/terraform-aws-sg-rendernode/module/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
data "aws_ssm_parameter" "ubl_url" {
  name = "/firehawk/resourcetier/dev/ubl_url"
}
data "aws_secretsmanager_secret" "ubl_activation_code" {
  name = "/firehawk/resourcetier/dev/ubl_activation_code"
}
data "aws_secretsmanager_secret_version" "ubl_activation_code" {
  secret_id = data.aws_secretsmanager_secret.ubl_activation_code.id
}
data "aws_ssm_parameter" "max_spot_capacity_engine" {
  name = "/firehawk/resourcetier/dev/max_spot_capacity_engine"
}
data "aws_ssm_parameter" "max_spot_capacity_mantra" {
  name = "/firehawk/resourcetier/dev/max_spot_capacity_mantra"
}

variable "ebs_empty_map" {
  type = map(string)
  default = {
    device_name = "/dev/sda1"
    snapshot_id = ""
  }
}
# We create a list with a dummy map as the 2nd / last element.
locals {
  # ebs_block_device_extended = concat(data.aws_ami.rendernode.block_device_mappings, list(list(var.ebs_empty_map)))
  # We select the first element in the list.  if the actual node exists, we will eventually get a valid value after the for loop below, otherwise it will return blank from the empty map, which is fine, since the ami id should never be referenced in this state.
  # ebs_block_device_selected = element(data.aws_ami.rendernode.block_device_mappings, 0)
  ebs_block_device_selected = data.aws_ami.rendernode.block_device_mappings
}
# This loop creates key's based on the device name, so the snapshot_id can be retrieved by the device name.
locals {
  ebs_block_device = {
    for bd in local.ebs_block_device_selected :
    bd.device_name => bd
  }
}
locals {
  ami_id                             = data.aws_ami.rendernode.id
  snapshot_id                        = local.ebs_block_device["/dev/sda1"].ebs.snapshot_id
  private_subnet_ids                 = [for s in data.aws_subnet.private : s.id]
  instance_profile                   = try( data.terraform_remote_state.rendernode_profile.outputs.instance_profile_arn, null )
  security_group_id                  = try( data.terraform_remote_state.rendernode_security_group.outputs.security_group_id, null )
  config_template_file_path          = "${path.module}/ansible/collections/ansible_collections/firehawkvfx/deadline/roles/deadline_spot/files/config_template.json"
  override_config_template_file_path = "${pathexpand("~")}/config_template.json"
  ubl_url                            = data.aws_ssm_parameter.ubl_url.value
  max_spot_capacity_engine           = data.aws_ssm_parameter.max_spot_capacity_engine.value
  max_spot_capacity_mantra           = data.aws_ssm_parameter.max_spot_capacity_mantra.value
  path_module                        = path.module
  fileset                            = fileset(path.module, "[^.]*/**")
  shaset                             = sha1(join("", [for f in local.fileset : filesha1(f)]))
}

output "fileset" {
  value = local.fileset
}
output "shaset" {
  value = local.shaset
}
resource "null_resource" "provision_deadline_spot" {
  count = 1
  triggers = {
    deadline_db_instance_id = var.deadline_db_instance_id
    ami_id                  = local.ami_id
    snapshot_id             = local.snapshot_id
    config_template_sha1    = sha1(file(fileexists(local.override_config_template_file_path) ? local.override_config_template_file_path : local.config_template_file_path))
    deadline_roles_tf_sha1  = sha1(local.instance_profile)
    shaset                  = local.shaset # checksum all contents of this directory
    volume_size             = var.node_centos_volume_size
    volume_type             = var.node_centos_volume_type
    user_data               = var.user_data
  }

  provisioner "local-exec" { # wait for deadline service to arrive (means user data config complete)
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
export SHOWCOMMANDS=true; set -x
echo "Ensure SSH Certs are configured correctly with the current instance for the Ansible playbook to configure Deadline groups / UBL"
cd ${path.module}
printf "\n...Waiting for consul deadlinedb service before attempting to configure groups / UBL.\n\n"

tries=0
max_tries=90
until [ $tries -gt $max_tries ] || consul catalog services | grep -m 1 "deadlinedb"; do
  tries=$(( $tries + 1 ))
  sleep 10
done
if [ $tries -gt $max_tries ]; then
  echo "Command timed out before service arrived"
  exit 1
fi
EOT
  }

  provisioner "local-exec" { # configure deadline groups and UBL
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
set -e
pathadd() {
  if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
    PATH="$${PATH:+"$PATH:"}$1"
  fi
}
pathadd $HOME/.local/bin
echo "PATH: $PATH"
ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook -vv -i "${path.module}/ansible/inventory/hosts" ansible/collections/ansible_collections/firehawkvfx/deadline/deadline_config.yaml -v --extra-vars "ubl_url=${data.aws_ssm_parameter.ubl_url.value} \
  ubl_activation_code=${data.aws_secretsmanager_secret_version.ubl_activation_code.secret_string}"
EOT
  }

  provisioner "local-exec" { # configure spot event plugin
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
export SHOWCOMMANDS=true; set -x
export local_config_output_dir="$HOME/firehawk"
export remote_config_output_dir="/home/${var.deadlineuser_name}/firehawk"
mkdir -p "$local_config_output_dir"
echo "Ensure SSH Certs are configured correctly with the current instance for the Ansible playbook to configure Deadline Spot Plugin"
cd ${path.module}
# printf "\n...Waiting for consul deadlinedb service before attempting to configure spot event plugin.\n\n"
# until consul catalog services | grep -m 1 "deadlinedb"; do sleep 10 ; done
# set -x
# set -e
pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$${PATH:+"$PATH:"}$1"
    fi
}
pathadd $HOME/.local/bin
echo "PATH: $PATH"
ANSIBLE_STDOUT_CALLBACK=debug ansible-playbook -i "${path.module}/ansible/inventory/hosts" ansible/collections/ansible_collections/firehawkvfx/deadline/deadline_spot.yaml -v --extra-vars "config_generated_json=$remote_config_output_dir/config_generated.json \
  deadlineuser_name=${var.deadlineuser_name} \
  local_config_output_dir=$local_config_output_dir \
  remote_config_output_dir=$remote_config_output_dir \
  max_spot_capacity_engine=${local.max_spot_capacity_engine} \
  max_spot_capacity_mantra=${local.max_spot_capacity_mantra} \
  volume_type=${var.node_centos_volume_type} \
  volume_size=${var.node_centos_volume_size} \
  ami_id=${local.ami_id} \
  snapshot_id=${local.snapshot_id} \
  subnet_id=${local.private_subnet_ids[0]} \
  spot_instance_profile_arn=${local.instance_profile} \
  security_group_id=${local.security_group_id} \
  aws_region=${data.aws_region.current.name} \
  aws_key_name=${var.aws_key_name} \
  account_id=${lookup(var.common_tags, "accountid", "0")} \
  valid_from=${timeadd(timestamp(), "-48h")} \
  valid_until=${timeadd(timestamp(), "8760h")} \
  user_data=${var.user_data}"

EOT
  }
}
