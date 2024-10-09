resource "aws_wafv2_ip_set" "cfipset" {
  name               = "Allow-${var.environment}-${var.project_name}-cf-ipset"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = var.dev_allowed_ips
}

resource "aws_wafv2_web_acl" "cfacl" {
  name        = "${var.environment}-${var.project_name}-ACL"
  scope       = "CLOUDFRONT"

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
            arn = aws_wafv2_ip_set.cfipset.arn
        }
    }
    visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.environment}-${var.project_name}-AllowIPList"
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
        metric_name                = "${var.environment}-${var.project_name}-ReputationList"
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
        metric_name                = "${var.environment}-${var.project_name}-AWSManagedRulesCommonRuleSet"
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
        metric_name                = "${var.environment}-${var.project_name}-AWSManagedRulesKnownBadInputsRuleSet"
        sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-${var.project_name}-waf"
    sampled_requests_enabled   = true
  }
}