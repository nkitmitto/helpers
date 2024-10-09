# Lambda Code S3 Bucket
resource "aws_s3_bucket" "dataSources" {
    bucket =  lower("${data.aws_caller_identity.current.account_id}-${var.project_name}-datasources")
}

# I don't know why this resource fails if I call the account ID rather than hardcode the account ID.
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.dataSources.id

  lambda_function {
    lambda_function_arn = "arn:aws:lambda:us-east-1:506980381146:function:dashboardApp-writeDataToDynamodb"
    events              = ["s3:ObjectCreated:*"]
  }
}

# SPA Code S3 Bucket
resource "aws_s3_bucket" "spaBucket" {
    bucket =  lower("${data.aws_caller_identity.current.account_id}-${var.project_name}-spa")
}

resource "aws_s3_bucket_policy" "spaAssignBucketPolicy" {
  bucket = aws_s3_bucket.spaBucket.id
  policy = data.aws_iam_policy_document.spa_bucket_policy.json
}

data "aws_iam_policy_document" "spa_bucket_policy" {
  version = "2008-10-17"
  statement {
    sid = "AllowCloudFront"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.spaBucket.arn}/*"
    ]

    condition {
      test = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        aws_cloudfront_distribution.dashboard-cf.arn
      ]
    }
  }
}