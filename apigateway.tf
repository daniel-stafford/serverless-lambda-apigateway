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
      }
    }
  }
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
  stage_name  = "test"
}
