resource "aws_wafv2_ip_set" "apigwipset" {
  name               = "Allow-${var.environment}-${var.project_name}-apigw-ipset"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.dev_allowed_ips
}

resource "aws_wafv2_web_acl" "apigwacl" {
  name        = "${var.environment}-${var.project_name}-APIGW-ACL"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  rule { 
    name =  "Allow-IPs"
    priority = 1

    action {
        allow {}
    }

    statement {
        ip_set_reference_statement {
            arn = aws_wafv2_ip_set.apigwipset.arn
        }
    }

    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.environment}-${var.project_name}-APIGW-AllowIPList"
        sampled_requests_enabled   = true
    }
  }

  rule { 
    name =  "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      count {}
    }

    statement {
        managed_rule_group_statement {
                vendor_name = "AWS"
                name = "AWSManagedRulesAmazonIpReputationList"
        }
    }
    
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.environment}-${var.project_name}-APIGW-ReputationList"
        sampled_requests_enabled   = true
    }
  }

  rule { 
    name =  "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      count {}
    }

    statement {
        managed_rule_group_statement {
                vendor_name = "AWS"
                name = "AWSManagedRulesCommonRuleSet"
        }
    }
    
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.environment}-${var.project_name}-APIGW-AWSManagedRulesCommonRuleSet"
        sampled_requests_enabled   = true
    }
  }

  rule { 
    name =  "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 4
    
    override_action {
      count {}
    }

    statement {
        managed_rule_group_statement {
                vendor_name = "AWS"
                name = "AWSManagedRulesKnownBadInputsRuleSet"
        }
    }
    
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.environment}-${var.project_name}-APIGW-AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-${var.project_name}-APIGW-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "associateAPIGW" {
  resource_arn = aws_api_gateway_stage.httpStage.arn
  web_acl_arn  = aws_wafv2_web_acl.apigwacl.arn
}