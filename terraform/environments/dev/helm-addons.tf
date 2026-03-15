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
    name  = "txtOwnerId"
    value = var.cluster_name
  }

  set {
    name  = "domainFilters[0]"
    value = trimsuffix(var.route53_zone_name, ".")
  }

  set {
    name  = "sources[0]"
    value = "ingress"
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
    kubernetes_ingress_class_v1.alb,
    helm_release.aws_load_balancer_controller,
    helm_release.external_dns,
    helm_release.kyverno,
    helm_release.falco
  ]
}
