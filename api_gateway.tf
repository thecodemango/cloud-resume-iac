#API Gateway

#Creating the API
resource "aws_apigatewayv2_api" "iac_api_gw" {
  name          = "iac_api_gw"
  protocol_type = "HTTP"

  cors_configuration {
    allow_credentials = false
    allow_headers     = []
    allow_methods = [
      "GET",
      "PUT",
    ]
    allow_origins = [
      "*",
    ]
    expose_headers = []
    max_age        = 0
  }

  tags = {
    project = var.project
  }
}

#Stage configuration
resource "aws_apigatewayv2_stage" "iac_api_stage" {
  api_id      = aws_apigatewayv2_api.iac_api_gw.id
  name        = "$default"
  auto_deploy = true

  #Defining logging settings. Optional, but highly recommended for troubleshooting
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_log.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }

}

#Integration with put_count lambda function
resource "aws_apigatewayv2_integration" "iac_put_integration" {
  api_id           = aws_apigatewayv2_api.iac_api_gw.id
  integration_type = "AWS_PROXY"

  integration_uri = aws_lambda_function.lambda_put.invoke_arn
}

#Integration with get_count lambda function
resource "aws_apigatewayv2_integration" "iac_get_integration" {
  api_id           = aws_apigatewayv2_api.iac_api_gw.id
  integration_type = "AWS_PROXY"

  integration_uri = aws_lambda_function.lambda_get.invoke_arn
}

#Routes configuration
resource "aws_apigatewayv2_route" "iac_put_route" {
  api_id    = aws_apigatewayv2_api.iac_api_gw.id
  route_key = "PUT /put_count/{n}"

  target = "integrations/${aws_apigatewayv2_integration.iac_put_integration.id}"
}

resource "aws_apigatewayv2_route" "iac_get_route" {
  api_id    = aws_apigatewayv2_api.iac_api_gw.id
  route_key = "GET /get_count"

  target = "integrations/${aws_apigatewayv2_integration.iac_get_integration.id}"
}

#Creation of log_group for the api
resource "aws_cloudwatch_log_group" "api_gw_log" {
  name              = "/aws/api_gw/${aws_apigatewayv2_api.iac_api_gw.name}"
  retention_in_days = 0
  tags = {
    project = var.project
  }
}

#Definition of resource-based policies to allow API Gateway to invoke the lambda functions

#put_count
resource "aws_lambda_permission" "api_gw_put" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_put.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.iac_api_gw.execution_arn}/*/*/put_count/{n}"
}

#get_count
resource "aws_lambda_permission" "api_gw_get" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.iac_api_gw.execution_arn}/*/*/get_count"
}