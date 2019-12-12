resource "aws_iam_role" "lambda-youtube-downloader" {
  name = "${var.project}-lambda-youtube-downloader-${var.environment}"

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

resource "aws_iam_role_policy" "lambda-youtube-downloader" {
  name = "${var.project}-lambda-youtube-downloader-${var.environment}"
  role = aws_iam_role.lambda-youtube-downloader.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.youtube-videos.arn}/*",
				"*"
      ]
    },
    {
      "Action": [
        "rekognition:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "iam:PassRole"
      ],
      "Effect": "Allow",
      "Resource": "${aws_iam_role.video-recognition.arn}"
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

data "archive_file" "lambda-youtube-downloader" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/youtube-downloader"
  output_path = "${path.module}/lambdas/youtube-downloader.zip"
}

resource "aws_lambda_function" "youtube-downloader" {
  filename         = data.archive_file.lambda-youtube-downloader.output_path
  function_name    = "${var.project}-youtube-downloader-${var.environment}"
  role             = aws_iam_role.lambda-youtube-downloader.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256(data.archive_file.lambda-youtube-downloader.output_path)
  runtime          = "nodejs8.10"
  timeout          = 60
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.youtube-videos.bucket
      SNS_ARN     = aws_sns_topic.recognition-notification.arn
      ROLE_ARN    = aws_iam_role.video-recognition.arn
    }
  }
}

