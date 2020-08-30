# terraform {
#   required_providers {
#     aws = "~> 3.0"
#   }
# }

# TODO
# install lustre on nodes, packages, fstab.
# test if export back to identical path works?  why is it a different path by default?  danger? https://docs.aws.amazon.com/fsx/latest/LustreGuide/create-fs-linked-data-repo.html
# change sync pull mode via cli.
# enable sync push events, check completion before destroy.
# tighten security groups.
# set a reasonable size for distribution over cluster.  100MB?


# fsx for lustre security group rules https://docs.aws.amazon.com/fsx/latest/LustreGuide/limit-access-security-groups.html

locals {
  name = "fsx_vpc_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  extra_tags = {
    role = "fsx"
    route = "private"
  }
}

resource "aws_security_group" "fsx_vpc" {
  count = local.fsx_enabled

  name        = "fsx_vpc_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "FSx security group"
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
    from_port   = 988
    to_port     = 988
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "udp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "icmp"
  }

  egress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "udp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [ var.vpc_cidr, var.public_subnets_cidr_blocks[0] ]
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

resource "aws_security_group" "fsx_vpn" {
  count = local.fsx_enabled
  depends_on = [var.vpn_private_ip]

  name        = "fsx_vpn_pipeid${lookup(var.common_tags, "pipelineid", "0")}"
  vpc_id      = var.vpc_id
  description = "FSX VPN security group for remote subnet"

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
    from_port   = 988
    to_port     = 988
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  ingress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "icmp"
  }

  egress {
    protocol    = "tcp"
    from_port   = 988
    to_port     = 988
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "tcp"
    from_port   = 1021
    to_port     = 1023
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
    description = "Allows Lustre traffic between Amazon FSx for Lustre file servers"
  }

  egress {
    protocol    = "icmp"
    from_port   = 8
    to_port     = 0
    cidr_blocks = [var.remote_subnet_cidr, var.vpn_cidr]
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

resource "null_resource" "init_fsx" {
  count = local.fsx_enabled
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_init.yaml; exit_test # Ensure the bucket used to archive the fsx cluster exists
EOT
  }
}

locals {
  fsx_enabled = ( !var.sleep && var.fsx_storage ) ? 1 : 0
  fsx_import_path = "s3://${var.fsx_bucket_prefix}.${var.bucket_extension}"
}

resource "aws_fsx_lustre_file_system" "fsx_storage" {
  count      = ( !var.sleep && ( local.fsx_enabled == 1 ) ) ? 1 : 0
  depends_on = [ null_resource.init_fsx ]
  
  import_path      = local.fsx_import_path
  export_path      = local.fsx_import_path
  storage_capacity = var.fsx_storage_capacity
  subnet_ids       = [ element( flatten( concat( var.subnet_ids, list("") ) ), 0 ) ]
  security_group_ids = concat( aws_security_group.fsx_vpc.*.id, aws_security_group.fsx_vpn.*.id, list("") )
  deployment_type  = "SCRATCH_2" # aws provider v3.0 only

  tags = var.common_tags
}

locals {
  id = element( concat( aws_fsx_lustre_file_system.fsx_storage.*.id, list("") ), 0)
  # id = element( aws_fsx_lustre_file_system.fsx_storage.*.id, 0 )
}

output "id" {
  depends_on = [
    aws_fsx_lustre_file_system.fsx_storage,
  ]
  value = local.id
}

output "network_interface_ids" {
  value = aws_fsx_lustre_file_system.fsx_storage.*.network_interface_ids
}

# Terraform provider API does list the primary interface in the correct order to obtain it.  so we use a custom data source to aquire the primary interface

data "external" "primary_interface_id" { # Why cant we use triggers here?
  count = local.fsx_enabled
  program = ["/bin/bash", "${path.module}/primary_interface.sh"]
  
  # Arbitrary map from strings to strings, passed to the external program as the data query.
  query = { 
    id = "${local.id}"
  }
}

locals {
  # primary_interface = data.external.primary_interface_id.result["primary_interface"]
  # primary_interface = element( concat( data.external.primary_interface_id.*.result, map( "primary_interface", "" ), 0 ))["primary_interface"]
  primary_interface = lookup( element( concat( data.external.primary_interface_id.*.result, list( map( "primary_interface", "" ) ) ), 0), "primary_interface", "" )
  # lookup(map, key, default)
  # primary_interface = element( concat( data.aws_network_interface.fsx_primary_interface.*.private_ip, list("") ), 0 )
}

output "primary_interface" {
  value = local.primary_interface
}

data "aws_network_interface" "fsx_primary_interface" {
  count = local.fsx_enabled
  id = local.primary_interface
}

locals {
  fsx_private_ip = element( concat( data.aws_network_interface.fsx_primary_interface.*.private_ip, list("")), 0 )
}

resource "aws_route53_record" "fsx_record" {
  count   = local.fsx_enabled
  zone_id = var.private_route53_zone_id
  name    = var.fsx_hostname
  type    = "A"
  ttl     = 300
  records = [local.fsx_private_ip]
}

output "fsx_private_ip" {
  depends_on = [
    aws_fsx_lustre_file_system.fsx_storage,
    data.external.primary_interface_id,
    data.aws_network_interface.fsx_primary_interface,
    aws_route53_record.fsx_record
  ]
  value = local.fsx_private_ip
}

### attach mounts onsite if fsx is available

locals {
  fsx_volumes_user_path = "/secrets/${ var.envtier }/fsx_volumes/fsx_volumes.yaml"
  fsx_volumes_default_path = "/deployuser/ansible/ansible_collections/firehawkvfx/fsx/roles/fsx_volume_mounts/files/fsx_volumes.yaml"
}

resource "null_resource" "fsx_update_file_system" { # Ensure the cluster synchronises changes in the S3 bucket.  Changes on the cluster must be pushed back to the bucket.
  count      = ( !var.sleep && ( local.fsx_enabled == 1 ) ) ? 1 : 0
  depends_on = [
    aws_fsx_lustre_file_system.fsx_storage,
    data.external.primary_interface_id,
    data.aws_network_interface.fsx_primary_interface
  ]
  triggers = {
    fsx_private_ip = local.fsx_private_ip
    ebs_template_sha1    = "${sha1( file( fileexists( local.fsx_volumes_user_path ) ? local.fsx_volumes_user_path : local.fsx_volumes_default_path ))}" # file contents can trigger volume attachment 
    fsx_enabled = local.fsx_enabled
    sleep = var.sleep
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x

      aws fsx update-file-system --file-system-id ${local.id} --lustre-configuration AutoImportPolicy=NEW_CHANGED
EOT
  }
}

resource "null_resource" "attach_local_mounts_after_start" {
  count      = ( !var.sleep && ( local.fsx_enabled == 1 ) ) ? 1 : 0
  depends_on = [
    aws_fsx_lustre_file_system.fsx_storage,
    data.external.primary_interface_id,
    data.aws_network_interface.fsx_primary_interface,
    aws_route53_record.fsx_record
  ]
  triggers = {
    fsx_private_ip = local.fsx_private_ip
    fsx_record = "${join(",", aws_route53_record.fsx_record.*.id)}"
    remote_mounts_on_local = var.remote_mounts_on_local
    ebs_template_sha1    = "${sha1( file( fileexists( local.fsx_volumes_user_path ) ? local.fsx_volumes_user_path : local.fsx_volumes_default_path ))}" # file contents can trigger volume attachment 
    fsx_enabled = local.fsx_enabled
    sleep = var.sleep
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x

      echo "TF_VAR_remote_mounts_on_local= $TF_VAR_remote_mounts_on_local"
      # ensure routes on workstation exist
      if [[ $TF_VAR_remote_mounts_on_local == true ]] && [[ "$TF_VAR_set_routes_on_workstation" = "true" ]]; then
        printf "\n$BLUE CONFIGURE REMOTE ROUTES ON LOCAL NODES $NC\n"
        ansible-playbook -i "$TF_VAR_inventory" ansible/node-centos-routes.yaml -v -v --extra-vars "variable_host=workstation1 variable_user=deployuser hostname=workstation1 ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key ethernet_interface=$TF_VAR_workstation_ethernet_interface"; exit_test
      fi
      
      # mount volumes to local site when fsx is started
      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        printf "\n$BLUE CONFIGURE REMOTE MOUNTS ON LOCAL NODES $NC\n"
        
        # unmount volumes from local site - same as when fsx is shutdown, we need to ensure no mounts are present since existing mounts pointed to an incorrect environment will be wrong
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
        
        # now mount current volumes
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml -v -v --extra-vars "fsx_ip=${var.fsx_hostname} variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
EOT
  }

  provisioner "local-exec" { # when this is disabled / destroyed / during sleep, we unmount from the site to prevent boot issues with invalid mounts in fstab
    when    = destroy
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x

      if [[ $TF_VAR_remote_mounts_on_local == true ]] ; then
        # unmount volumes from local site when fsx is shutdown.
        ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_volume_mounts.yaml --extra-vars "variable_host=workstation1 variable_user=deployuser ansible_ssh_private_key_file=$TF_VAR_onsite_workstation_private_ssh_key destroy=true variable_gather_facts=no" --skip-tags 'cloud_install local_install_onsite_mounts' --tags 'local_install'; exit_test
      fi
EOT
  }
}

output "attach_local_mounts_after_start" {
  value = null_resource.attach_local_mounts_after_start.*.id
}