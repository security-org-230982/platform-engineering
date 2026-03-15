#!/usr/bin/env bash
set -euo pipefail
cd terraform/bootstrap
terraform init
terraform apply -auto-approve   -var="state_bucket_name=$1"   -var="region=${2:-us-east-1}"
