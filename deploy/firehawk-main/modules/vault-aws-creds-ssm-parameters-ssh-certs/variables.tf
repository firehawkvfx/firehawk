variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "sqs_send_arns" {
  description = "A list of SQS queue ARNS's the secret key may send messages to"
  type        = list(string)
}
variable "sqs_recieve_arns" {
  description = "A list of SQS queue ARNS's the secret key may recieve messages from"
  type        = list(string)
}
variable "vault_aws_secret_backend_path" {
  description = "The path for the aws secret backend"
  type        = string
}
variable "backend_name" {
  description = "The name / path where the backend will generate cred from"
  type        = string
}