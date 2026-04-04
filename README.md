# Terraform AWS CloudWatch Module 📊

> **Comprehensive Terraform module for AWS CloudWatch monitoring, alerting, dashboards, and log management**

[![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A5%201.3-623CE4?logo=terraform)](https://terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-%E2%89%A5%205.0-FF9900?logo=amazon-aws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 **Overview**

This Terraform module creates a complete AWS CloudWatch monitoring infrastructure with custom metrics, alarms, dashboards, log groups, and automated incident response. Perfect for production monitoring, SLA compliance, and operational excellence.

## 🚀 **Features**

### **Core Monitoring**
- 📊 **Custom Dashboards** - Real-time metric visualization
- 🚨 **Smart Alarms** - Multi-dimensional alerting
- 📝 **Log Management** - Centralized log aggregation
- 📈 **Custom Metrics** - Application-specific monitoring
- 🔔 **SNS Integration** - Multi-channel notifications
- 🎯 **Composite Alarms** - Complex alert conditions

### **Advanced Features**
- 🔍 **Log Insights** - Query and analyze logs
- 📊 **Container Insights** - ECS/EKS monitoring
- 🚀 **Lambda Insights** - Serverless performance
- 🎯 **Synthetics** - Synthetic monitoring
- 📈 **Anomaly Detection** - Machine learning alerts
- 🔄 **Auto Remediation** - Lambda-based responses

## 📋 **Usage**

### **Basic Application Monitoring**
```hcl
module "app_monitoring" {
  source = "./terraform-aws-cloudwatch"

  project_name = "my-web-app"
  environment  = "production"

  log_groups_config = {
    "/aws/lambda/api-function" = {
      retention_days = 30

      metric_filters = {
        high_error_rate = {
          pattern          = "ERROR"
          metric_name      = "ErrorCount"
          metric_namespace = "MyApp/Lambda"
          metric_value     = "1"
          
          alarms = {
            high-error-rate = {
              comparison_operator  = "GreaterThanThreshold"
              evaluation_periods   = 2
              period               = 300
              statistic            = "Sum"
              threshold            = 5
              description          = "Lambda error count is too high"
              alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]
              ok_sns_topic_arns    = [aws_sns_topic.ok_alerts.arn]
            }
          }
        }
      }
    }
  }
}
```

### **Comprehensive Infrastructure Monitoring**
```hcl
module "infrastructure_monitoring" {
  source = "./terraform-aws-cloudwatch"

  project_name = "infrastructure"
  environment  = "production"

  log_groups_config = {
    "/aws/ecs/web-app" = {
      retention_days = 14

      metric_filters = {
        error-count = {
          pattern          = "ERROR"
          metric_name      = "ErrorCount"
          metric_namespace = "MyApp/ECS"
          metric_value     = "1"
          
          alarms = {
            web-app-error-rate = {
              comparison_operator  = "GreaterThanThreshold"
              evaluation_periods   = 2
              period               = 300
              statistic            = "Sum"
              threshold            = 10
              description          = "ECS error count is too high"
              alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]
              ok_sns_topic_arns    = [aws_sns_topic.ok_alerts.arn]
            }
          }
        }
      }
    }
  }

  enable_dashboard = true
  dashboard_metrics = [
    ["AWS/ECS", "CPUUtilization", "ClusterName", "production-cluster", "ServiceName", "web-app"]
  ]
}
```

### **Microservices Monitoring with Service Map**
```hcl
module "microservices_monitoring" {
  source = "./terraform-aws-cloudwatch"

  project_name = "microservices"
  environment  = "production"

  log_groups_config = {
    "/ecs/user-service" = {
      retention_days = 30
      metric_filters = {}
    }
  }

  enable_composite_alarm         = true
  composite_alarm_rule           = "ALARM(microservices-user-service-errors)"
  composite_alarm_sns_topic_arns = [aws_sns_topic.alerts.arn]
  composite_ok_sns_topic_arns    = [aws_sns_topic.ok_alerts.arn]
}
```

## 📝 **Input Variables**

### **Required Variables**
| Name | Description | Type |
|------|-------------|------|
| `project_name` | Name of the project | `string` |
| `environment` | Environment (prod/staging/dev) | `string` |

### **Notification Configuration**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `notification_email` | Email for alarm notifications | `string` | `""` |
| `notification_channels` | Multi-channel notification config | `map(object)` | `{}` |
| `sns_topic_name` | Custom SNS topic name | `string` | `""` |

### **Log Management**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `log_groups_config` | Map of log groups with metric filters; each metric filter can have alarms watching its published metrics | `map(object)` | `{}` |
| `log_resource_policy` | Optional CloudWatch Logs resource policy definition | `object` | `null` |

### **Alarms Configuration**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_composite_alarm` | Whether to create a composite alarm | `bool` | `false` |
| `composite_alarm_rule` | Alarm rule for the composite alarm | `string` | `""` |
| `composite_alarm_sns_topic_arns` | SNS topic ARNs to notify when the composite alarm transitions to ALARM state | `list(string)` | `[]` |
| `composite_ok_sns_topic_arns` | SNS topic ARNs to notify when the composite alarm transitions to OK state | `list(string)` | `[]` |

### **Dashboard Configuration**
| Name | Description | Type | Default |
|------|-------------|------|---------|
| `enable_dashboard` | Whether to create the default dashboard | `bool` | `false` |
| `dashboard_metrics` | Metric definitions rendered in the dashboard widget | `list(list(string))` | `[]` |

## 📤 **Outputs**

| Name | Description |
|------|-------------|
| `sns_topic_arn` | SNS topic ARN for notifications |
| `log_group_names` | Names of created log groups |
| `log_group_arns` | ARNs of created log groups |
| `alarm_names` | Names of created alarms |
| `alarm_arns` | ARNs of created alarms |
| `dashboard_urls` | URLs of created dashboards |
| `metric_filter_names` | Names of created metric filters |

## 🏗️ **Architecture**

```
                    ┌─────────────────┐
                    │   Applications  │
                    │   & Services    │
                    └─────────┬───────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │   CloudWatch    │
                    │     Logs        │
                    └─────────┬───────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Metric    │     │   Alarms    │     │ Dashboards  │
│  Filters    │     │ & Anomaly   │     │ & Insights  │
│             │     │ Detection   │     │             │
└─────────┬───┘     └─────────┬───┘     └─────────────┘
          │                   │
          ▼                   ▼
┌─────────────┐     ┌─────────────┐
│   Custom    │     │     SNS     │
│   Metrics   │     │ Notifications│
└─────────────┘     └─────────┬───┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    Email    │     │    Slack    │     │ PagerDuty   │
│ Notifications│     │   Webhooks  │     │  Incidents  │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 🔒 **Security & Compliance**

### **Data Protection**
- 🔐 **Encryption at Rest** - KMS encryption for logs
- 🔒 **Encryption in Transit** - TLS for all communications
- 🛡️ **Access Control** - IAM policies for resources
- 📊 **Audit Logging** - CloudTrail integration

### **Compliance Features**
- 📋 **Retention Policies** - Configurable log retention
- 🔍 **Access Monitoring** - Who accessed what data
- 📈 **Compliance Dashboards** - Regulatory metrics
- 🚨 **Breach Detection** - Unusual access patterns

## 💰 **Cost Optimization**

### **Pricing Components**
- **Logs Ingestion**: $0.50 per GB ingested
- **Logs Storage**: $0.03 per GB per month
- **Custom Metrics**: $0.30 per metric per month
- **API Requests**: $0.01 per 1,000 requests
- **Dashboards**: $3.00 per dashboard per month

### **Cost-Saving Strategies**
- 📊 **Log Retention** - Optimize retention periods
- 🎯 **Metric Filtering** - Reduce unnecessary metrics
- 📈 **Sampling** - Sample high-volume logs
- 🔄 **Log Compression** - Compress before ingestion

## 🧪 **Examples**

Check the [examples](examples/) directory for complete implementations:

- **[Web Application](examples/web-app-monitoring/)** - Complete web app monitoring
- **[Microservices](examples/microservices-monitoring/)** - Service mesh monitoring
- **[Database Monitoring](examples/database-monitoring/)** - RDS and DynamoDB monitoring
- **[Cost Optimization](examples/cost-monitoring/)** - Billing and resource monitoring

## 🔧 **Requirements**

| Name | Version |
|------|---------|
| terraform | >= 1.3.0 |
| aws | >= 5.0 |

## 🧪 **Testing**

```bash
# Validate Terraform configuration
terraform validate

# Test alarm functionality
aws cloudwatch set-alarm-state \
  --alarm-name "test-alarm" \
  --state-value ALARM \
  --state-reason "Testing alarm"

# Query logs
aws logs start-query \
  --log-group-name "/aws/lambda/my-function" \
  --start-time 1609459200 \
  --end-time 1609462800 \
  --query-string 'fields @timestamp, @message | filter @message like /ERROR/'
```

## 📊 **Best Practices**

### **Monitoring Strategy**
- 🎯 **Start with SLIs** - Service Level Indicators first
- 📈 **Use Error Budgets** - Define acceptable failure rates
- 🔄 **Monitor the Monitors** - Alert on monitoring failures
- 📊 **Dashboard Hierarchy** - Executive, operational, diagnostic views

### **Alerting Guidelines**
- 🚨 **Alert on Symptoms** - Not just causes
- 📧 **Notification Fatigue** - Reduce false positives
- 🎯 **Actionable Alerts** - Include remediation steps
- 🔄 **Alert Lifecycle** - Acknowledge, investigate, resolve

### **Performance Optimization**
- 📊 **Batch Metrics** - Reduce API calls
- 🎯 **Efficient Queries** - Optimize Log Insights queries
- 📈 **Metric Math** - Use CloudWatch math for calculations
- 🔄 **Resource Tagging** - Organize monitoring resources

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/monitoring-enhancement`)
3. Commit your changes (`git commit -m 'Add monitoring enhancement'`)
4. Push to the branch (`git push origin feature/monitoring-enhancement`)
5. Open a Pull Request

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏆 **Related Modules**

- **[terraform-aws-s3](../terraform-aws-s3)** - S3 access logging
- **[terraform-aws-lambda](../terraform-aws-lambda)** - Function monitoring
- **[terraform-aws-ecs](../terraform-aws-ecs)** - Container monitoring
- **[terraform-aws-networking](../terraform-aws-networking)** - Network monitoring

---

**📊 Built for enterprise observability and operational excellence**

> *This module demonstrates advanced CloudWatch architecture patterns and monitoring expertise suitable for production environments with comprehensive SLA management.*