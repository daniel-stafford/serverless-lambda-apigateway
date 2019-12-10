resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.project}-cloudwatch-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  role = aws_iam_role.cloudwatch.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_api_gateway_rest_api" "projects" {
  name        = "${var.project}-projects-${var.environment}"
  description = "Example Projects REST API"
}

resource "aws_api_gateway_model" "project" {
  rest_api_id  = aws_api_gateway_rest_api.projects.id
  name         = "project"
  description  = "Project JSON schema"
  content_type = "application/json"

  schema = <<EOF
{
  "$schema": "http://json-schema.org/draft-04/schema#",
  "title": "Project",
  "type": "object",
  "properties": {
    "name": {
      "type": "string"
    },
    "description": {
      "type": "string"
    },
    "deadline": {
      "type": "string"
    },
    "technologies": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "minItems": 1
    }
  },
  "required": [
    "name",
    "description",
    "deadline",
    "technologies"
  ]
}
EOF
}

resource "aws_api_gateway_resource" "projects" {
  rest_api_id = aws_api_gateway_rest_api.projects.id
  parent_id   = aws_api_gateway_rest_api.projects.root_resource_id
  path_part   = "projects"
}

resource "aws_api_gateway_resource" "project-id" {
  rest_api_id = aws_api_gateway_rest_api.projects.id
  parent_id   = aws_api_gateway_resource.projects.id
  path_part   = "{projectId}"
}

resource "aws_api_gateway_method" "projects" {
  rest_api_id   = aws_api_gateway_rest_api.projects.id
  resource_id   = aws_api_gateway_resource.projects.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "project-insert" {
  rest_api_id          = aws_api_gateway_rest_api.projects.id
  resource_id          = aws_api_gateway_resource.projects.id
  request_validator_id = aws_api_gateway_request_validator.projects.id
  http_method          = "POST"
  authorization        = "NONE"
  request_models = {
    "application/json" = aws_api_gateway_model.project.name
  }

  depends_on = [
    "aws_api_gateway_model.project"
  ]
}

resource "aws_api_gateway_method" "project-update" {
  rest_api_id          = aws_api_gateway_rest_api.projects.id
  resource_id          = aws_api_gateway_resource.projects.id
  request_validator_id = aws_api_gateway_request_validator.projects.id
  http_method          = "PUT"
  authorization        = "NONE"

  request_parameters = {
    "method.request.path.projectId" = true
  }

  request_models = {
    "application/json" = aws_api_gateway_model.project.name
  }

  depends_on = [
    "aws_api_gateway_model.project"
  ]
}

resource "aws_api_gateway_method" "project-get" {
  rest_api_id   = aws_api_gateway_rest_api.projects.id
  resource_id   = aws_api_gateway_resource.project-id.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.projectId" = true
  }
}

resource "aws_api_gateway_method" "project-delete" {
  rest_api_id   = aws_api_gateway_rest_api.projects.id
  resource_id   = aws_api_gateway_resource.project-id.id
  http_method   = "DELETE"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.projectId" = true
  }
}

resource "aws_api_gateway_request_validator" "projects" {
  name                        = "Projects"
  rest_api_id                 = aws_api_gateway_rest_api.projects.id
  validate_request_body       = true
  validate_request_parameters = false
}

resource "aws_api_gateway_request_validator" "project-id" {
  name                        = "ProjectId"
  rest_api_id                 = aws_api_gateway_rest_api.projects.id
  validate_request_body       = false
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "projects" {
  rest_api_id             = aws_api_gateway_rest_api.projects.id
  resource_id             = aws_api_gateway_resource.projects.id
  http_method             = aws_api_gateway_method.projects.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest-api.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<-EOF
    {
      "action" : "get_all"
    }
EOF
  }

  depends_on = [
    "aws_api_gateway_method.projects"
  ]
}

resource "aws_api_gateway_integration" "project-get" {
  rest_api_id             = aws_api_gateway_rest_api.projects.id
  resource_id             = aws_api_gateway_resource.project-id.id
  http_method             = aws_api_gateway_method.project-get.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest-api.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<-EOF
    {
      "action" : "get"
    }
EOF
  }
}

resource "aws_api_gateway_integration" "project-insert" {
  rest_api_id             = aws_api_gateway_rest_api.projects.id
  resource_id             = aws_api_gateway_resource.projects.id
  http_method             = aws_api_gateway_method.project-insert.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest-api.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<-EOF
    {
      "action" : "insert",
      "payload": $input.json('$')
    }
EOF
  }

  depends_on = [
    aws_api_gateway_method.project-insert
  ]
}

resource "aws_api_gateway_integration" "project-update" {
  rest_api_id             = aws_api_gateway_rest_api.projects.id
  resource_id             = aws_api_gateway_resource.projects.id
  http_method             = aws_api_gateway_method.project-update.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest-api.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<-EOF
    {
      "action" : "update",
      "projectId": "$input.params('projectId')",
      "payload": $input.json('$')
    }
EOF
  }
}

resource "aws_api_gateway_integration" "project-delete" {
  rest_api_id             = aws_api_gateway_rest_api.projects.id
  resource_id             = aws_api_gateway_resource.project-id.id
  http_method             = aws_api_gateway_method.project-delete.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.rest-api.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"

  request_templates = {
    "application/json" = <<-EOF
    {
      "action" : "delete",
      "projectId": "$input.params('projectId')"
    }
EOF
  }
}

resource "aws_api_gateway_deployment" "projects" {
  depends_on = [
    aws_api_gateway_integration.projects,
    aws_api_gateway_integration.project-insert,
    aws_api_gateway_integration.project-get,
    aws_api_gateway_integration.project-update,
    aws_api_gateway_integration.project-delete
  ]

  rest_api_id = aws_api_gateway_rest_api.projects.id
}

resource "aws_api_gateway_stage" "dev" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.projects.id
  deployment_id = aws_api_gateway_deployment.projects.id
}

resource "aws_api_gateway_method_settings" "settings" {
  rest_api_id = aws_api_gateway_rest_api.projects.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    data_trace_enabled = true
    logging_level      = "INFO"
  }
}

resource "aws_api_gateway_method_response" "project-insert-200" {
  rest_api_id = aws_api_gateway_rest_api.projects.id
  resource_id = aws_api_gateway_resource.projects.id
  http_method = aws_api_gateway_method.project-insert.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "project-insert-200" {
  rest_api_id = aws_api_gateway_rest_api.projects.id
  resource_id = aws_api_gateway_resource.projects.id
  http_method = aws_api_gateway_method.project-insert.http_method
  status_code = aws_api_gateway_method_response.project-insert-200.status_code

  response_templates = {
    "application/json" = <<EOF
    {
      "body": $input.json('$')
    }
EOF
  }
}
