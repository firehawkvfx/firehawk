output "user_data_base64" {
  value     = null
  sensitive = true
}
output "vpc_cidr" {
  value = data.aws_vpc.primary.cidr_block
}
output "public_subnet_ids" {
  value = toset(data.aws_subnets.public.ids)
}
