terraform {
  backend "azurerm" {
    container_name   = "tfstate"
    key              = "prod.terraform.tfstate"
    use_azuread_auth = true
  }
}
