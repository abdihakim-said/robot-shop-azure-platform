# Trigger Terraform pipeline - ServiceAccount fix v2
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

data "azurerm_client_config" "current" {}

# Every secret gets an expiry date (CKV_AZURE_41). The first apply after the rotation
# period moves the date on, and the 30 days of grace leave time to rotate the value:
#   terraform apply -replace='module.keyvault.random_password.missing_secrets["<key>"]'
resource "time_rotating" "secret_expiry" {
  rotation_days = var.secret_rotation_days
}

locals {
  secret_expiry = timeadd(time_rotating.secret_expiry.rotation_rfc3339, "720h")
}

# Generate random passwords for each secret
resource "random_password" "secrets" {
  for_each = var.secrets

  length  = each.value.length
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_key_vault" "secrets" {
  name                = "${replace(var.name_prefix, "-", "")}kv${var.random_suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # CKV_AZURE_42 / CKV_AZURE_110. The vault name has a random suffix, so a rebuilt
  # environment never collides with a soft-deleted vault.
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  #checkov:skip=CKV_AZURE_109:Terraform and CI write secrets from GitHub-hosted runners, which have no fixed IPs. Next step: private endpoint plus self-hosted runners (README, known limitations).
  #checkov:skip=CKV_AZURE_189:Same reason as CKV_AZURE_109.
  #checkov:skip=CKV2_AZURE_32:Same reason as CKV_AZURE_109.

  # Default access policy for current user/service principal
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }

  # GitHub Actions access policy (conditional)
  dynamic "access_policy" {
    for_each = var.github_actions_object_id != "" ? [1] : []
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = var.github_actions_object_id
      secret_permissions = ["Get", "List"]
    }
  }

  # Additional dynamic access policies
  dynamic "access_policy" {
    for_each = var.access_policies
    content {
      tenant_id               = data.azurerm_client_config.current.tenant_id
      object_id               = access_policy.value.object_id
      secret_permissions      = access_policy.value.secret_permissions
      key_permissions         = access_policy.value.key_permissions
      certificate_permissions = access_policy.value.certificate_permissions
    }
  }

  tags = var.tags
}

# Dynamic secrets creation
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name            = each.value.name
  value           = random_password.secrets[each.key].result
  key_vault_id    = azurerm_key_vault.secrets.id
  content_type    = "password"
  expiration_date = local.secret_expiry

  depends_on = [azurerm_key_vault.secrets]

  lifecycle {
    ignore_changes = [value]
  }
}

# Missing secrets
resource "random_password" "missing_secrets" {
  for_each = {
    mysql_root         = 20
    mysql_user         = 20
    mongodb_root       = 20
    mongodb_catalogue  = 20
    mongodb_users      = 20
    rabbitmq           = 16
    rabbitmq_cookie    = 32
    stripe_secret      = 32
    stripe_publishable = 32
  }

  length  = each.value
  special = true
  upper   = true
  lower   = true
  numeric = true
}

resource "azurerm_key_vault_secret" "missing_secrets" {
  for_each = {
    mysql_root         = "mysql-root-password"
    mysql_user         = "mysql-user-password"
    mongodb_root       = "mongodb-root-password"
    mongodb_catalogue  = "mongodb-catalogue-password"
    mongodb_users      = "mongodb-users-password"
    rabbitmq           = "rabbitmq-password"
    rabbitmq_cookie    = "rabbitmq-erlang-cookie"
    stripe_secret      = "stripe-secret-key"
    stripe_publishable = "stripe-publishable-key"
  }

  name            = each.value
  value           = random_password.missing_secrets[each.key].result
  key_vault_id    = azurerm_key_vault.secrets.id
  content_type    = "password"
  expiration_date = local.secret_expiry

  depends_on = [azurerm_key_vault.secrets]
}
