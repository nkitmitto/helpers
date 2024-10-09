resource "aws_dynamodb_table" "dashboardData" {
  name           = "${var.dataSourceName}-data"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key  = var.hash_key

  dynamic attribute {
    for_each = var.attributes

    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  tags = {
    Name        = "${var.project_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_dynamodb_table" "dashboardDataColumns" {
  name           = "${var.dataSourceName}-columns"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "dashboard"

  attribute {
    name = "dashboard"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}"
    Environment = "${var.environment}"
  }
}

resource "aws_dynamodb_table" "dashboardMetadata" {
  name           = "${var.dataSourceName}-metadata"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "dashboard"

  attribute {
    name = "dashboard"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}"
    Environment = "${var.environment}"
  }
}