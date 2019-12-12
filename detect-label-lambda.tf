resource "aws_iam_role" "lambda-detect-image-label" {
  name = "${var.project}-lambda-detect-image-label-${var.environment}"

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

resource "aws_iam_role_policy" "lambda-detect-image-label" {
  name = "${var.project}-lambda-detect-image-label-${var.environment}"
  role = aws_iam_role.lambda-detect-image-label.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rekognition:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:*"
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

data "archive_file" "lambda-detect-image-label" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/detect-image-labels"
  output_path = "${path.module}/lambdas/detect-image-labels.zip"
}

resource "aws_lambda_function" "detect-image-label" {
  filename         = data.archive_file.lambda-detect-image-label.output_path
  function_name    = "${var.project}-detect-image-label-${var.environment}"
  role             = aws_iam_role.lambda-detect-image-label.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda-detect-image-label.output_path)
  runtime          = "python3.6"
  timeout          = 60

  environment {
    variables = {
      BUCKET= aws_s3_bucket.images.bucket
    }
  }
}
