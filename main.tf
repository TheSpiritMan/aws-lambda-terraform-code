provider "aws" {
  region  = var.aws_region  # Change this to your desired AWS region
  profile = var.aws_profile # Replace with your AWS profile name
}


data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = "./python-code" # Replace with the actual path to your lambda_function.py directory
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name = "my-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"

  filename = data.archive_file.lambda_function_zip.output_path
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_api_gateway_rest_api" "my_api" {
  name = "my-api"
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id # Set the parent ID to the root resource ID
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.my_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "my_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"
}

resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
  name        = "lambda-trigger-rule"
  description = "Trigger Lambda function on API Gateway request"
  event_pattern = jsonencode({
    source      = ["aws.apigateway"],
    detail_type = ["AWS API Gateway Execution State Change"],
    detail = {
      "statusCode" = ["200"],
      "httpMethod" = ["ANY"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger_rule.name
  arn       = aws_lambda_function.my_lambda_function.arn
  target_id = "lambda-function-target"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.my_deployment.invoke_url
}
