provider "aws" {
  region  = var.aws_region  # Change this to your desired AWS region
  profile = var.aws_profile # Replace with your AWS profile name
}


data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = "./node-js" # Replace with the actual path to your lambda_function.py directory
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "my_lambda_function" {
  function_name = "my-lambda-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

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

resource "aws_api_gateway_rest_api" "lambda_api" {
  name = "lambda-api"
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id # Set the parent ID to the root resource ID
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.my_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_method" "my_method_root" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration_root" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.my_method_root.resource_id
  http_method = aws_api_gateway_method.my_method_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.lambda_integration_root
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "test"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

# resource "aws_cloudwatch_event_rule" "lambda_trigger_rule" {
#   name        = "lambda-trigger-rule"
#   description = "Trigger Lambda function on API Gateway request"
#   event_pattern = jsonencode({
#     source      = ["aws.apigateway"],
#     detail_type = ["AWS API Gateway Execution State Change"],
#     detail = {
#       "statusCode" = ["200"],
#       "httpMethod" = ["ANY"]
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "lambda_target" {
#   rule      = aws_cloudwatch_event_rule.lambda_trigger_rule.name
#   arn       = aws_lambda_function.my_lambda_function.arn
#   target_id = "lambda-function-target"
# }



output "api_gateway_url" {
  value = aws_api_gateway_deployment.lambda_deployment.invoke_url
}
