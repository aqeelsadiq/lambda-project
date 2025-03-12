# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "5.69.0"
#     }
#   }
# }

provider "aws" {
  region = var.region
}


data "aws_ssm_parameter" "github_token" {
  name = "/lambda/github-token"
  with_decryption = true
}


provider "github" {
  token = data.aws_ssm_parameter.github_token.value
  owner = var.github_owner
}