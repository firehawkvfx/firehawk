output "private_ip" {
  value = "${aws_instance.bastion.private_ip}"
}

output "public_ip" {
  value = "${aws_instance.bastion.public_ip}"
}
