variable "vpc_id" {}
# variable "pub_subnet" {
#     type = list(string)
# }
variable "pri_subnet" {}
variable "security_group_ids" {
    type = list(string)
}
variable "ec2_iam_role" {
  type = map(object({
    iam_role_name = string
    iam_policy_name = string
    ec2_actions   = string
    region        = string
  }))
}
# variable "ec2_iam_roles" {
#     type = list(map(string))
# }
variable "ec2_config" {
  type = object({
    ec2_ami        = string
    instance_type  = string
    key_name       = string
    resource_name  = string
    instance_count = number
    project = string
    labelname  = string
  })
}