terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate random suffix for globally unique ACR name
resource "random_string" "acr_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_container_registry" "main" {
  name                = "${var.acr_name}${random_string.acr_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.acr_sku
  admin_enabled       = true # Enable for dev environment

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = var.kubelet_identity_object_id
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  blob_properties {
    delete_retention_policy {
      days = var.blob_retention_days
    }
  }

  tags = var.tags
}
