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

provider "github" {
  token = var.github_token
  owner = var.github_owner
}