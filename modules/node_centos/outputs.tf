output "private_ip" {
  value = "${aws_instance.node_centos.private_ip}"
}

output "public_ip" {
  value = "${aws_instance.node_centos.public_ip}"
}
