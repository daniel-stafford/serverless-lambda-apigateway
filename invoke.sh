#!/bin/bash

source ./terraform-utils.sh

if [ $# -lt 1 ]; then
  echo "Usage: $0 <function_name> <payload>"
  exit 1
fi

aws_access_key=$(terraform_get var.aws_access_key)
aws_secret_key=$(terraform_get var.aws_secret_key)
aws_region=$(terraform_get var.aws_region)

name=$1
function_name=$(terraform_get aws_lambda_function.$name.function_name)

shift
payload='{}'
if [ $# -gt 0 ]; then
  payload="$1"
fi

AWS_ACCESS_KEY_ID=$aws_access_key \
AWS_SECRET_ACCESS_KEY=$aws_secret_key \
AWS_DEFAULT_REGION=$aws_region \
aws lambda invoke \
  --function-name $function_name \
  --payload "$payload" \
  --output json \
  /tmp/${name}.json && jq '.' /tmp/${name}.json && echo
