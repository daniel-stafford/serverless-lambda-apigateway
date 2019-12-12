resource "aws_iam_role" "video-recognition" {
  name = "${var.project}-video-recognition-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "rekognition.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "video-recognition" {
  name = "${var.project}-video-recognition-${var.environment}"
  role = aws_iam_role.video-recognition.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": [
        "sns:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_sns_topic.recognition-notification.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role" "lambda-recognition-post-process" {
  name = "${var.project}-lambda-recognition-post-process-${var.environment}"

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

resource "aws_iam_role_policy" "lambda-recognition-post-process" {
  name = "${var.project}-lambda-recognition-post-process-${var.environment}"
  role = aws_iam_role.lambda-recognition-post-process.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Action": [
        "rekognition:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

data "archive_file" "lambda-recognition-post-process" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/recognition-post-process"
  output_path = "${path.module}/lambdas/recognition-post-process.zip"
}

resource "aws_lambda_function" "recognition-post-process" {
  filename         = data.archive_file.lambda-recognition-post-process.output_path
  function_name    = "${var.project}-recognition-post-process-${var.environment}"
  role             = aws_iam_role.lambda-recognition-post-process.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda-recognition-post-process.output_path)
  runtime          = "nodejs8.10"
  timeout          = 60
}

resource "aws_lambda_permission" "recognition-post-process" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.recognition-post-process.arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.recognition-notification.arn
}
