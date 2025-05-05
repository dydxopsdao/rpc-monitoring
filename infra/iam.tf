# -----------------------------------------------------------------------------
# Get current AWS account ID
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# No longer needed here as we are looking up existing roles
# locals {
#   aws_account_id = data.aws_caller_identity.current.account_id
# }

# -----------------------------------------------------------------------------
# Look up existing Lambda execution role
# -----------------------------------------------------------------------------
data "aws_iam_role" "lambda_exec_role" {
  name = "rpc-monitor-lambda-role" # The exact name of the existing role
}

# -----------------------------------------------------------------------------
# Look up existing EventBridge role
# -----------------------------------------------------------------------------
data "aws_iam_role" "eventbridge_role" {
  name = "rpc-monitor-eventbridge-role" # The exact name of the existing role
}

# -----------------------------------------------------------------------------
# Ensure Lambda CloudWatch logging permissions are attached
# (AWSLambdaBasicExecutionRole is a managed policy, we just ensure attachment)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = data.aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -----------------------------------------------------------------------------
# Look up existing Lambda S3 access policy
# -----------------------------------------------------------------------------
data "aws_iam_policy" "lambda_s3_policy" {
  # Construct the ARN using the current account ID and the known policy name
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/rpc-monitor-lambda-s3-policy"
}

# -----------------------------------------------------------------------------
# Ensure Lambda S3 policy is attached to the Lambda role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_s3" {
  role       = data.aws_iam_role.lambda_exec_role.name
  policy_arn = data.aws_iam_policy.lambda_s3_policy.arn
}

# -----------------------------------------------------------------------------
# Look up existing EventBridge Lambda invocation policy
# -----------------------------------------------------------------------------
data "aws_iam_policy" "eventbridge_lambda" {
  # Construct the ARN using the current account ID and the known policy name
  arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/rpc-monitor-eventbridge-lambda"
}

# -----------------------------------------------------------------------------
# Ensure EventBridge Lambda policy is attached to the EventBridge role
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "eventbridge_lambda" {
  role       = data.aws_iam_role.eventbridge_role.name
  policy_arn = data.aws_iam_policy.eventbridge_lambda.arn
}