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

variable "log_groups_config" {
  description = "Map of log groups with metric filters; each metric filter can have alarms watching its published metrics"
  type = map(object({
    retention_days = number
    metric_filters = optional(map(object({
      pattern          = string
      metric_name      = string
      metric_namespace = string
      metric_value     = string
      alarms = optional(map(object({
        comparison_operator  = string
        evaluation_periods   = number
        period               = number
        statistic            = string
        threshold            = number
        description          = string
        alarm_sns_topic_arns = list(string)
        ok_sns_topic_arns    = optional(list(string), [])
      })), {})
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for _, log_cfg in var.log_groups_config : [
        for _, filter_cfg in log_cfg.metric_filters : [
          for _, alarm_cfg in filter_cfg.alarms :
          length(alarm_cfg.alarm_sns_topic_arns) > 0
        ]
      ]
    ]))
    error_message = "Each alarm in log_groups_config must define at least one alarm SNS topic ARN in alarm_sns_topic_arns."
  }
}

variable "synthetics_schedule" {
  description = "Schedule configuration for Synthetics canary"
  type = object({
    expression          = string
    duration_in_seconds = number
  })
  default = null
}

variable "log_resource_policy" {
  description = "Account-level CloudWatch Logs resource policy. Accepts either policy_document (raw JSON) or statements (structured). Only one allowed."
  type = object({
    name            = string
    policy_document = optional(string)
    statements = optional(list(object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = list(string)
      principal = optional(any)
      condition = optional(any)
    })), [])
  })
  default = null

  validation {
    condition = (
      var.log_resource_policy == null ||
      (
        (
          try(trim(var.log_resource_policy.policy_document), "") != "" &&
          length(var.log_resource_policy.statements) == 0
        ) ||
        (
          try(trim(var.log_resource_policy.policy_document), "") == "" &&
          length(var.log_resource_policy.statements) > 0
        )
      )
    )
    error_message = "log_resource_policy must use only one source: either policy_document or statements, not both."
  }

  validation {
    condition = (
      var.log_resource_policy == null ||
      (
        try(trim(var.log_resource_policy.policy_document), "") != "" ||
        length(var.log_resource_policy.statements) > 0
      )
    )
    error_message = "log_resource_policy must provide either policy_document or at least one statement."
  }

  validation {
    condition = (
      var.log_resource_policy == null ||
      alltrue([
        for statement in var.log_resource_policy.statements :
        length(statement.resources) > 0
      ])
    )
    error_message = "Each policy statement in log_resource_policy must include at least one resource ARN."
  }
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

variable "composite_alarm_sns_topic_arns" {
  description = "SNS topic ARNs to notify when the composite alarm transitions to ALARM state"
  type        = list(string)
  default     = []
}

variable "composite_ok_sns_topic_arns" {
  description = "SNS topic ARNs to notify when the composite alarm transitions to OK state"
  type        = list(string)
  default     = []
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
