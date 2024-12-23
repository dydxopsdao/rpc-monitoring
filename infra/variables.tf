variable "frankfurt_region" {
  type        = string
  description = "The AWS region for Frankfurt resources"
  default     = "eu-central-1"
}

variable "frankfurt_bucket_name" {
  type        = string
  description = "The name of the S3 bucket in Frankfurt"
}

variable "frankfurt_lambda_name" {
  type        = string
  description = "The name of the Lambda function in Frankfurt"
}

variable "frankfurt_lambda_s3_bucket" {
  type        = string
  description = "The S3 bucket for the Lambda function code in Frankfurt"
}

variable "frankfurt_lambda_layer_arn" {
  type        = string
  description = "The ARN of the Lambda layer in Frankfurt"
}

variable "frankfurt_event_rule_name" {
  type        = string
  description = "The name of the EventBridge rule in Frankfurt"
}

variable "tokyo_region" {
  type        = string
  description = "The AWS region for Tokyo resources"
  default     = "ap-northeast-1"
}

variable "tokyo_bucket_name" {
  type        = string
  description = "The name of the S3 bucket in Tokyo"
}

variable "tokyo_lambda_name" {
  type        = string
  description = "The name of the Lambda function in Tokyo"
}

variable "tokyo_lambda_s3_bucket" {
  type        = string
  description = "The S3 bucket for the Lambda function code in Tokyo"
}

variable "tokyo_lambda_layer_arn" {
  type        = string
  description = "The ARN of the Lambda layer in Tokyo"
}

variable "tokyo_event_rule_name" {
  type        = string
  description = "The name of the EventBridge rule in Tokyo"
}

variable "datadog_api_key" {
  type        = string
  description = "The Datadog API key"
  sensitive   = true
}