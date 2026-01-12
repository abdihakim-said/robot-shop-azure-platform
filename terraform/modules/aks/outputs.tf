output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "resource_group_name" {
  description = "Resource group name"
  value       = var.resource_group_name
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config[0]
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0]
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.aks.id
}

output "effective_outbound_ips" {
  description = "AKS cluster effective outbound IPs"
  value       = azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_profile[0].effective_outbound_ips
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "grafana_workload_identity_client_id" {
  description = "Grafana workload identity client ID"
  value       = azurerm_user_assigned_identity.grafana.client_id
}
