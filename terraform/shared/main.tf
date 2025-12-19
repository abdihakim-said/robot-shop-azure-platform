terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "shared" {
  name     = "robot-shop-shared-rg"
  location = "East US"

  tags = {
    Environment = "shared"
    Project     = "robot-shop"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_key_vault" "secrets" {
  name                = "robot-shop-secrets-kv"
  location            = azurerm_resource_group.shared.location
  resource_group_name = azurerm_resource_group.shared.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete"]
  }

  tags = {
    Environment = "shared"
    Project     = "robot-shop"
    ManagedBy   = "terraform"
  }
}

resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.secrets.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete"]
}

resource "azurerm_key_vault_secret" "grafana_password" {
  name         = "grafana-admin-password"
  value        = "admin123!"
  key_vault_id = azurerm_key_vault.secrets.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "prometheus_password" {
  name         = "prometheus-password"
  value        = "prom123!"
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-admin-password"
  value        = "mysql123!"
  key_vault_id = azurerm_key_vault.secrets.id
}

resource "azurerm_key_vault_secret" "redis_password" {
  name         = "redis-password"
  value        = "redis123!"
  key_vault_id = azurerm_key_vault.secrets.id
}
