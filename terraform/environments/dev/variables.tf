variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cluster_name" {
  type    = string
  default = "game-dev-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.20.0.0/24", "10.20.1.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "domain_name" {
  type    = string
  default = "dev.example.com"
}

variable "route53_zone_name" {
  type    = string
  default = "example.com"
}

variable "acm_certificate_arn" {
  type    = string
  default = ""
}

variable "container_registry" {
  type    = string
  default = "ghcr.io/security-org-230982/simple-game"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "falco_runtime_rules_file" {
  description = "Path to the main Falco runtime rules file"
  type        = string
}

variable "falco_noise_tuning_file" {
  description = "Path to the Falco noise tuning rules file"
  type        = string
}
