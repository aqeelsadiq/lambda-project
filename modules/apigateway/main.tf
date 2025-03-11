resource "aws_apigatewayv2_api" "http_api" {
  for_each = var.api_gateway_config

  name          = "${terraform.workspace}-${each.value.region}-${each.value.api_name}"
  protocol_type = each.value.protocol_type

  tags = {
    project     = each.value.project
    environment = terraform.workspace
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  for_each         = var.lambda_function_names
  api_id           = aws_apigatewayv2_api.http_api[one(keys(var.api_gateway_config))].id
  integration_type = var.api_gateway_config[one(keys(var.api_gateway_config))].integration_type
  integration_uri  = var.lambda_invoke_arns[each.key]
}

resource "aws_apigatewayv2_route" "lambda_route" {
  for_each  = var.lambda_function_names
  api_id    = aws_apigatewayv2_api.http_api[one(keys(var.api_gateway_config))].id
  route_key = "POST /${each.key}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration[each.key].id}"
}

resource "aws_apigatewayv2_stage" "http_stage" {
  for_each    = var.api_gateway_config
  api_id      = aws_apigatewayv2_api.http_api[each.key].id
  name        = "$default"
  auto_deploy = each.value.auto_deploy
}

resource "aws_lambda_permission" "apigateway_invoke_lambda" {
  for_each      = var.lambda_function_names
  statement_id  = "AllowExecutionFromAPIGatewayStart-${each.key}"
  action        = var.api_gateway_config[one(keys(var.api_gateway_config))].lambda_action
  function_name = each.value
  principal     = var.api_gateway_config[one(keys(var.api_gateway_config))].lambda_principal
  source_arn    = "${aws_apigatewayv2_api.http_api[one(keys(var.api_gateway_config))].execution_arn}/*/*"
}


resource "github_repository_webhook" "webhook" {
  repository = var.github_repository_name

  configuration {
    url          = "${aws_apigatewayv2_stage.http_stage[one(keys(var.api_gateway_config))].invoke_url}/start-multiple-ec2"
    content_type = "json"
    insecure_ssl = false
  }

  active = true
  events = ["push", "workflow_job"]
  depends_on = [ aws_apigatewayv2_stage.http_stage ]
}
