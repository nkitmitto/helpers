data "aws_caller_identity" "current" {}

module lambda_functions {
  for_each = var.lambda_functions
  source = "./lambda_function_module"
  lambda_name = each.key
  lambda_s3_bucket = aws_s3_bucket.appLambdas.id
  lambda_exec = aws_iam_role.lambda_exec.arn
  lambda_datasource_bucket = aws_s3_bucket.dataSources.id
  lambda_datasource_bucket_arn = aws_s3_bucket.dataSources.arn
  project_name = var.project_name
  lambda_permission_execution_arn = aws_api_gateway_rest_api.httpAPI.execution_arn
  querystring = each.value.querystring
  dataSourceName = var.dataSourceName
  memory_size = each.value.memory_size
  timeout = each.value.timeout
  runtime = each.value.runtime
  handler = each.value.handler
  
  # API Gateway
  api_gateway_id = aws_api_gateway_rest_api.httpAPI.id
  api_gateway_root = aws_api_gateway_rest_api.httpAPI.root_resource_id
  path = each.value.path
  method = each.value.method
  integration_type = each.value.integration_type
  integration_http_method = each.value.integration_http_method
}

# Lambda Code S3 Bucket
resource "aws_s3_bucket" "appLambdas" {
    bucket =  lower("${data.aws_caller_identity.current.account_id}-${var.project_name}-lambdas")
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}_serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}