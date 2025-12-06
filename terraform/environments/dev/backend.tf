terraform {
  backend "azurerm" {
    resource_group_name  = "robot-shop-tfstate-rg"
    storage_account_name = "robotshoptfstate03640a07"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true # Uses Workload Identity
  }
}
