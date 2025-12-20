output "key_vault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.secrets.id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.secrets.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.secrets.vault_uri
}

output "secret_ids" {
  description = "Map of secret names to their IDs"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.id }
}

output "secret_values" {
  description = "Map of secret names to their values"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.value }
  sensitive   = true
}
