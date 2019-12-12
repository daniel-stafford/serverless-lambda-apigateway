data "archive_file" "lambda-hello" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/hello"
  output_path = "${path.module}/lambdas/hello.zip"
}

resource "aws_iam_role" "lambda-hello" {
  name = "${var.project}-lambda-hello-${var.environment}"

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

resource "aws_lambda_function" "hello" {
  filename         = data.archive_file.lambda-hello.output_path
  function_name    = "${var.project}-hello-${var.environment}"
  role             = aws_iam_role.lambda-hello.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda-hello.output_path)
  runtime          = "python3.6"
  timeout          = 60
}
