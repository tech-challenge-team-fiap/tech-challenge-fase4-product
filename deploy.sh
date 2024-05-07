#!/bin/bash

# Deploy infrastructure using Terraform
cd infra
terraform init
terraform validate
terraform apply -auto-approve -var "aws_access_key=${AWS_ACCESS_KEY}" -var "aws_secret_key=${AWS_SECRET_KEY}"
cd ..

echo "Deployment completed!"