output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "game_access" {
  description = "Run kubectl get ingress -n game to get the ALB DNS name"
  value       = "kubectl get ingress -n simple-game"
}