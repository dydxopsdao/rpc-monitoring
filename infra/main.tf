terraform {
  cloud {
    organization = "dydxopsdao"
    workspaces {
      name = "rpc-monitoring"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83.1"
    }
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.4"
    }
  }

  required_version = "~> 1.10.3"
}

provider "aws" {
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "frankfurt"
  region = var.frankfurt_region
}

provider "aws" {
  alias  = "tokyo"
  region = var.tokyo_region
}

module "frankfurt" {
  source = "./module"

  providers = {
    aws = aws.frankfurt
  }

  region           = var.frankfurt_region
  bucket_name      = var.frankfurt_bucket_name
  lambda_name      = var.frankfurt_lambda_name
  lambda_layer_arn = var.frankfurt_lambda_layer_arn
  event_rule_name  = var.frankfurt_event_rule_name
  datadog_api_key  = var.datadog_api_key
  lambda_role_arn  = data.aws_iam_role.lambda_exec_role.arn
}

module "tokyo" {
  source = "./module"

  providers = {
    aws = aws.tokyo
  }

  region           = var.tokyo_region
  bucket_name      = var.tokyo_bucket_name
  lambda_name      = var.tokyo_lambda_name
  lambda_layer_arn = var.tokyo_lambda_layer_arn
  event_rule_name  = var.tokyo_event_rule_name
  datadog_api_key  = var.datadog_api_key
  lambda_role_arn  = data.aws_iam_role.lambda_exec_role.arn
}