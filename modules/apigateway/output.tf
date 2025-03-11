output "api_gateway_endpoints" {
  value = { for key, api in aws_apigatewayv2_api.http_api : key => "${api.api_endpoint}/start-multiple-ec2" }
}