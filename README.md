# RPC Monitor Infrastructure

This repository contains the infrastructure code for deploying and managing RPC monitoring Lambda functions across multiple AWS regions (Tokyo and Frankfurt).

## Overview
The infrastructure deploys Lambda functions that:
- Monitor RPC endpoint health and performance
- Run every 5 minutes in each region
- Send metrics to Datadog for monitoring
- Store Lambda code in regional S3 buckets

## Architecture
- **Regions**: Frankfurt (eu-central-1) and Tokyo (ap-northeast-1)
- **Components per Region**:
  - S3 Bucket: Stores Lambda deployment packages
  - Lambda Function: Executes RPC monitoring code
  - EventBridge Rule: Triggers Lambda every 5 minutes
  - CloudWatch Logs: Captures Lambda execution logs
  - IAM Roles & Policies: Manages permissions

## Prerequisites
- Terraform ~> 1.10.3
- AWS Account access
- Datadog API key
- Terraform Cloud account

## Infrastructure Setup

### 1. AWS Resources
The infrastructure creates:
- S3 buckets for Lambda code storage
- Lambda functions with 5-minute execution schedule
- Required IAM roles and policies
- EventBridge rules for scheduling

### 2. Deployment
1. Clone this repository
2. Update variables in `frankfurt.tfvars` and `tokyo.tfvars` if needed
3. Commit and push changes
4. Terraform Cloud will automatically plan and apply changes

## File Structure
infra/
├── terraform/
│   ├── module/
│   │   ├── main.tf         # Module resources
│   │   ├── variables.tf    # Module variables
│   │   └── outputs.tf      # Module outputs
│   ├── main.tf            # Root configuration
│   ├── variables.tf       # Root variables
│   ├── outputs.tf         # Root outputs
│   ├── iam.tf            # IAM configurations
│   ├── frankfurt.tfvars  # Frankfurt variables
│   └── tokyo.tfvars      # Tokyo variables
└── rpc_monitor/
└── [Lambda function code]


## Outputs
The infrastructure outputs:
- S3 bucket names
- Lambda function names
- EventBridge rule ARNs and schedules
- Lambda function ARNs

## Maintenance
### Updating Lambda Code
1. Update code in rpc_monitor directory
2. Create new zip package
3. Update will be handled by Terraform

### Monitoring
- Check Datadog for metrics
- Review CloudWatch logs for Lambda execution details
- Monitor EventBridge for scheduling issues

