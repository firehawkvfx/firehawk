module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  # key_name   = "deployuser-${var.resourcetier}"
  key_name   = var.aws_key_name
  public_key = file( var.public_key_path )
  tags       = var.common_tags
}
