terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
  backend "azurerm" {
    # Dynamic configuration via CI/CD pipeline
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

locals {
  common_tags = {
    Environment = "shared"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "azurerm_resource_group" "shared" {
  name     = "${var.project_name}-shared-rg"
  location = var.location
  tags     = local.common_tags
}

# Create Azure AD Application for GitHub Actions
resource "azuread_application" "github_actions" {
  display_name = "${var.project_name}-github-actions"
}

# Create Service Principal
resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

# Assign Contributor role to subscription
resource "azurerm_role_assignment" "github_actions_contributor" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# GitHub federated identity module with dynamic configuration
module "github_federated_identity" {
  source = "../modules/github-federated-identity"

  application_id    = azuread_application.github_actions.client_id
  github_repository = var.github_repository
  branches          = ["develop", "main"]
  release_branches  = ["release/*"]
  environments      = ["development", "staging", "production"]
}
