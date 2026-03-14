output "log_group_names" {
  description = "Names of the CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.application_logs : lg.name]
}

output "log_group_arns" {
  description = "ARNs of the CloudWatch log groups"
  value       = [for lg in aws_cloudwatch_log_group.application_logs : lg.arn]
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
  description = "Effective SNS topic ARN for CloudWatch notifications"
  value       = local.effective_sns_topic_arn
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