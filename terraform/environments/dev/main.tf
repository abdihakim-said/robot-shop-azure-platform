terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "robot-shop-tfstate-rg"
    storage_account_name = "robotshoptfstate03640a07"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}

locals {
  environment = "dev"
  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  vnet_address_space        = var.vnet_address_space
  aks_subnet_address_prefix = var.aks_subnet_address_prefix

  tags = local.common_tags
}

# AKS Module
module "aks" {
  source = "../../modules/aks"

  cluster_name        = "${local.name_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.aks_subnet_id

  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  vm_size            = var.vm_size
  enable_autoscaling = var.enable_autoscaling
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count
  max_pods_per_node  = 30 # Match existing cluster

  # Security settings (dev-appropriate)
  private_cluster_enabled         = false     # Public for testing
  local_account_disabled          = false     # Keep for dev access
  sku_tier                        = "Free"    # Cost optimization
  automatic_channel_upgrade       = "patch"   # Auto patch updates
  api_server_authorized_ip_ranges = []        # Open for testing
  os_disk_type                    = "Managed" # Standard

  tags = local.common_tags

  depends_on = [module.networking]
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  acr_name             = "${replace(local.name_prefix, "-", "")}acr"
  storage_account_name = "${replace(local.name_prefix, "-", "")}storage"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name

  kubelet_identity_object_id = module.aks.kubelet_identity.object_id

  acr_sku                  = var.acr_sku
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type

  tags = local.common_tags

  depends_on = [module.aks]
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix                = local.name_prefix
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = module.aks.log_analytics_workspace_id
  aks_cluster_id             = module.aks.cluster_id

  alert_emails = var.alert_emails

  tags = local.common_tags

  depends_on = [module.aks]
}

# Helm/Kubernetes Providers
# Prometheus + Grafana
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.aks]
}

# Note: Monitoring stack (Prometheus/Grafana) is managed via Helm CLI
# See MONITORING-MANAGEMENT.md for deployment instructions
# This follows best practices: Terraform manages infrastructure, Helm CLI manages applications
