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
  deployment_type  = SCRATCH_2

  tags = var.common_tags
}

data "aws_network_interface" "fsx_network_interface" {
  id = aws_fsx_lustre_file_system.fsx_storage.network_interface_ids
}

output "id" {
  value = aws_fsx_lustre_file_system.fsx_storage.id
}

output "network_interface_ids" {
  value = aws_fsx_lustre_file_system.fsx_storage.network_interface_ids
}

output "aws_network_interface" {
  value = aws_network_interface.fsx_network_interface.private_ip
}