variable "vpc_id" {
  type =map(string)
}
variable "project" {}
variable "security_group" {
  type = list(map(string))
}
