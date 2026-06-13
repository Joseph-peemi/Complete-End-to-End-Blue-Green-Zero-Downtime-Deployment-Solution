# ── Metric Alarms ─────────────────────────────────────────────────────────────
# ── Log Groups ────────────────────────────────────────────────────────────────
# Declared here because cloudwatch.tf references them in the dashboard.
# ECS tasks also reference these via awslogs-group in the task definition.

resource "aws_cloudwatch_log_group" "blue" {
  name              = "/ecs/aspnetapp/blue"
  retention_in_days = 30

  tags = { Name = "aspnetapp-blue-logs" }
}

resource "aws_cloudwatch_log_group" "green" {
  name              = "/ecs/aspnetapp/green"
  retention_in_days = 30

  tags = { Name = "aspnetapp-green-logs" }
}
resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${var.project_name}-5xx-rate"
  alarm_description   = "HTTP 5xx error rate exceeds 1%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "errors / requests * 100"
    label       = "5xx Error Rate (%)"
    return_data = true
  }

  metric_query {
    id = "errors"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id = "requests"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
      period      = 60
      stat        = "Sum"
    }
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "latency_p99" {
  alarm_name          = "${var.project_name}-latency-p99"
  alarm_description   = "p99 latency exceeds 2 seconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 2
  treat_missing_data  = "notBreaching"

  metric_query {
    id = "latency"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "TargetResponseTime"
      dimensions  = { LoadBalancer = aws_lb.main.arn_suffix }
      period      = 60
      stat        = "p99"
    }
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project_name}-unhealthy-hosts"
  alarm_description   = "One or more targets are unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0
  treat_missing_data  = "notBreaching"

  metric_query {
    id = "unhealthy_hosts"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "UnHealthyHostCount"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
        TargetGroup  = aws_lb_target_group.blue.arn_suffix
      }
      period = 60
      stat   = "Maximum"
    }
    return_data = true
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# ── SNS Topic for alarm notifications ─────────────────────────────────────────

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-deployment-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# ── CloudWatch Dashboard ───────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-deployments"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "Request count + 5xx errors"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix]
          ]
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Target response time p50/p99"
          region = var.aws_region
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "p50" }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix, { stat = "p99" }]
          ]
        }
      },
      {
        type = "log"
        properties = {
          title   = "Deployment alarms"
          region  = var.aws_region
          query   = "fields @timestamp, @message | filter @message like /ALARM/ | stats count() by @message"
          logGroupNames = [
            aws_cloudwatch_log_group.blue.name,
            aws_cloudwatch_log_group.green.name
          ]
        }
      }
    ]
  })
}

