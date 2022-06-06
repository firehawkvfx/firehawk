provider "vault" {}
resource "vault_auth_backend" "aws" {
  type = "aws"
}
resource "vault_aws_auth_backend_client" "provisioner" {
  # Sets the access key and secret key that Vault will use when making API requests on behalf of an AWS Auth Backend
  backend                    = vault_auth_backend.aws.path
  iam_server_id_header_value = "vault.service.consul"
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "provisioner_profile" { # read the arn with data.terraform_remote_state.provisioner_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.provisioner_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "init/modules/terraform-aws-iam-profile-provisioner/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "provisioner" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 70
  token_max_ttl        = 120
  token_policies       = ["provisioner"]
  role                 = "provisioner-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.provisioner_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
  # bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  # bound_ami_ids                   = ["ami-8c1be5f6"]
  # bound_vpc_ids                   = ["vpc-b61106d4"]
  # bound_subnet_ids                = ["vpc-133128f1"]
  # iam_server_id_header_value      = "vault.service.consul" # required to mitigate against replay attacks.
}


data "terraform_remote_state" "deadline_db_profile" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "init/modules/terraform-aws-iam-profile-deadline-db/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "deadline_db" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 1200
  token_max_ttl        = 1200
  token_policies       = ["deadline_db", "ssh_host", "pki_int"]
  role                 = "deadline-db-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.deadline_db_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
  # bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  # bound_ami_ids                   = ["ami-8c1be5f6"]
  # bound_vpc_ids                   = ["vpc-b61106d4"]
  # bound_subnet_ids                = ["vpc-133128f1"]
  # iam_server_id_header_value      = "vault.service.consul" # required to mitigate against replay attacks.
}

data "terraform_remote_state" "openvpn_profile" { # read the arn with data.terraform_remote_state.openvpn_profile.outputs.instance_role_arn, or read the profile name with data.terraform_remote_state.openvpn_profile.outputs.instance_profile_name
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-openvpn/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "vpn_server" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 300
  token_max_ttl        = 300
  token_policies       = ["vpn_server", "ssh_host"]
  role                 = "vpn-server-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.openvpn_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
  # bound_iam_instance_profile_arns = ["arn:aws:iam::123456789012:instance-profile/MyProfile"]
  # iam_server_id_header_value      = "vault.service.consul" # required to mitigate against replay attacks.
}
data "terraform_remote_state" "rendernode_profile" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-rendernode/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "rendernode" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 300
  token_max_ttl        = 300
  token_policies       = ["deadline_client", "ssh_host"]
  role                 = "rendernode-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.rendernode_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
}
data "terraform_remote_state" "workstation_profile" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-workstation/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "workstation" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 300
  token_max_ttl        = 300
  token_policies       = ["deadline_client", "ssh_host", "workstation_pw"]
  role                 = "workstation-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.workstation_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
}

data "terraform_remote_state" "bastion_profile" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-bastion/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "bastion" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 300
  token_max_ttl        = 300
  token_policies       = ["ssh_host"]
  role                 = "bastion-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.bastion_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
}
output "bastion_arn" {
  value = data.terraform_remote_state.bastion_profile.outputs.instance_role_arn
}
data "terraform_remote_state" "vault_client_profile" {
  backend = "s3"
  config = {
    bucket = "state.terraform.${var.bucket_extension}"
    key    = "firehawk-main/modules/terraform-aws-iam-profile-vault-client/terraform.tfstate"
    region = data.aws_region.current.name
  }
}
resource "vault_aws_auth_backend_role" "vault_client" {
  backend              = vault_auth_backend.aws.path
  token_ttl            = 300
  token_max_ttl        = 300
  token_policies       = ["ssh_host"]
  role                 = "vault-client-vault-role"
  auth_type            = "iam"
  bound_account_ids    = [data.aws_caller_identity.current.account_id]
  bound_iam_role_arns  = concat([data.terraform_remote_state.vault_client_profile.outputs.instance_role_arn]) # Only instances with this Role ARN May read vault data.
  inferred_entity_type = "ec2_instance"
  inferred_aws_region  = data.aws_region.current.name
}