output "private_ip" {
  value = aws_instance.pcoipgw.private_ip
}

output "public_ip" {
  value = aws_instance.pcoipgw.public_ip
}

