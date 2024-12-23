output "frankfurt_s3_bucket_name" {
  value = module.frankfurt.s3_bucket_name
}

output "frankfurt_lambda_function_name" {
  value = module.frankfurt.lambda_function_name
}

output "tokyo_s3_bucket_name" {
  value = module.tokyo.s3_bucket_name
}

output "tokyo_lambda_function_name" {
  value = module.tokyo.lambda_function_name
}

output "frankfurt_eventbridge_rule_arn" {
  value = module.frankfurt.eventbridge_rule_arn
}

output "frankfurt_eventbridge_schedule" {
  value = module.frankfurt.eventbridge_schedule
}

output "tokyo_eventbridge_rule_arn" {
  value = module.tokyo.eventbridge_rule_arn
}

output "tokyo_eventbridge_schedule" {
  value = module.tokyo.eventbridge_schedule
}
