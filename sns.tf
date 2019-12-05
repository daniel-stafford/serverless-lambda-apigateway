resource "aws_sns_topic" "recognition-notification" {
  name = "${var.project}-recognition-notification-${var.environment}"
}

resource "aws_sns_topic_subscription" "recognition-notification-lambda" {
  topic_arn = aws_sns_topic.recognition-notification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.recognition-post-process.arn
}
