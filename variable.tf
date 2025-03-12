variable "region" {}

variable "ec2_iam_role" {
  type = map(object({
    iam_role_name = string
    iam_policy_name = string
    ec2_actions   = string
    region        = string
  }))
}

variable "ec2_config" {
  type = object({
    ec2_ami        = string
    instance_type  = string
    key_name       = string
    resource_name  = string
    instance_count = number
    project = string
    labelname = string
  })
}
# # modules/vpc/variables.tf
variable "vpcs" {}
variable "pub_subnets" {}
variable "pri_subnets" {}
variable "project" {}
variable "identifier" {
  type = map(string)
}
variable "security_group" {
  type = list(map(string))
}
variable "lambda_functions" {
  type = map(object({
    function_name   = string
    runtime         = string
    timeout         = string
    handler         = string
    iam_role_name   = string
    iam_policy_name = string
    ec2_actions     = string
    region          = string
  }))
}


variable "action" {}
variable "principle" {}
variable "statement_id" {}

variable "api_gateway_config" {
  type = map(object({
    api_name         = string
    protocol_type    = string
    integration_type = string
    auto_deploy      = bool
    lambda_action    = string
    lambda_principal = string
    project          = string
    region  = string
  }))
}

variable "github_repository_name" {}
variable "github_owner" {}