terraform {
  backend "s3" {
    bucket         = "infrastructure-state-230982"
    key            = "platform-engineering/bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

