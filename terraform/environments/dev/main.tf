provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "simple-game"
      Environment = var.environment
      ManagedBy   = "terraform"
      Repository  = "platform-engineering"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true
  create_cloudwatch_log_group              = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }
}

module "irsa_ingress" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.cluster_name}-aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

module "irsa_external_dns" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = "${var.cluster_name}-external-dns"

  role_policy_arns = {
    route53 = aws_iam_policy.external_dns.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-dns"]
    }
  }
}

resource "aws_iam_policy" "external_dns" {
  name = "${var.cluster_name}-external-dns"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["route53:ChangeResourceRecordSets"],
        Resource = ["arn:aws:route53:::hostedzone/*"]
      },
      {
        Effect   = "Allow",
        Action   = ["route53:ListHostedZones", "route53:ListResourceRecordSets"],
        Resource = ["*"]
      }
    ]
  })
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

locals {
  falco_runtime_rules = file(var.falco_runtime_rules_file)
  falco_noise_tuning  = file(var.falco_noise_tuning_file)

  falco_values = templatefile("${path.module}/falco-values.yaml.tmpl", {
    falco_runtime_rules = local.falco_runtime_rules
    falco_noise_tuning  = local.falco_noise_tuning
  })
}

resource "kubernetes_namespace" "simple_game" {
  metadata {
    name = "simple-game"

    labels = {
      "pod-security.kubernetes.io/enforce"         = "restricted"
      "pod-security.kubernetes.io/enforce-version" = "v1.30"
      "pod-security.kubernetes.io/audit"           = "restricted"
      "pod-security.kubernetes.io/audit-version"   = "v1.30"
      "pod-security.kubernetes.io/warn"            = "restricted"
      "pod-security.kubernetes.io/warn-version"    = "v1.30"
    }
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_ingress.iam_role_arn
  }

  depends_on = [
    module.eks,
    module.irsa_ingress
  ]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "policy"
    value = "upsert-only"
  }

  set {
    name  = "registry"
    value = "txt"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-dns"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.irsa_external_dns.iam_role_arn
  }

  depends_on = [
    module.eks,
    module.irsa_external_dns
  ]
}

resource "helm_release" "kyverno" {
  name             = "kyverno"
  namespace        = "kyverno"
  create_namespace = true

  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = "3.2.6"

  set {
    name  = "admissionController.replicas"
    value = "2"
  }

  set {
    name  = "backgroundController.replicas"
    value = "1"
  }

  set {
    name  = "cleanupController.replicas"
    value = "1"
  }

  set {
    name  = "reportsController.replicas"
    value = "1"
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "falco" {
  name             = "falco"
  namespace        = "falco"
  create_namespace = true

  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"

  values = [
    local.falco_values
  ]

  set {
    name  = "driver.kind"
    value = "modern_ebpf"
  }

  set {
    name  = "falco.grpc.enabled"
    value = "true"
  }

  set {
    name  = "falco.grpcOutput.enabled"
    value = "true"
  }

  set {
    name  = "collectors.enabled"
    value = "true"
  }

  depends_on = [
    module.eks
  ]
}

resource "helm_release" "simple_game" {
  name             = "simple-game"
  namespace        = kubernetes_namespace.simple_game.metadata[0].name
  create_namespace = false

  chart = "${path.module}/../../../helm/simple-game"

  set {
    name  = "image.repository"
    value = "ghcr.io/security-org-230982/simple-game"
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  depends_on = [
    module.eks,
    kubernetes_namespace.simple_game,
    helm_release.aws_load_balancer_controller,
    helm_release.external_dns,
    helm_release.kyverno,
    helm_release.falco
  ]
}