locals {
  sns_topic_arns = [for t in var.sns_topic_arns : t.arn]
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each          = var.log_groups
  name              = each.key
  retention_in_days = each.value.retention_days

  tags = {
    Name        = each.key
    Environment = var.environment
    Application = var.project_name
  }
}

# CloudWatch Log Resource Policies (per log group)
resource "aws_cloudwatch_log_resource_policy" "custom_policy" {
  count           = length(var.log_group_policies)
  policy_name     = var.log_group_policies[count.index].policy_name
  policy_document = var.log_group_policies[count.index].policy_document
}


# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.enable_dashboard ? 1 : 0
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = var.dashboard_metrics
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms for Application Metrics
resource "aws_cloudwatch_metric_alarm" "application_alarms" {
  count = length(var.metric_alarms)

  alarm_name          = "${var.project_name}-${var.environment}-${var.metric_alarms[count.index].name}"
  comparison_operator = var.metric_alarms[count.index].comparison_operator
  evaluation_periods  = var.metric_alarms[count.index].evaluation_periods
  metric_name         = var.metric_alarms[count.index].metric_name
  namespace           = var.metric_alarms[count.index].namespace
  period              = var.metric_alarms[count.index].period
  statistic           = var.metric_alarms[count.index].statistic
  threshold           = var.metric_alarms[count.index].threshold
  alarm_description   = var.metric_alarms[count.index].description
  alarm_actions       = local.sns_topic_arns
  actions_enabled     = true
  dimensions          = var.metric_alarms[count.index].dimensions

  tags = {
    Name        = "${var.project_name}-${var.metric_alarms[count.index].name}"
    Environment = var.environment
  }
}

# CloudWatch Composite Alarm
resource "aws_cloudwatch_composite_alarm" "main" {
  count = var.enable_composite_alarm ? 1 : 0

  alarm_name        = "${var.project_name}-composite-alarm"
  alarm_description = "Composite alarm for ${var.project_name}"
  alarm_rule        = var.composite_alarm_rule
  alarm_actions     = local.sns_topic_arns
  ok_actions        = local.sns_topic_arns

  tags = {
    Name        = "${var.project_name}-composite-alarm"
    Environment = var.environment
  }
}

# CloudWatch Event Rules for Custom Events
resource "aws_cloudwatch_event_rule" "custom_events" {
  count = length(var.event_rules)

  name                = "${var.project_name}-${var.event_rules[count.index].name}"
  description         = var.event_rules[count.index].description
  event_pattern       = var.event_rules[count.index].event_pattern
  schedule_expression = var.event_rules[count.index].schedule_expression

  tags = {
    Name        = "${var.project_name}-${var.event_rules[count.index].name}"
    Environment = var.environment
  }
}

# CloudWatch Event Targets
resource "aws_cloudwatch_event_target" "targets" {
  count     = length(var.event_rules)
  rule      = aws_cloudwatch_event_rule.custom_events[count.index].name
  target_id = "Target${count.index}"
  arn       = var.event_rules[count.index].target_arn

  dynamic "input_transformer" {
    for_each = var.event_rules[count.index].input_transformer != null ? [var.event_rules[count.index].input_transformer] : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}

# CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "filters" {
  count = length(var.log_metric_filters)

  name           = "${var.project_name}-${var.log_metric_filters[count.index].name}"
  log_group_name = var.log_metric_filters[count.index].log_group_name
  pattern        = var.log_metric_filters[count.index].pattern

  metric_transformation {
    name      = var.log_metric_filters[count.index].metric_name
    namespace = var.log_metric_filters[count.index].metric_namespace
    value     = var.log_metric_filters[count.index].metric_value
  }
}

# CloudWatch Insights Queries (for common queries)
resource "aws_cloudwatch_query_definition" "insights_queries" {
  count = length(var.insights_queries)

  name            = "${var.project_name}-${var.insights_queries[count.index].name}"
  log_group_names = var.insights_queries[count.index].log_group_names
  query_string    = var.insights_queries[count.index].query_string
}

# SNS Topic for CloudWatch Notifications
resource "aws_sns_topic" "cloudwatch_notifications" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-cloudwatch-notifications"

  tags = {
    Name        = "${var.project_name}-cloudwatch-notifications"
    Environment = var.environment
  }
}

# SNS Topic Subscription
resource "aws_sns_topic_subscription" "email_notifications" {
  count     = var.create_sns_topic && length(var.notification_emails) > 0 ? length(var.notification_emails) : 0
  topic_arn = aws_sns_topic.cloudwatch_notifications[0].arn
  protocol  = "email"
  endpoint  = var.notification_emails[count.index]
}

# CloudWatch Synthetics Canary (for website monitoring)
resource "aws_synthetics_canary" "website_monitor" {
  count                = var.enable_synthetics_canary ? 1 : 0
  name                 = "${var.project_name}-website-monitor"
  artifact_s3_location = "s3://${var.synthetics_bucket_name}/"
  execution_role_arn   = aws_iam_role.synthetics_role[0].arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = "synthetics/nodejs/node_modules/pageLoadBlueprint.js"
  runtime_version      = "syn-nodejs-puppeteer-3.8"

  dynamic "schedule" {
    for_each = var.synthetics_schedule != null ? [var.synthetics_schedule] : []
    content {
      expression          = schedule.value.expression
      duration_in_seconds = schedule.value.duration_in_seconds
    }
  }

  run_config {
    memory_in_mb       = 960
    timeout_in_seconds = 60
    environment_variables = {
      URL = var.website_url
    }
  }

  tags = {
    Name        = "${var.project_name}-website-monitor"
    Environment = var.environment
  }
}

# IAM Role for Synthetics Canary
resource "aws_iam_role" "synthetics_role" {
  count = var.enable_synthetics_canary ? 1 : 0
  name  = "${var.project_name}-synthetics-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-synthetics-role"
    Environment = var.environment
  }
}

# IAM Policy for Synthetics Canary
resource "aws_iam_role_policy_attachment" "synthetics_policy" {
  count      = var.enable_synthetics_canary ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsExecutionRolePolicy"
  role       = aws_iam_role.synthetics_role[0].name
}
