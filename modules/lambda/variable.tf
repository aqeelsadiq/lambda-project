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
variable "project" {}
