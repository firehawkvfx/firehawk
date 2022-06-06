output "fsx_storage" {
  value = try(data.terraform_remote_state.fsx.outputs.fsx_storage, null)
}
output "fsx_private_ip" {
  value = length(try(data.terraform_remote_state.fsx.outputs.fsx_storage, [])) > 0 ? data.terraform_remote_state.fsx.outputs.fsx_private_ip : null
}
output "fsx_dns_name" {
  value = length(try(data.terraform_remote_state.fsx.outputs.fsx_storage, [])) > 0 ? data.terraform_remote_state.fsx.outputs.fsx_dns_name : null
}
output "fsx_mount_name" {
  value = length(try(data.terraform_remote_state.fsx.outputs.fsx_storage, [])) > 0 ? data.terraform_remote_state.fsx.outputs.fsx_mount_name : null
}

output "file_gateway_object" {
  value     = try(data.terraform_remote_state.file_gateway.outputs.file_gateway_object, null)
  sensitive = true
}
output "file_gateway_private_ip" {
  value = length(try(data.terraform_remote_state.file_gateway.outputs.file_gateway_object, [])) > 0 ? data.terraform_remote_state.file_gateway.outputs.file_gateway_private_ip : null
}
output "nfs_file_share_path" {
  value = length(try(data.terraform_remote_state.file_gateway.outputs.file_gateway_object, [])) > 0 ? data.terraform_remote_state.file_gateway.outputs.nfs_file_share_path : null
}
