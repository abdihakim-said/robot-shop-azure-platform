# Read secrets from Azure Key Vault
data "azurerm_key_vault" "secrets" {
  name                = "robot-shop-secrets-kv"
  resource_group_name = "robot-shop-shared-rg"
}

data "azurerm_key_vault_secret" "grafana_password" {
  name         = "grafana-admin-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

data "azurerm_key_vault_secret" "prometheus_password" {
  name         = "prometheus-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

data "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

data "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  key_vault_id = data.azurerm_key_vault.secrets.id
}
