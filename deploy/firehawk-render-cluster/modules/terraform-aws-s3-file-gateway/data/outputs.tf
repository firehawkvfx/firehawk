output "storage_gateway_sg_id" {
  value = local.storage_gateway_sg_id
}
output "private_subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.private : s.cidr_block]
}
output "private_subnet_ids" {
  value = [for s in data.aws_subnet.private : s.id]
}
output "public_subnet_cidr_blocks" {
  value = [for s in data.aws_subnet.public : s.cidr_block]
}
output "public_subnet_ids" {
  value = [for s in data.aws_subnet.public : s.id]
}
output "vpc_id" {
  value = local.rendervpc_id
}
output "rendervpc_cidr" {
  value = length(data.aws_vpc.rendervpc) > 0 ? data.aws_vpc.rendervpc[0].cidr_block : ""
}
output "cloud_s3_gateway" {
  value = data.aws_ssm_parameter.cloud_s3_gateway.value
  sensitive = true
}
output "cloud_s3_gateway_mount_target" {
  value = data.aws_ssm_parameter.cloud_s3_gateway_mount_target.value
  sensitive = true
}
output "cloud_s3_gateway_size" {
  value = data.aws_ssm_parameter.cloud_s3_gateway_size.value
  sensitive = true
}
output "aws_s3_bucket_arn" {
  value = data.aws_s3_bucket.rendering_bucket.arn
}