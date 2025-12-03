output "acr_id" {
  description = "Container Registry ID"
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "storage_account_id" {
  description = "Storage account ID"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Storage account name"
  value       = azurerm_storage_account.main.name
}
