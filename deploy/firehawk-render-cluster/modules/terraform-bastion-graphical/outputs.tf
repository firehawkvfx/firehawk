output "private_ip" {
  value = local.private_ip
  depends_on = [
    null_resource.provision_bastion_graphical
  ]
}

output "public_ip" {
  value = local.public_ip
  depends_on = [
    null_resource.provision_bastion_graphical
  ]
}

output "bastion_graphical_dependency" {
  value = local.bastion_graphical_dependency
  depends_on = [
    null_resource.provision_bastion_graphical
  ]
}

output "Instructions" {
  value = <<EOF
  To use connect to the graphical bastion, you must first set a user password using ssh:
  ssh ec2-user@${module.vpc.bastion_graphical_public_ip}
  sudo passwd ec2-user

  Then using the NICE DCV Client installed on your desktop, you can connect to ${module.vpc.bastion_graphical_public_ip} with your password.

  Ensure you correctly set the remote_ip_graphical_cidr variable (ending in /32).  This is the remote public IP address of your host running the NICE DCV client.
  This variable is used to define the security groups.
  
  You can change this variable and use 'terraform apply' to update the security group if you forgot to do this or if your IP changes because it is not static. 
EOF
}
