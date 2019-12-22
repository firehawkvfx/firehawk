output "private_ip" {
  value = aws_instance.node_centos.*.private_ip
}

output "public_ip" {
  value = aws_instance.node_centos.*.public_ip
}

# see https://github.com/hashicorp/terraform/issues/16726 for pointers on outputting variables where count is 0
# "${element(concat(resource.name.*.attr, list("")), 0)}"

output "ami_id" {
  # value = aws_ami_from_instance.node_centos.*.id  
  value = "${element(concat(aws_ami_from_instance.node_centos.*.id, list("")), 0)}"
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
  ebs_block_device_extended = concat(aws_ami_from_instance.node_centos.*.ebs_block_device, list(list(var.ebs_empty_map)))
}

# We select the first element in the list.  if the actual node exists, we will eventually get a valid value after the for loop below, otherwise it will return blank from the empty map, which is fine, since the ami id should never be referenced in this state.
locals {
  ebs_block_device_selected = element(local.ebs_block_device_extended, 0)
}

# This loop creates key's based on the device name, so the snapshot_id can be retrieved by the device name.
locals {
  ebs_block_device = {
    for bd in local.ebs_block_device_selected :
    bd.device_name => bd
  }
}

output "snapshot_id" {
  value = local.ebs_block_device["/dev/sda1"].snapshot_id
}

output "security_group_id" {
  value = aws_security_group.node_centos.id
}