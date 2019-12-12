resource "aws_iam_role" "lambda-rest-api" {
  name = "${var.project}-lambda-rest-api-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda-rest-api" {
  name = "${var.project}-lambda-rest-api-${var.environment}"
  role = aws_iam_role.lambda-rest-api.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

data "archive_file" "lambda-rest-api" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/rest-api"
  output_path = "${path.module}/lambdas/rest-api.zip"
}

resource "aws_lambda_function" "rest-api" {
  filename         = data.archive_file.lambda-rest-api.output_path
  function_name    = "${var.project}-rest-api-${var.environment}"
  role             = aws_iam_role.lambda-rest-api.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda-rest-api.output_path)
  runtime          = "python3.6"
  timeout          = 60
}

resource "aws_lambda_permission" "rest-api" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rest-api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.projects.execution_arn}/*/*/*"
}

