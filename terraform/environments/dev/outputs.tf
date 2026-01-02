output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = module.aks.cluster_id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.key_vault_name
}

output "managed_identity_client_id" {
  description = "AKS managed identity client ID"
  value       = module.aks.kubelet_identity.client_id
}

output "tenant_id" {
  description = "Azure tenant ID"
  value       = module.keyvault.tenant_id
}

output "acr_login_server" {
  description = "ACR login server"
  value       = module.storage.acr_login_server
}

output "grafana_url" {
  description = "Grafana URL (wait 2-3 minutes after apply)"
  value       = "kubectl get svc -n monitoring monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}
