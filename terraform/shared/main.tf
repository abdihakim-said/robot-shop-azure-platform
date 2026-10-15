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
  admin_enabled       = false # CKV_AZURE_137: CI uses `az acr login`, AKS uses AcrPull
  # Premium-SKU features. The registry is Basic to keep the platform cheap to run.
  #checkov:skip=CKV_AZURE_139:Private networking needs the Premium SKU. AKS pulls through its kubelet identity (AcrPull).
  #checkov:skip=CKV_AZURE_164:Content trust needs the Premium SKU. Images are built and scanned (Trivy, SBOM) in CI before push.
  #checkov:skip=CKV_AZURE_165:Geo-replication needs the Premium SKU; the platform runs in one region.
  #checkov:skip=CKV_AZURE_166:Quarantine needs the Premium SKU. The Trivy gate in CI blocks fixable CRITICAL CVEs before push.
  #checkov:skip=CKV_AZURE_167:Untagged-manifest retention needs the Premium SKU.
  #checkov:skip=CKV_AZURE_233:Zone redundancy needs the Premium SKU.
  #checkov:skip=CKV_AZURE_237:Dedicated data endpoints need the Premium SKU.
  #checkov:skip=CKV_AZURE_163:Images are scanned with Trivy in CI (build-and-push.yml); Defender for Containers is not enabled, to avoid its cost.

  tags = local.common_tags
}
