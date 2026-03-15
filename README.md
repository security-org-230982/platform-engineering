# platform-engineering

This repository provisions an AWS EKS cluster with Terraform, stores state in S3 + DynamoDB locking,
deploys a sample game app via Helm, and reuses security workflows
from the `security-engineering` repository.

## Layout
- `terraform/bootstrap` - one-time backend bootstrap (S3 + DynamoDB + KMS)
- `terraform/environments/dev` - EKS, IAM, IRSA, networking
- `helm/simple-game` - sample application chart and ingress
- `.github/workflows` - CI/CD and reusable workflow consumers
- `scripts` - local helpers

## Prerequisites
- AWS account and permissions to create IAM, EKS, VPC, Route53, ACM, and S3 resources
- Configure GitHub Actions authentication outside Terraform if you still want CI/CD to deploy into AWS.
- GitHub organization with these repositories:
  - `platform-engineering`
  - `product-engineering`
  - `security-engineering`
- GitHub Actions OIDC trust configured for this repository

## Notes
- Replace `your-org`, `dev.example.com`, Route53 zone, ACM certificate ARN, and account IDs.
- Apply `terraform/bootstrap` once before initializing remote state in environment stacks.
