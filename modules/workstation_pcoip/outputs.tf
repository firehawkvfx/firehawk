output "private_ip" {
  value = aws_instance.workstation_pcoip.*.private_ip
}

output "public_ip" {
  value = aws_instance.workstation_pcoip.*.public_ip
}

