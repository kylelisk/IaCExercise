resource "aws_networkfirewall_rule_group" "allow_http_https" {
  #checkov:skip=CKV_AWS_345:Using default encryption for this exercise, CMK not required
  name        = "${var.project_name}-allow-http-https"
  type        = "STATEFUL"
  capacity    = 100
  description = "Allow HTTP and HTTPS traffic, block everything else"

  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "80"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }

      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "443"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }
    }

    # Default action: DROP all other traffic
    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = {
    Name = "${var.project_name}-allow-http-https-rules"
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  #checkov:skip=CKV_AWS_346:Using default encryption for this exercise, CMK not required
  name = "${var.project_name}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_http_https.arn
      priority     = 1
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # Block all traffic that doesn't match the rules
    stateful_default_actions = ["aws:drop_strict"]
  }

  tags = {
    Name = "${var.project_name}-firewall-policy"
  }
}

resource "aws_networkfirewall_firewall" "main" {
  #checkov:skip=CKV_AWS_345:Using default encryption for this exercise, CMK not required
  #checkov:skip=CKV_AWS_344:Deletion protection disabled for easier cleanup in exercise environment
  name                = "${var.project_name}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.main.id
  delete_protection   = true

  # Deploy firewall endpoints in dedicated firewall subnets
  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall[*].id
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name = "${var.project_name}-network-firewall"
  }
}

resource "aws_cloudwatch_log_group" "network_firewall" {
  #checkov:skip=CKV_AWS_338:7-day retention is sufficient for this exercise
  name              = "/aws/networkfirewall/${var.project_name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = {
    Name = "${var.project_name}-firewall-logs"
  }

  depends_on = [aws_kms_key_policy.cloudwatch_logs]
}

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.network_firewall.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
