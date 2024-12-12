# Lambda RPC Checker README

This document provides an overview of the **Lambda RPC Checker** and steps to deploy, configure, and update it across the two AWS regions (Tokyo and Frankfurt).

---

## **Overview**
The Lambda RPC Checker is a Node.js-based AWS Lambda function designed to:
1. Measure the latency and block heights of multiple RPC providers.
2. Identify the active RPC provider used by a specific web application.
3. Send results to Datadog for monitoring and logging.

---

## **Features**
- **Ping Providers**: Measures latency and retrieves block height from multiple RPC endpoints.
- **Check RPC Provider**: Detects which RPC provider the application is actively using.
- **Datadog Integration**: Sends logs with metrics and tags to Datadog for observability.
- **AWS Regions**: Deployed in **Tokyo** and **Frankfurt**, running every 5 minutes.

---

## **Pre-requisites**
1. **Node.js**: Installed to install dependencies locally.
2. **Datadog API Key**: Set in Lambda environment variables (`DD_API_KEY`).
3. **S3 Buckets**:
   - `rpc-checker-tokyo`
   - `rpc-checker-frankfurt`
4. **Lambda Functions**:
   - `rpc-checker-tokyo`
   - `rpc-checker-frankfurt`

---

## **Deployment Steps**

### 1. Prepare the Code
1. Clone the repository or save the script as `check_rpc.js`.
2. Install dependencies:
   ```bash
   npm init -y
   npm install axios puppeteer-core @sparticuz/chromium
   ```
3. Ensure the `package.json` and `node_modules` are in the same directory as `check_rpc.js`.
4. Create a zip file containing the code and dependencies:
   ```bash
   zip -r rpc-checker.zip
   ```

---

### 2. Deploy the Code to AWS Lambda
1. Upload the zip file to the appropriate S3 bucket for the region:
   - For Tokyo: Upload to `rpc-checker-tokyo`
   - For Frankfurt: Upload to `rpc-checker-frankfurt`
2. Open the **AWS Lambda Console**.
3. Navigate to the Lambda function for the desired region (`rpc-checker-tokyo` or `rpc-checker-frankfurt`).
4. Under the **Code** section, choose **Upload from > Amazon S3**.
5. Enter the S3 object URL of the uploaded zip file (e.g., `s3://rpc-checker-tokyo/rpc-checker.zip`).
6. Save changes and wait for the update to complete.

---

### 3. Verify and Test
1. Confirm the update was successful by reviewing the **Last modified** timestamp in the AWS Lambda Console.
2. Test the function manually:
   - Use the **Test** tab in the AWS Lambda Console.
   - Review the execution logs in CloudWatch for errors or successful results.

---

## **Schedule the Lambda Function**
The Lambda functions are configured to run every 5 minutes using AWS EventBridge.

To update the schedule:
1. Open the EventBridge Rule associated with the Lambda in the AWS Console.
2. Modify the schedule expression if needed (e.g., `rate(5 minutes)`).

---

## **Environment Variables**
The following environment variables are required for each Lambda function:
- `DD_API_KEY`: Your Datadog API key.

---

## **Key Points**
- **Datadog Tags**: The logs sent to Datadog include environment, provider, and region tags for better observability.
- **Puppeteer**: Uses headless Chromium for detecting RPC providers through request interception.

---

For additional troubleshooting or customization, refer to the CloudWatch logs of the Lambda functions or contact your system administrator.
