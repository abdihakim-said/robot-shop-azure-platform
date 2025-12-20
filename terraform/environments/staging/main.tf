terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  environment = "staging"
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

  # Security settings (staging - production-like)
  private_cluster_enabled         = true        # Private cluster
  local_account_disabled          = true        # Disable local admin
  sku_tier                        = "Standard"  # Paid SLA
  automatic_channel_upgrade       = "stable"    # Stable updates
  api_server_authorized_ip_ranges = []          # Configure as needed
  max_pods_per_node               = 50          # Production-ready
  os_disk_type                    = "Ephemeral" # Better performance

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

# Prometheus + Grafana
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.aks]
}

resource "helm_release" "prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "55.0.0"

  values = [
    templatefile("${path.module}/../../helm-values/prometheus-values.yaml", {
      grafana_admin_password = var.grafana_admin_password
      storage_class          = "managed-csi"
      prometheus_storage     = var.prometheus_storage_size
      grafana_storage        = var.grafana_storage_size
    })
  ]

  depends_on = [module.aks, kubernetes_namespace.monitoring]
}

# Key Vault Module (Environment-specific)
module "keyvault" {
  source = "../../modules/keyvault"
  
  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  random_suffix       = var.random_suffix
  github_actions_object_id = var.github_actions_object_id
  
  secrets = var.secrets
  
  tags = local.common_tags
}
