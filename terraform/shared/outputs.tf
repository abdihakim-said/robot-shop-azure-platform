# Shared infrastructure outputs
output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = azurerm_resource_group.shared.name
}

output "github_application_id" {
  description = "GitHub Actions application ID"
  value       = azuread_application.github_actions.client_id
}

output "github_service_principal_object_id" {
  description = "GitHub Actions service principal object ID"
  value       = azuread_service_principal.github_actions.object_id
}

output "github_federated_identity" {
  description = "GitHub federated identity configuration"
  value       = module.github_federated_identity
  sensitive   = true
}
