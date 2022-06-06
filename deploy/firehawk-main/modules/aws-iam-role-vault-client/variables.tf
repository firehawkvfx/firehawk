variable "role_name" {
    description = "The name for the role"
    type = string
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
variable "conflictkey" {
    description = "The conflictkey is a unique name for each deployement usuallly consisting of the resourcetier and the pipeid."
    type = string
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}