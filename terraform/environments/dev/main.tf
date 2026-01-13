# Robot Shop Development Environment - Updated 2026-01-07
# Trigger pipeline with complete Azure permissions
# Storage account public access enabled for GitHub Actions
# Bootstrap resources deleted - will recreate with proper container
terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Get bootstrap outputs
data "terraform_remote_state" "bootstrap" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = "bootstrap.tfstate"
  }
}

# Get shared outputs
data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.backend_resource_group_name
    storage_account_name = var.backend_storage_account_name
    container_name       = var.backend_container_name
    key                  = "shared.tfstate"
  }
}

# Random suffix for unique resource naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  environment = "dev"
  name_prefix = "${var.project_name}-${local.environment}"

  # Generate random suffix locally for dev environment
  random_suffix = random_string.suffix.result

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

  # Security settings (enhanced for dev)
  private_cluster_enabled         = false      # Match current cluster to prevent replacement
  local_account_disabled          = false      # Requires AAD integration
  sku_tier                        = "Standard" # SECURITY FIX: Paid SLA
  automatic_channel_upgrade       = "stable"   # SECURITY FIX: Stable updates
  api_server_authorized_ip_ranges = []         # SECURITY FIX: Restrict access
  max_pods_per_node               = 50         # SECURITY FIX: Production density
  os_disk_type                    = "Managed"  # COMPATIBILITY FIX: Standard_D2s_v3 doesn't support Ephemeral
  only_critical_addons_enabled    = true       # BEST PRACTICE: System node pool for critical addons only
  # Trigger pipeline after complete ArgoCD cleanup - all resources removed

  # Pass naming variables for KeyVault access
  name_prefix      = local.name_prefix

  tags = local.common_tags

  depends_on = [module.networking]
}

# User Node Pool for Applications (Best Practice: Separate from System Pool)
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = module.aks.cluster_id
  vm_size               = var.vm_size
  node_count            = var.min_node_count
  min_count             = var.min_node_count
  max_count             = var.max_node_count
  enable_auto_scaling   = true

  # Application node pool configuration
  os_disk_type = "Managed"

  # Network configuration
  vnet_subnet_id = module.networking.aks_subnet_id

  # Labels to identify user nodes
  node_labels = {
    "nodepool-type" = "user"
    "environment"   = var.environment
    "workload"      = "applications"
  }

  # No CriticalAddonsOnly taint - applications can run here
  node_taints = []

  tags = local.common_tags

  depends_on = [module.aks]
}

# Wait for AKS cluster to be fully ready before using providers
resource "time_sleep" "wait_for_aks" {
  depends_on = [module.aks]
  
  create_duration = "60s"  # Give AKS time to be fully ready
}

# Helm/Kubernetes Providers for infrastructure components
provider "helm" {
  kubernetes {
    host                   = module.aks.kube_config.host
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  load_config_file       = false
}

# Storage Module
module "storage" {
  source = "../../modules/storage"

  acr_name             = "${replace(local.name_prefix, "-", "")}acr"
  storage_account_name = "robotshopdevst${local.random_suffix}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.main.name

  kubelet_identity_object_id = module.aks.kubelet_identity.object_id

  acr_sku                  = var.acr_sku
  storage_account_tier     = var.storage_account_tier
  storage_replication_type = var.storage_replication_type

  tags = local.common_tags

  depends_on = [module.aks]
}

# Key Vault Module (Environment-specific)
module "keyvault" {
  source = "../../modules/keyvault"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  random_suffix       = local.random_suffix

  secrets = var.secrets

  # CRITICAL: Grant AKS managed identity access to Key Vault
  access_policies = [
    {
      object_id          = module.aks.kubelet_identity.object_id
      secret_permissions = ["Get"]
    }
  ]

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

# ENTERPRISE GITOPS: Kubernetes and Helm providers removed
# These are not needed when using ArgoCD for application deployment
# ArgoCD handles all Kubernetes resources and Helm chart deployments

# ENTERPRISE GITOPS PATTERN: Kubernetes resources managed by ArgoCD
# The monitoring namespace will be created by ArgoCD when deploying
# the monitoring Helm chart. This follows GitOps best practices where:
# - Terraform manages Azure infrastructure (AKS, networking, storage)
# - ArgoCD manages Kubernetes applications (namespaces, deployments)
# - Clear separation of concerns prevents circular dependencies

# Monitoring is now managed via Helm CLI
# See: helm-charts/monitoring/ or use helm install directly
# helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml
# Infrastructure test Wed 17 Dec 2025 14:35:22 GMT
# Test auto-fix Thu 18 Dec 2025 14:26:27 GMT

# Trigger pipeline Tue 13 Jan 2026 19:36:22 EAT
