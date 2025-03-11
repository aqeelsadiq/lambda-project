
variable "lambda_invoke_arns" {
  type = map(string)
}
variable "lambda_function_names" {
  type = map(string)
}

variable "github_repository_name" {}
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
