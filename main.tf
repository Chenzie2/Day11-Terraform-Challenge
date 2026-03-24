terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Environment variable with validation
variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# Toggle for using existing VPC
variable "use_existing_vpc" {
  description = "Whether to use an existing VPC or create a new one"
  type        = bool
  default     = false
}

# Centralised conditional logic
locals {
  is_production = var.environment == "production"

  instance_type     = local.is_production ? "t3.medium" : "t3.micro"
  min_size          = local.is_production ? 3 : 1
  max_size          = local.is_production ? 10 : 3
  enable_monitoring = local.is_production

  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id
}

# Conditional data source (existing VPC)
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0

  tags = {
    Name = "existing-vpc"
  }
}

# Conditional resource (new VPC)
resource "aws_vpc" "new" {
  count      = var.use_existing_vpc ? 0 : 1
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "vpc-${var.environment}"
    Environment = var.environment
  }
}

# Conditional CloudWatch alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.enable_monitoring ? 1 : 0

  alarm_name          = "${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80%"
}

# Outputs
output "alarm_arn" {
  value = local.enable_monitoring ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
}

output "vpc_id" {
  value = local.vpc_id
}

output "instance_type" {
  value = local.instance_type
}

output "min_size" {
  value = local.min_size
}

output "max_size" {
  value = local.max_size
}

output "environment" {
  value = var.environment
}