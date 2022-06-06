output "file_gateway_object" {
  value     = aws_storagegateway_gateway.storage_gateway_resource
  sensitive = true
}
output "file_gateway_private_ip" {
  value = local.private_ip
}
output "nfs_file_share_path" {
  value = local.nfs_file_share_path
}
output "smb_file_share_path" {
  value = local.smb_file_share_path
}
