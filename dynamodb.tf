resource "aws_dynamodb_table" "projects" {
  name           = "Projects"
  read_capacity  = 5
  write_capacity = 2
  hash_key       = "projectId"

  attribute {
    name = "projectId"
    type = "S"
  }
}

resource "aws_dynamodb_table" "video-labels" {
  name           = "VideoLabels"
  read_capacity  = 5
  write_capacity = 2
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
