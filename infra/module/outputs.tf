output "s3_bucket_name" {
  value       = aws_s3_bucket.bucket.id
  description = "The name of the created S3 bucket"
}

output "lambda_function_name" {
  value       = aws_lambda_function.lambda.function_name
  description = "The name of the created Lambda function"
}

output "eventbridge_rule_arn" {
  value       = aws_cloudwatch_event_rule.every_five_minutes.arn
  description = "The ARN of the EventBridge rule"
}

output "eventbridge_rule_name" {
  value       = aws_cloudwatch_event_rule.every_five_minutes.name
  description = "The name of the EventBridge rule"
}

output "eventbridge_schedule" {
  value       = aws_cloudwatch_event_rule.every_five_minutes.schedule_expression
  description = "The schedule expression for the EventBridge rule"
}