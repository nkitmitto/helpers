resource "aws_api_gateway_resource" "apigw_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root
  path_part   = var.path
}

resource "aws_api_gateway_method" "method" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = var.method
  authorization = "NONE"
  request_parameters = "${var.querystring != "" ? {"method.request.querystring.${var.querystring}" = true} : {}}"
  depends_on = [
    aws_api_gateway_resource.apigw_resource
  ]
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
  depends_on = [
    aws_api_gateway_resource.apigw_resource,
    aws_api_gateway_method.method,
    aws_lambda_function.lambda_function
  ]
}

resource "aws_api_gateway_integration_response" "response_200" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.method.http_method
  status_code             = "200"

    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = "'*'",
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    }
  
  depends_on = [
    aws_api_gateway_resource.apigw_resource,
    aws_api_gateway_integration.integration,
    aws_api_gateway_method.method
  ]
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.apigw_resource.id
  http_method             = aws_api_gateway_method.method.http_method
  status_code             = "200"
  response_models = {
    "application/json" = "Empty"
  }
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin" = true
  }
  
  depends_on = [
    aws_api_gateway_resource.apigw_resource,
    aws_api_gateway_method.method
  ]
}

# Options Method
resource "aws_api_gateway_method" "method_options" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.apigw_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
  
  request_parameters = {
    "method.request.header.Access-Control-Allow-Headers" = false
    "method.request.header.Access-Control-Allow-Methods" = false
    "method.request.header.Access-Control-Allow-Origin" = false
  }
  
  depends_on = [
    aws_api_gateway_resource.apigw_resource
  ]
}

resource "aws_api_gateway_integration" "integration_options" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.apigw_resource.id
  http_method             = "OPTIONS"
  type                    = "MOCK"

  request_templates = {
      "application/json" = <<EOF
        {"statusCode": 200}
      EOF
  }
  
  depends_on = [
    aws_api_gateway_resource.apigw_resource,
    aws_api_gateway_method.method_options
  ]
}

resource "aws_api_gateway_integration_response" "app_api_gateway_integration_response" {
    rest_api_id             = var.api_gateway_id
    resource_id             = aws_api_gateway_resource.apigw_resource.id
    http_method             = "OPTIONS"
    status_code             = 200
    
    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = "'*'",
      "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
      "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    }
    
    depends_on = [
      aws_api_gateway_resource.apigw_resource,
      aws_api_gateway_integration.integration_options,
      aws_api_gateway_method_response.app_api_gateway_method_response
    ]
}

resource "aws_api_gateway_method_response" "app_api_gateway_method_response" {
    rest_api_id             = var.api_gateway_id
    resource_id             = aws_api_gateway_resource.apigw_resource.id
    http_method             = "OPTIONS"
    status_code             = 200
    response_models = {
      "application/json" = "Empty"
    }
    response_parameters = {
      "method.response.header.Access-Control-Allow-Origin" = true,
      "method.response.header.Access-Control-Allow-Headers" = true,
      "method.response.header.Access-Control-Allow-Methods" = true
    }
    depends_on = [
      aws_api_gateway_resource.apigw_resource,
      aws_api_gateway_method.method_options
    ]
}