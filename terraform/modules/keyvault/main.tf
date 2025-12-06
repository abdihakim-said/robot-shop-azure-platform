data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "${var.environment}-robotshop-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.environment == "production" ? "premium" : "standard"
  
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.environment == "production" ? true : false
  soft_delete_retention_days      = 7
  
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = var.allowed_ips
    virtual_network_subnet_ids = [var.aks_subnet_id]
  }
  
  tags = var.tags
}

# Grant AKS access to Key Vault
resource "azurerm_role_assignment" "aks_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.aks_kubelet_identity_object_id
}

# Store Grafana admin password
resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = var.grafana_admin_password
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}

# Store Prometheus credentials
resource "azurerm_key_vault_secret" "prometheus_password" {
  name         = "prometheus-password"
  value        = var.prometheus_password
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}

# Store database passwords
resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  value        = var.mysql_admin_password
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = var.redis_password
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}

# Store ACR credentials
resource "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  value        = var.acr_admin_username
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}

resource "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  value        = var.acr_admin_password
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_role_assignment.aks_secrets_user]
}
