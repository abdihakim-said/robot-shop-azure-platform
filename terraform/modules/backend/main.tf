resource "azurerm_resource_group" "tfstate" {
  name     = "${var.name_prefix}-tfstate-rg"
  location = var.location

  tags = merge(var.tags, {
    Purpose = "terraform-state"
  })
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "${replace(var.name_prefix, "-", "")}tfstate${var.random_suffix}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "GRS"    # CKV_AZURE_206: Use GRS replication
  min_tls_version          = "TLS1_2" # CKV_AZURE_44: TLS 1.2 minimum

  # CKV_AZURE_190: Restrict public access (but allow for GitHub Actions)
  public_network_access_enabled   = true # Required for GitHub Actions access
  allow_nested_items_to_be_public = false

  #checkov:skip=CKV_AZURE_59:CI runs Terraform from GitHub-hosted and Microsoft-hosted agents, which have no fixed IPs. Access needs Entra ID or the account key; blobs are never anonymous.
  #checkov:skip=CKV2_AZURE_33:Same reason as CKV_AZURE_59: the agents cannot reach a private endpoint.
  #checkov:skip=CKV2_AZURE_40:The azurerm backend authenticates with the account key unless use_azuread_auth is set. Next step: set it in every pipeline, then disable shared keys.
  #checkov:skip=CKV2_AZURE_1:Microsoft-managed keys; a customer-managed key would need a Key Vault that exists before the state account.

  # CKV2_AZURE_41: shared keys stay on (see CKV2_AZURE_40), so SAS tokens expire after a day
  shared_access_key_enabled = true
  sas_policy {
    expiration_period = "01.00:00:00"
  }

  # CKV2_AZURE_38: soft delete for state blobs and the container, on top of versioning
  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  # CKV_AZURE_33: log queue reads, writes and deletes
  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }

  tags = merge(var.tags, {
    Purpose = "terraform-state"
  })
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"

  #checkov:skip=CKV2_AZURE_21:Read logging needs a diagnostic setting to a Log Analytics workspace, which the bootstrap layer does not have. State is versioned and soft-deleted.
}
