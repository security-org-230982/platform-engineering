🚀 Platform Engineering – Secure EKS Deployment

This repository manages infrastructure provisioning, application deployment, and runtime validation on AWS EKS using Terraform, Helm, and GitHub Actions.

It integrates with the security-engineering repository to enforce consistent DevSecOps controls.

🎯 Purpose

This repository is responsible for:

Provisioning AWS infrastructure (VPC, EKS)

Deploying applications via Helm

Enforcing runtime security configurations

Orchestrating security workflows from security-engineering

🧩 What This Repo Does
☁️ Infrastructure

AWS VPC

EKS cluster

Node groups

IAM roles (IRSA)

🚀 Application Deployment

Helm-based deployment (simple-game)

ALB Ingress exposure

Kubernetes namespace + PSA enforcement

🔐 Security Integration

This repo consumes reusable workflows from:

security-org-230982/security-engineering

Including:

Image signing verification (Cosign)

Helm chart scanning

IaC scanning

CIS benchmark validation

PSA alignment check

📁 Repository Structure
.github/workflows/
  ├── terraform-plan.yaml
  ├── deploy.yaml

terraform/
  └── environments/dev/
      ├── main.tf
      ├── variables.tf
      ├── backend.tf
      ├── helm-addons.tf

helm/
  └── simple-game/
      ├── templates/
      ├── values.yaml
🔄 CI/CD Workflows
🧪 terraform-plan.yaml (Pull Request)

Runs pre-deployment security and validation checks:

Secrets scan (Gitleaks)

IaC scan (Trivy)

Helm chart scan (manifest + RBAC)

Image signing verification (Cosign)

Terraform plan

👉 Purpose:

Validate before merge
🚀 deploy.yaml (Post Merge)

Runs actual deployment and runtime validation:

Image signature verification

Terraform apply (EKS + app)

Pod Security Admission (PSA) validation

CIS Kubernetes benchmark

👉 Purpose:

Deploy and validate runtime security
🔐 Security Architecture
GitHub Actions (OIDC)
        ↓
AWS IAM Role (AssumeRole)
        ↓
Terraform → EKS
        ↓
Helm → Application
        ↓
ALB → External Access
🔏 Image Security

Images are built in another repo (product-engineering)

Pushed to GHCR

Signed using Cosign

Verified here before deployment

Only trusted, signed images are deployed
☸️ Kubernetes Security
Pod Security Admission (PSA)

Namespace enforced with:

pod-security.kubernetes.io/enforce: restricted

Ensures:

non-root containers

no privilege escalation

seccomp profile enforced

CIS Benchmark

Post-deployment validation ensures cluster compliance with:

Kubernetes CIS Benchmark

Node and control plane security checks

Note: This is for learning purpose!!!