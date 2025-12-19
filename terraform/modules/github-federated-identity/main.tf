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

resource "azuread_application_federated_identity_credential" "github_develop" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-branch-develop"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:ref:refs/heads/develop"
}

resource "azuread_application_federated_identity_credential" "github_main" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-branch-main"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "github_release" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-branch-release"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:ref:refs/heads/release/*"
}

resource "azuread_application_federated_identity_credential" "github_env_dev" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-env-development"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:environment:development"
}

resource "azuread_application_federated_identity_credential" "github_env_staging" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-env-staging"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:environment:staging"
}

resource "azuread_application_federated_identity_credential" "github_env_production" {
  application_object_id = data.azuread_application.github_actions.object_id
  display_name          = "github-env-production"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${var.github_repository}:environment:production"
}
