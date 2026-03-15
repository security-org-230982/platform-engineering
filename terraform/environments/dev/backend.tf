terraform {
  backend "s3" {
    bucket         = "infrastructure-state-230982"
    key            = "platform-engineering/dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile = true
    encrypt        = true
  }

  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
