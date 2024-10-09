resource "aws_api_gateway_rest_api" "httpAPI" {
  name          = "${var.project_name}-http-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


# Deploy API Gateway Stage
resource "aws_api_gateway_deployment" "httpAPI" {
  rest_api_id = aws_api_gateway_rest_api.httpAPI.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.httpAPI.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "httpStage" {
  deployment_id = aws_api_gateway_deployment.httpAPI.id
  rest_api_id   = aws_api_gateway_rest_api.httpAPI.id
  stage_name    = "${var.environment}"
  
  depends_on = [
    aws_api_gateway_deployment.httpAPI
  ]
}

resource "null_resource" "deployAPIGatewayStage" {
  triggers = {
    always_run = "${timestamp()}"
  }
  
  provisioner "local-exec" {
    command = "aws apigateway create-deployment --rest-api-id ${aws_api_gateway_rest_api.httpAPI.id} --stage-name ${var.environment} --region us-east-1"
  }
}
