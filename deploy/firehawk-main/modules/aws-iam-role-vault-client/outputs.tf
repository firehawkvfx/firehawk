output "vault_client_profile_id" {
  value = aws_iam_instance_profile.vault_client_profile.id
}

output "vault_client_profile_arn" {
  value = aws_iam_instance_profile.vault_client_profile.arn
}

output "vault_client_role_id" {
  value = aws_iam_role.vault_client_role.id
}

output "vault_client_role_arn" {
  value = aws_iam_role.vault_client_role.arn
}