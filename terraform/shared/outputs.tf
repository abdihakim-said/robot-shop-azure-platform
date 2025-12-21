# Shared infrastructure outputs
output "resource_group_name" {
  description = "Name of the shared resource group"
  value       = azurerm_resource_group.shared.name
}

output "container_registry_name" {
  description = "Name of the shared container registry"
  value       = azurerm_container_registry.shared.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.shared.login_server
}
