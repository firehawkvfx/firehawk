output "private_ip" {
  value = aws_instance.node_centos.*.private_ip
}

output "public_ip" {
  value = aws_instance.node_centos.*.public_ip
}

output "ami_id" {
  value = aws_ami_from_instance.node_centos[0].id
}

# locals {
#   block_device_mappings = {
#     for bd in aws_ami_from_instance.node_centos[0].block_device_mappings:
#     bd.device_name => bd
#   }
# }

locals {
  ebs_block_device = {
    for bd in aws_ami_from_instance.node_centos[0].ebs_block_device :
    bd.device_name => bd
  }
}

# (just for example)
output "snapshot_id" {
  #value = local.block_device_mappings["/dev/sda1"].snapshot_id
  value = local.ebs_block_device["/dev/sda1"].snapshot_id
  #value = aws_ami_from_instance.node_centos[0].ebs_block_device.snapshot_id
}

# output "snapshot_id" {
#   value = data.aws_ami.node_centos.block_device_mappings.0.ebs.snapshot_id
# }

output "security_group_id" {
  value = aws_security_group.node_centos.id
}