terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

data "azuread_application" "github_actions" {
  application_id = var.application_id
}

# Dynamic branch credentials
resource "azuread_application_federated_identity_credential" "github_branches" {
  for_each = toset(var.branches)

  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-branch-${each.value}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:ref:refs/heads/${each.value}"
}

# Dynamic release branch credentials
resource "azuread_application_federated_identity_credential" "github_release_branches" {
  for_each = toset(var.release_branches)

  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-branch-${replace(each.value, "/", "-")}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:ref:refs/heads/${each.value}"
}

# Dynamic environment credentials
resource "azuread_application_federated_identity_credential" "github_environments" {
  for_each = toset(var.environments)

  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-env-${each.value}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:environment:${each.value}"
}
