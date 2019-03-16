output "private_ip" {
  value = "${aws_instance.bastion.private_ip}"
}
output "public_ip" {
  value = "${aws_eip.bastionip.public_ip}"
}