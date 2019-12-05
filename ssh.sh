#!/bin/bash

if ! echo true | terraform console|grep -v "state lock." &> /dev/null; then
  echo "Terraform has not been initialized properly"
  exit 1
fi

terraform_get() {
  echo $(echo "$1"|terraform console|grep -v "state lock.")
}

ec2_public_ip=$(terraform_get aws_instance.api-server.public_ip)
ssh -i instance-private.key ubuntu@$ec2_public_ip
