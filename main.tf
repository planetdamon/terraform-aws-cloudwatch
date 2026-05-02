locals {
  log_groups = {
    for log_group_name, log_group in var.log_groups_config : log_group_name => {
      name           = log_group_name
      retention_days = log_group.retention_days
    }
  }

  log_metric_filters = length(var.log_groups_config) > 0 ? merge([
    for log_group_name, log_group in var.log_groups_config : {
      for filter_name, metric_filter in log_group.metric_filters : "${log_group_name}:${filter_name}" => {
        name             = filter_name
        log_group_name   = log_group_name
        pattern          = metric_filter.pattern
        metric_name      = metric_filter.metric_name
        metric_namespace = metric_filter.metric_namespace
        metric_value     = metric_filter.metric_value
      }
    }
  ]...) : {}

  metric_alarms = length(var.log_groups_config) > 0 ? merge([
    for log_group_name, log_group in var.log_groups_config :
    merge([
      for filter_name, filter in log_group.metric_filters : {
        for alarm_name, alarm in filter.alarms : "${log_group_name}:${filter_name}:${alarm_name}" => {
          name                 = alarm_name
          log_group_name       = log_group_name
          filter_name          = filter_name
          comparison_operator  = alarm.comparison_operator
          evaluation_periods   = alarm.evaluation_periods
          metric_name          = filter.metric_name
          namespace            = filter.metric_namespace
          period               = alarm.period
          statistic            = alarm.statistic
          threshold            = alarm.threshold
          description          = alarm.description
          alarm_sns_topic_arns = alarm.alarm_sns_topic_arns
          ok_sns_topic_arns    = alarm.ok_sns_topic_arns
        }
      }
    ]...)
  ]...) : {}

  log_resource_policy = (
    var.log_resource_policy != null ? {
      name = var.log_resource_policy.name
      policy_document = try(trim(var.log_resource_policy.policy_document), "") != "" ? var.log_resource_policy.policy_document : jsonencode({
        Version = "2012-10-17"
        Statement = [
          for statement in var.log_resource_policy.statements : merge(
            {
              Effect   = statement.effect
              Action   = statement.actions
              Resource = statement.resources
            },
            try(statement.sid, null) != null ? { Sid = statement.sid } : {},
            try(statement.principal, null) != null ? { Principal = statement.principal } : {},
            try(statement.condition, null) != null ? { Condition = statement.condition } : {}
          )
        ]
      })
    } : null
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "application_logs" {
  for_each          = local.log_groups
  name              = each.value.name
  retention_in_days = each.value.retention_days

  tags = {
    Name        = each.value.name
    Environment = var.environment
    Application = var.project_name
  }
}

resource "aws_cloudwatch_log_resource_policy" "main" {
  count           = local.log_resource_policy != null ? 1 : 0
  policy_name     = local.log_resource_policy.name
  policy_document = local.log_resource_policy.policy_document
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
  for_each = local.metric_alarms

  alarm_name          = "${var.project_name}-${each.value.name}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  alarm_actions       = each.value.alarm_sns_topic_arns
  ok_actions          = each.value.ok_sns_topic_arns

  tags = {
    Name        = "${var.project_name}-${each.value.name}"
    Environment = var.environment
  }
}

# CloudWatch Composite Alarm
resource "aws_cloudwatch_composite_alarm" "main" {
  count = var.enable_composite_alarm ? 1 : 0

  alarm_name        = "${var.project_name}-composite-alarm"
  alarm_description = "Composite alarm for ${var.project_name}"
  alarm_rule        = var.composite_alarm_rule
  alarm_actions     = var.composite_alarm_sns_topic_arns
  ok_actions        = var.composite_ok_sns_topic_arns
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
  for_each = local.log_metric_filters

  name           = "${var.project_name}-${each.value.name}"
  log_group_name = each.value.log_group_name
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = each.value.metric_namespace
    value     = each.value.metric_value
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

# ========================================
# S3 Bucket Size Monitoring
# ========================================

# CloudWatch Metric Alarm for S3 Bucket Size
# AWS publishes BucketSizeBytes metrics to CloudWatch daily

//TODO: #6 paramaterize collection period
resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  for_each = var.s3_buckets_config

  alarm_name          = "${var.project_name}-${each.key}-size-alarm"
  alarm_description   = "Alert when ${each.value.bucket_name} exceeds ${each.value.threshold_gb}GB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = 86400 # 24 hours (S3 metrics are published daily)
  statistic           = "Average"
  threshold           = each.value.threshold_gb * 1024 * 1024 * 1024 # Convert GB to bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = each.value.bucket_name
    StorageType = each.value.storage_type
  }

  alarm_actions = each.value.alarm_sns_topic_arns
  ok_actions    = each.value.ok_sns_topic_arns

  tags = {
    Name        = "${var.project_name}-${each.key}-size-alarm"
    BucketName  = each.value.bucket_name
    Environment = var.environment
  }
}

# Optional: CloudWatch Metric Alarm for Number of Objects
//TODO: #7 paramaterize collection period
resource "aws_cloudwatch_metric_alarm" "s3_object_count" {
  for_each = { for k, v in var.s3_buckets_config : k => v if v.enable_object_count_alarm }

  alarm_name          = "${var.project_name}-${each.key}-object-count-alarm"
  alarm_description   = "Alert when ${each.value.bucket_name} exceeds ${each.value.object_count_threshold} objects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 86400 # 24 hours
  statistic           = "Average"
  threshold           = each.value.object_count_threshold
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = each.value.bucket_name
    StorageType = "AllStorageTypes"
  }

  alarm_actions = each.value.alarm_sns_topic_arns
  ok_actions    = each.value.ok_sns_topic_arns

  tags = {
    Name        = "${var.project_name}-${each.key}-object-count-alarm"
    BucketName  = each.value.bucket_name
    Environment = var.environment
  }
}