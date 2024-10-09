data "archive_file" "lambda_function_archive" {
  type = "zip"
  source_dir  = "${path.module}/lambda_functions/${var.lambda_name}"
  output_path = "${path.module}/lambda_functions/${var.lambda_name}.zip"
}

resource "aws_s3_object" "lambda_s3_object" {
  bucket = var.lambda_s3_bucket

  key    = "${var.lambda_name}.zip"
  source = data.archive_file.lambda_function_archive.output_path

  etag = filemd5(data.archive_file.lambda_function_archive.output_path)
}

resource "aws_lambda_function" "lambda_function" {
  function_name = "${var.project_name}-${var.lambda_name}"

  s3_bucket = var.lambda_s3_bucket
  s3_key    = aws_s3_object.lambda_s3_object.key

  runtime = var.runtime
  handler = "${var.lambda_name}.${var.handler}"
  memory_size = var.memory_size
  timeout = var.timeout

  environment {
    variables = {
      dataSourceName = var.dataSourceName
      dataSourceTableName = "${var.dataSourceName}-data"
      dataSourceColumnsTableName = "${var.dataSourceName}-columns"
    }
  }
  
  source_code_hash = data.archive_file.lambda_function_archive.output_base64sha256

  role = var.lambda_exec
}

resource "aws_lambda_permission" "allowBucketExecutionToLambda" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = var.lambda_datasource_bucket_arn
}

resource "aws_cloudwatch_log_group" "lambda_cloudwatch_group" {
  name = "/aws/lambda/${aws_lambda_function.lambda_function.function_name}"
  retention_in_days = 30
}

resource "aws_lambda_permission" "lambda_permissions" {
  statement_id  = "Allow${var.project_name}APIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.lambda_permission_execution_arn}/*/*/*"
}