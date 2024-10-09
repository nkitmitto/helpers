locals {
  s3_origin_id = "DashboardOrigin"
}

resource "aws_s3_bucket" "cf-access" {
  bucket =  lower("${data.aws_caller_identity.current.account_id}-${var.project_name}-cf-accesslogs")
}

resource "aws_s3_bucket_ownership_controls" "cf-access" {
  bucket = aws_s3_bucket.cf-access.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.project_name}-${var.environment}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "dashboard-cf" {
  depends_on = [
    aws_s3_bucket.cf-access
  ]

  web_acl_id = aws_wafv2_web_acl.cfacl.arn
  is_ipv6_enabled = false

  origin {
    domain_name              = aws_s3_bucket.spaBucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.cf-access.id}.s3.amazonaws.com"
    prefix          = "${var.project_name}-${var.environment}"
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code  = 403
    response_code = 200
    response_page_path = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD","GET"]
    cached_methods   = ["HEAD","GET"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "/content/immutable/*"
    allowed_methods  = ["HEAD","GET"]
    cached_methods   = ["HEAD","GET"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "/content/*"
    allowed_methods  = ["HEAD","GET"]
    cached_methods   = ["HEAD","GET"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US"]
    }
  }

  tags = {
    Environment = "${var.environment}"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}