variable "name_prefix" {
  description = "The prefix for the name of the key"
  type        = string
}
variable "secrets_manager_parameter" {
  description = "The secret parameter to store file content"
  type        = string
}
variable "ssm_parameter_name_kms_key_id" {
  description = "The ssm parameter to store the key id"
  type        = string
}
variable "description" {
  description = "The description for the key"
  type        = string
}
variable "environment" {
  description = "The environment.  eg: dev/prod"
  type        = string
}
variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "pipelineid" {
  description = "The pipelineid uniquely defining the deployment instance if using CI.  eg: dev/green/blue/main"
  type        = string
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}