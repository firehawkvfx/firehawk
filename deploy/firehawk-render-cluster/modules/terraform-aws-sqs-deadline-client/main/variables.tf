variable "resourcetier" {
  description = "The resource tier uniquely defining the deployment area.  eg: dev/green/blue/main"
  type        = string
}
variable "instance_id" {
  description = "The Instance ID that will retrigger sending this data"
  type = string
  default = ""
}