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

variable "public_key_path" {
  description = "The path to the public key to SSH to instances"
  type        = string
}
