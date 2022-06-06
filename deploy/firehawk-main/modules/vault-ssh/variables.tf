variable "aws_external_domain" {
  description = "The AWS external domain can be used for ssh certtificates, provided we always ensure to provide the CA cert to any host that wishes to connect. eg: ap-southeast-2.compute.amazonaws.com.  It is also possible to use your own domain, and recommended for produciton, provided you have enabled AWS access to control its name records."
  type        = string
}