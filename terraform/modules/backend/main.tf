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
  public_network_access_enabled   = true  # Required for GitHub Actions access
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true
  }

  tags = merge(var.tags, {
    Purpose = "terraform-state"
  })
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
