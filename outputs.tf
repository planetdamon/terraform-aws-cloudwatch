output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.application_logs : lg.name]
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.application_logs : lg.arn]
}

output "log_group_arns_map" {
  description = "Map of log group names to their ARNs"
  value       = { for name, lg in aws_cloudwatch_log_group.application_logs : name => lg.arn }
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = var.enable_dashboard ? "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main[0].dashboard_name}" : ""
}

output "alarm_names" {
  description = "Names of the CloudWatch alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.application_alarms : alarm.alarm_name]
}

output "alarm_arns" {
  description = "ARNs of the CloudWatch alarms"
  value       = [for alarm in aws_cloudwatch_metric_alarm.application_alarms : alarm.arn]
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch notifications"
  value       = var.create_sns_topic ? aws_sns_topic.cloudwatch_notifications[0].arn : ""
}

output "event_rule_names" {
  description = "Names of the CloudWatch event rules"
  value       = [for rule in aws_cloudwatch_event_rule.custom_events : rule.name]
}

output "event_rule_arns" {
  description = "ARNs of the CloudWatch event rules"
  value       = [for rule in aws_cloudwatch_event_rule.custom_events : rule.arn]
}

output "canary_name" {
  description = "Name of the Synthetics canary"
  value       = var.enable_synthetics_canary ? aws_synthetics_canary.website_monitor[0].name : ""
}

output "canary_arn" {
  description = "ARN of the Synthetics canary"
  value       = var.enable_synthetics_canary ? aws_synthetics_canary.website_monitor[0].arn : ""
}

# S3 Bucket Size Monitoring Outputs
output "s3_bucket_size_alarm_arns" {
  description = "Map of S3 bucket size alarm ARNs"
  value = {
    for k, alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : k => alarm.arn
  }
}

output "s3_bucket_size_alarm_names" {
  description = "Map of S3 bucket size alarm names"
  value = {
    for k, alarm in aws_cloudwatch_metric_alarm.s3_bucket_size : k => alarm.alarm_name
  }
}

output "s3_object_count_alarm_arns" {
  description = "Map of S3 object count alarm ARNs"
  value = {
    for k, alarm in aws_cloudwatch_metric_alarm.s3_object_count : k => alarm.arn
  }
}

output "s3_object_count_alarm_names" {
  description = "Map of S3 object count alarm names"
  value = {
    for k, alarm in aws_cloudwatch_metric_alarm.s3_object_count : k => alarm.alarm_name
  }
}

output "s3_monitored_buckets" {
  description = "List of S3 bucket names being monitored"
  value       = [for k, v in var.s3_buckets_config : v.bucket_name]
}