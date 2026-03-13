variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "log_groups" {
  description = "Map of CloudWatch log groups to create, keyed by log group name."
  type = map(object({
    retention_days = number
  }))
  default = {}
}

variable "log_group_policies" {
  description = "List of log group policies, each with log_group_name, policy_name, and policy_document."
  type = list(object({
    log_group_name  = string
    policy_name     = string
    policy_document = string
  }))
  default = []
}

variable "enable_dashboard" {
  description = "Whether to create CloudWatch dashboard"
  type        = bool
  default     = false
}

variable "dashboard_metrics" {
  description = "List of metrics for CloudWatch dashboard"
  type        = list(list(string))
  default     = []
}

variable "metric_alarms" {
  description = "List of CloudWatch metric alarms to create"
  type = list(object({
    name                = string
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    description         = string
    dimensions          = map(string)
  }))
  default = []
}

variable "enable_composite_alarm" {
  description = "Whether to create composite alarm"
  type        = bool
  default     = false
}

variable "composite_alarm_rule" {
  description = "Rule for composite alarm"
  type        = string
  default     = ""
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for notifications"
  type        = string
  default     = ""
}

variable "event_rules" {
  description = "List of CloudWatch event rules to create"
  type = list(object({
    name                = string
    description         = string
    event_pattern       = string
    schedule_expression = string
    target_arn          = string
    input_transformer = object({
      input_paths    = map(string)
      input_template = string
    })
  }))
  default = []
}

variable "log_metric_filters" {
  description = "List of CloudWatch log metric filters"
  type = list(object({
    name             = string
    log_group_name   = string
    pattern          = string
    metric_name      = string
    metric_namespace = string
    metric_value     = string
  }))
  default = []
}

variable "insights_queries" {
  description = "List of CloudWatch Insights queries"
  type = list(object({
    name            = string
    log_group_names = list(string)
    query_string    = string
  }))
  default = []
}

variable "create_sns_topic" {
  description = "Whether to create SNS topic for CloudWatch notifications"
  type        = bool
  default     = false
}

variable "notification_emails" {
  description = "List of email addresses for CloudWatch notifications"
  type        = list(string)
  default     = []
}

variable "enable_synthetics_canary" {
  description = "Whether to enable CloudWatch Synthetics canary"
  type        = bool
  default     = false
}

variable "synthetics_bucket_name" {
  description = "S3 bucket name for Synthetics artifacts"
  type        = string
  default     = ""
}

variable "website_url" {
  description = "Website URL to monitor with Synthetics"
  type        = string
  default     = ""
}

variable "synthetics_schedule" {
  description = "Schedule configuration for Synthetics canary"
  type = object({
    expression          = string
    duration_in_seconds = number
  })
  default = null
}