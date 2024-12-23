variable "region" {
  type        = string
  description = "The AWS region"
}

variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}

variable "lambda_name" {
  type        = string
  description = "The name of the Lambda function"
}

variable "lambda_layer_arn" {
  type        = string
  description = "The ARN of the Lambda layer"
}

variable "event_rule_name" {
  type        = string
  description = "The name of the EventBridge rule"
}

variable "datadog_api_key" {
  type        = string
  description = "The Datadog API key"
  sensitive   = true
}

variable "lambda_role_arn" {
  type = string
  description = "The ARN of the Lambda execution role"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}