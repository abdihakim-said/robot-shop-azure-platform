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
    # Configuration provided via CLI
  }
}

provider "azurerm" {
  features {}
}

locals {
  common_tags = {
    Environment = "bootstrap"
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Backend infrastructure only
module "backend" {
  source = "../modules/backend"

  name_prefix   = var.project_name
  location      = var.location
  random_suffix = random_string.suffix.result
  tags          = local.common_tags
}
