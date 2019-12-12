resource "aws_s3_bucket" "youtube-videos" {
  bucket        = "${var.company}-${var.project}-youtube-videos-${var.environment}"
  acl           = "public-read"
  force_destroy = true
  region        = var.aws_region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
  }
}

resource "aws_s3_bucket" "images" {
  bucket        = "${var.company}-${var.project}-internet-images-${var.environment}"
  acl           = "public-read"
  force_destroy = true
  region        = var.aws_region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
  }
}
