# modules/vpc/variables.tf
variable "vpcs" {}
variable "pub_subnets" {}
variable "pri_subnets" {}
variable "project" {}
variable "identifier" {
  type = map(string)
}