resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name         = var.bucket_name
    Environment  = "Production"
    Organization = "dydxprotocol"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "lambda_zip" {
  bucket = aws_s3_bucket.bucket.id
  key    = "rpc_monitor.zip"
  source = "${path.module}/../../rpc_monitor/rpc_monitor.zip"
  etag   = filemd5("${path.module}/../../rpc_monitor/rpc_monitor.zip")
}

resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_name
  runtime       = "nodejs18.x"
  handler       = "check_rpc.handler"
  role          = var.lambda_role_arn

  memory_size = 2048
  timeout     = 300
  ephemeral_storage {
    size = 512
  }

  s3_bucket = aws_s3_bucket.bucket.id
  s3_key    = aws_s3_object.lambda_zip.key

  environment {
    variables = {
      REGION       = var.region
      ORGANIZATION = "dydxprotocol"
      DD_API_KEY   = var.datadog_api_key
    }
  }

  layers = [
    var.lambda_layer_arn
  ]

  tags = {
    Name         = var.lambda_name
    Organization = "dydxprotocol"
    DeploymentTime = timestamp()
  }

  depends_on = [aws_s3_object.lambda_zip]
}

resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name                = var.event_rule_name
  description         = "Triggers the Lambda function every 5 minutes in ${var.region}"
  schedule_expression = "rate(5 minutes)"
  state = "ENABLED"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "InvokeLambdaFunction"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}