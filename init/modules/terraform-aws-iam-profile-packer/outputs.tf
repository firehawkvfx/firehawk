output "instance_role_arn" {
  value = aws_iam_role.instance_role.arn
}
output "instance_profile_arn" {
  value = aws_iam_instance_profile.instance_profile.arn
}
output "instance_role_name" {
  value = aws_iam_role.instance_role.name
}
output "instance_profile_name" {
  value = aws_iam_role.instance_role.name
}