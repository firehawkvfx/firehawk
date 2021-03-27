variable "vault_public_key" {
  description = "The public key of the host used to ssh into the vault cluster"
  type = string
  default = ""
}
variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "common_tags" {
  description = "Common tags for all resources in a deployment run."
  type        = map(string)
}

variable "aws_key_name" {
  description = "The name of the AWS PEM key for access to the instance"
  type        = string
}