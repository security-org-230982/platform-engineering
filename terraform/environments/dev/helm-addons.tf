data "aws_route53_zone" "selected" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "kubernetes_namespace" "game" {
  metadata { name = "game" }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
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
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = module.irsa_ingress.iam_role_arn
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"

  set { name = "provider" value = "aws" }
  set { name = "policy" value = "sync" }
  set { name = "serviceAccount.create" value = "true" }
  set { name = "serviceAccount.name" value = "external-dns" }
  set {
    name  = "serviceAccount.annotations.eks\.amazonaws\.com/role-arn"
    value = module.irsa_external_dns.iam_role_arn
  }
  set { name = "domainFilters[0]" value = var.route53_zone_name }
}

resource "helm_release" "kyverno" {
  name       = "kyverno"
  namespace  = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  create_namespace = true
}

resource "helm_release" "falco" {
  name       = "falco"
  namespace  = "falco"
  repository = "https://falcosecurity.github.io/charts"
  chart      = "falco"
  create_namespace = true
}

resource "helm_release" "simple_game" {
  name      = "simple-game"
  namespace = kubernetes_namespace.game.metadata[0].name
  chart     = "${path.module}/../../../helm/simple-game"

  values = [yamlencode({
    image = {
      repository = var.container_registry
      tag        = var.image_tag
      pullPolicy = "IfNotPresent"
    }
    ingress = {
      enabled = true
      className = "alb"
      host = "game.${var.domain_name}"
      annotations = {
        "external-dns.alpha.kubernetes.io/hostname" = "game.${var.domain_name}"
        "alb.ingress.kubernetes.io/scheme" = "internet-facing"
        "alb.ingress.kubernetes.io/target-type" = "ip"
        "alb.ingress.kubernetes.io/listen-ports" = "[{"HTTP":80},{"HTTPS":443}]"
        "alb.ingress.kubernetes.io/ssl-redirect" = "443"
        "alb.ingress.kubernetes.io/certificate-arn" = var.acm_certificate_arn
      }
    }
  })]

  depends_on = [
    helm_release.aws_load_balancer_controller,
    helm_release.external_dns,
    helm_release.kyverno
  ]
}
