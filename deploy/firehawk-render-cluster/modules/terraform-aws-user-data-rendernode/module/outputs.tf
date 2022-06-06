# output "user_data" {
#   value = data.template_file.user_data_auth_client.rendered
# }

output "user_data_base64" {
  value     = base64encode(data.template_file.user_data_auth_client.rendered)
  sensitive = true
}
