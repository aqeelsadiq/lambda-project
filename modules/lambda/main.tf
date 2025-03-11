data "aws_ssm_parameter" "github_token" {
  name = "/lambda/github-token"
}

data "aws_ssm_parameter" "repo_owner" {
  name = "/lambda/github-owner"
}

data "aws_ssm_parameter" "repo_name" {
  name = "/lambda/githubrepo-name"
}


resource "aws_iam_role" "lambda_role" {
  for_each = var.lambda_functions

  name = "${terraform.workspace}-${each.value.region}-${each.value.iam_role_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_ec2_policy" {
  for_each = var.lambda_functions

  name   = each.value.iam_policy_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = split(",", each.value.ec2_actions)
        Resource = "*"
      }
      # {
      #   Effect   = "Allow"
      #   Action   = "ssm:GetParameter"
      #   Resource = "arn:aws:ssm:us-west-1:489994096722:parameter/lambda/*"
      # }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ec2_attach" {
  for_each = var.lambda_functions

  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = aws_iam_policy.lambda_ec2_policy[each.key].arn
}

data "archive_file" "zip_the_python_code" {
  for_each = var.lambda_functions

  type        = "zip"
  source_dir  = "${path.root}/app/"
  output_path = "${path.root}/app/${each.key}.zip"
}

resource "aws_lambda_function" "lambda" {
  for_each = var.lambda_functions

  function_name = "${terraform.workspace}-${each.value.region}-${each.key}"
  role          = aws_iam_role.lambda_role[each.key].arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  filename      = "${path.root}/app/${each.key}.zip"
  timeout       = tonumber(each.value.timeout)

  environment {
    variables = {
      GITHUB_TOKEN = data.aws_ssm_parameter.github_token.value
      GITHUB_OWNER   = data.aws_ssm_parameter.repo_owner.value
      REPO_NAME    = data.aws_ssm_parameter.repo_name.value
    }
  }
  depends_on = [aws_iam_role_policy_attachment.lambda_ec2_attach]

  tags = {
    project     = var.project
    environment = terraform.workspace
  }
}

resource "aws_lambda_permission" "invoke_lambda" {
  for_each = var.lambda_functions

  statement_id  = var.statement_id
  action        = var.action
  function_name = aws_lambda_function.lambda[each.key].function_name
  principal     = var.principle
}

resource "aws_lambda_function_url" "lambda_url" {
  for_each          = aws_lambda_function.lambda
  function_name     = each.value.function_name
  authorization_type = "NONE"
}


