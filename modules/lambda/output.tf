
output "lambda_invoke_arns" {
  value = { for key, lambda in aws_lambda_function.lambda : key => lambda.invoke_arn }
}

output "lambda_function_names" {
  value = { for key, lambda in aws_lambda_function.lambda : key => lambda.function_name }
}


