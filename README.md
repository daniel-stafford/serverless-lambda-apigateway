# Serverless: Introduction to AWS Lambda & API Gateway

## Setup
1. Make sure you complete the steps in the [Preparation](https://github.com/Integrify-Finland/infrastructure-as-code-intro) for your AWS credentials setup
2. Clone this repository
3. Create a file called `terraform.tfvars` and put in it following information:
```
aws_region = "us-east-1"
aws_access_key = "<access_key>"
aws_secret_key = "<secret_key>"
```
Where `<access_key>` and `<secret_key>` are your AWS IAM user credentials

4. Bring up the infrastructure as instructed in [How to run](https://github.com/Integrify-Finland/infrastructure-as-code-intro) section


## Test
1. Hello Lambda:
```
./invoke.sh '{"name": "Your name"}'
```

2. Image object detection/recognition:
```
./invoke.sh detect-image-label '{"imageUrl": "<url">}'
```

3. Youtube video object detection/recognition:
```
./invoke.sh youtube-downloader '{"videoUrl": "<youtube_video_url>"}'
```

4. REST API:
* Get the DNS of the API Gateway:
```
echo output.api_gateway_invoke_url | terraform console
```

* Get all projects:
```
curl -X GET <dns>/projects | jq '.'
```

* Get one project:
```
curl -X GET <dns>/projects/<project_id> | jq '.'
```

* Create one project:
```
curl -X POST <dns>/projects -H "content-type: application/json" -d '{"name": "Test", "description": "Test project", "deadline": "today", "technologies": ["React", "Javascript"]}' | jq '.'
```

* Update one project:
```
curl -X PUT <dns>/projects/<project_id> -H "content-type: application/json" -d '{"name": "Test", "description": "Test project", "deadline": "today", "technologies": ["React", "Javascript"]}' | jq '.'
```

* Delete one project:
```
curl -X DELETE <dns>/projects/<project_id>
```

## Destroy
Remember to ALWAYS destroy the infrastructure once you've finished experimenting or you'll get a bill from AWS.
```
terraform destroy -force
```
