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
  # Bootstrap uses local backend - it creates the remote backend for others
}

provider "azurerm" {
  features {}
}

# Import existing resource group if it exists
import {
  to = module.backend.azurerm_resource_group.tfstate
  id = "/subscriptions/00f5b0bc-d9f4-41da-99cd-abcc157e1035/resourceGroups/robot-shop-tfstate-rg"
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
