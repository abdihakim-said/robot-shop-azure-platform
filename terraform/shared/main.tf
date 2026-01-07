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
  }
  backend "azurerm" {
    # Dynamic configuration via CI/CD pipeline
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    Environment = "shared"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Shared resource group for cross-environment resources
resource "azurerm_resource_group" "shared" {
  name     = "${var.project_name}-shared-rg"
  location = var.location
  tags     = local.common_tags
}

# Random suffix for globally unique ACR name
resource "random_string" "acr_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Container Registry for all environments
resource "azurerm_container_registry" "shared" {
  name                = "${replace(var.project_name, "-", "")}acr${random_string.acr_suffix.result}"
  resource_group_name = azurerm_resource_group.shared.name
  location            = azurerm_resource_group.shared.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = local.common_tags
}
