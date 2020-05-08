output "private_ip" {
  value = local.private_ip
  depends_on = [
    null_resource.provision_bastion
  ]
}

output "public_ip" {
  value = local.public_ip
  depends_on = [
    null_resource.provision_bastion
  ]
}

output "bastion_dependency" {
  value = local.bastion_dependency
  depends_on = [
    null_resource.provision_bastion
  ]
}