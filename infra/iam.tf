# -----------------------------------------------------------------------------
# Get current AWS account ID
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

# -----------------------------------------------------------------------------
# Lambda execution role policy
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "rpc-monitor-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name         = "rpc-monitor-lambda-role"
    Environment  = "Production"
    Organization = "dydxprotocol"
  }
}

# -----------------------------------------------------------------------------
# Lambda CloudWatch logging permissions
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Lambda S3 access policy
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_s3_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.frankfurt_bucket_name}",
      "arn:aws:s3:::${var.frankfurt_bucket_name}/*",
      "arn:aws:s3:::${var.tokyo_bucket_name}",
      "arn:aws:s3:::${var.tokyo_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "rpc-monitor-lambda-s3-policy"
  description = "Policy for RPC monitor Lambda to access S3"
  policy      = data.aws_iam_policy_document.lambda_s3_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# -----------------------------------------------------------------------------
# Terraform Cloud Role
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "terraform_cloud_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws_account_id}:root"]
    }
  }
}

resource "aws_iam_role" "terraform_cloud_role" {
  name               = "tfc_workspace_role"
  assume_role_policy = data.aws_iam_policy_document.terraform_cloud_assume_role.json

  tags = {
    Name         = "terraform-cloud-role"
    Environment  = "Production"
    Organization = "dydxprotocol"
  }
}
# -----------------------------------------------------------------------------
# EventBridge role and permissions
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "eventbridge_role" {
  name               = "rpc-monitor-eventbridge-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json

  tags = {
    Name         = "rpc-monitor-eventbridge-role"
    Environment  = "Production"
    Organization = "dydxprotocol"
  }
}

data "aws_iam_policy_document" "eventbridge_lambda_policy" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [
      "arn:aws:lambda:${var.frankfurt_region}:${local.aws_account_id}:function:${var.frankfurt_lambda_name}",
      "arn:aws:lambda:${var.tokyo_region}:${local.aws_account_id}:function:${var.tokyo_lambda_name}"
    ]
  }
}

resource "aws_iam_policy" "eventbridge_lambda" {
  name        = "rpc-monitor-eventbridge-lambda"
  description = "Allow EventBridge to invoke RPC monitor Lambda functions"
  policy      = data.aws_iam_policy_document.eventbridge_lambda_policy.json
}

resource "aws_iam_role_policy_attachment" "eventbridge_lambda" {
  role       = aws_iam_role.eventbridge_role.name
  policy_arn = aws_iam_policy.eventbridge_lambda.arn
}

resource "aws_iam_role_policy_attachment" "terraform_cloud_policy" {
  role       = aws_iam_role.terraform_cloud_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}