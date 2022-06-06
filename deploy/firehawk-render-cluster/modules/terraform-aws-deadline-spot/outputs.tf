output "block_device_mappings" {
  value = data.aws_ami.rendernode.block_device_mappings
}
output "ebs_block_device" {
  value = local.ebs_block_device
}
output "snapshot_id" {
  value = local.snapshot_id
}