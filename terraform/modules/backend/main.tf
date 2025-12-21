# Import existing resource group if it exists
import {
  to = azurerm_resource_group.tfstate
  id = "/subscriptions/00f5b0bc-d9f4-41da-99cd-abcc157e1035/resourceGroups/robot-shop-tfstate-rg"
}

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
  account_replication_type = "LRS"

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
