# terraform {
#   required_providers {
#     aws = "~> 3.0"
#   }
# }

resource "null_resource" "init_fsx" {
  count = var.fsx_storage ? 1 : 0
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      . /deployuser/scripts/exit_test.sh
      export SHOWCOMMANDS=true; set -x
      cd /deployuser

      ansible-playbook -i "$TF_VAR_inventory" ansible/ansible_collections/firehawkvfx/fsx/fsx_init.yaml; exit_test
EOT
  }
}

resource "aws_fsx_lustre_file_system" "fsx_storage" {
  count = var.fsx_storage ? 1 : 0
  depends_on = [ null_resource.init_fsx ]
  
  import_path      = "s3://prod.${var.bucket_extension}"
  storage_capacity = 1200
  subnet_ids       = var.subnet_ids
  # deployment_type  = "SCRATCH_2" # aws provider v3.0 only

  tags = var.common_tags
}

# data "aws_network_interface" "fsx_network_interface" {
#   count = var.fsx_storage ? 1 : 0

#   # id = aws_fsx_lustre_file_system.fsx_storage.*.network_interface_ids
#   id = "${element( concat( aws_fsx_lustre_file_system.fsx_storage.*.network_interface_ids, list("") ), 0)}"
# }

output "id" {
  # value = aws_fsx_lustre_file_system.fsx_storage.*.id
  value = element( concat( aws_fsx_lustre_file_system.fsx_storage.*.id, list("") ), 0)
}

output "network_interface_ids" {
  value = aws_fsx_lustre_file_system.fsx_storage.*.network_interface_ids
}

data "external" "primary_interface_id" { # Terraform provider API does list the primary interface in the correct order to obtain it.  so we use a custom data source to aquire the primary interface
  program = ["/bin/bash", "${path.module}/primary_interface.sh"]

  query = {
    # arbitrary map from strings to strings, passed
    # to the external program as the data query.
    id = "${element( concat( aws_fsx_lustre_file_system.fsx_storage.*.id, list("") ), 0)}"
  }
}

locals {
  primary_interface = data.external.primary_interface_id.result["primary_interface"]
}

output "primary_interface" {
  value = local.primary_interface
}

data "aws_network_interface" "fsx_primary_interface" {
  count = var.fsx_storage ? 1 : 0

  id = local.primary_interface
}

# This command will return the primary network interface
# aws fsx describe-file-systems | jq '.FileSystems[] | select(.FileSystemId == "fs-003bfeff0d38c8ce6") | .NetworkInterfaceIds[0]'

# output "aws_network_interface" {
#   value = data.aws_network_interface.fsx_network_interface.*.private_ip
# }

# to mount https://docs.aws.amazon.com/fsx/latest/LustreGuide/mount-fs-auto-mount-onreboot.html
# file_system_dns_name@tcp:/mountname /fsx lustre defaults,noatime,flock,_netdev 0 0