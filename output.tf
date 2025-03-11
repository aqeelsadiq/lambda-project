output "vpc_ids" {
  value = module.vpc.vpc_ids
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "api_gateway_execution_arn" {
    value = module.apigateway.api_gateway_endpoints
}


output "lambda_invoke_arns" {
    value = module.lambda.lambda_invoke_arns
}

output "lambda_function_names" {
    value = module.lambda.lambda_function_names
  
}