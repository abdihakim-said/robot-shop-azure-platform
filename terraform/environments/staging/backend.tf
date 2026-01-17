terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "staging.terraform.tfstate"
    use_azuread_auth = true
  }
}
