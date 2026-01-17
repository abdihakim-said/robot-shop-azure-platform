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
  environment = "production"
  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
    CostCenter  = var.cost_center
    Optimized   = "cost-optimized-v1"
    Owner       = "platform-team"
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Network Security Groups for Production
resource "azurerm_network_security_group" "aks" {
  name                = "${local.name_prefix}-aks-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS only
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Deny HTTP
  security_rule {
    name                       = "DenyHTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow SSH from corporate network only
  security_rule {
    name                       = "AllowSSHCorporate"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Database Security Groups
resource "azurerm_network_security_group" "database" {
  name                = "${local.name_prefix}-db-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow database access from AKS subnet only
  security_rule {
    name                       = "AllowAKSToDatabase"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["3306", "6379", "10255"]
    source_address_prefix      = var.aks_subnet_address_prefix
    destination_address_prefix = "*"
  }

  tags = local.common_tags
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

# Private DNS Zones for Private Endpoints
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.common_tags
}

# Link DNS zones to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${local.name_prefix}-mysql-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = module.networking.vnet_id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis" {
  name                  = "${local.name_prefix}-redis-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  virtual_network_id    = module.networking.vnet_id
  tags                  = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb" {
  name                  = "${local.name_prefix}-cosmosdb-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  virtual_network_id    = module.networking.vnet_id
  tags                  = local.common_tags
}

# Generate passwords directly for infrastructure
resource "random_password" "mysql" {
  length  = 32
  special = true
}

# Databases Module (Production-Grade Managed Services)
module "databases" {
  source = "../../modules/databases"

  environment         = local.environment
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  # Required networking parameters
  aks_subnet_id              = module.networking.aks_subnet_id
  aks_outbound_ip            = "10.0.0.0" # Will be replaced with actual AKS outbound IP post-deployment
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id

  # MySQL Configuration - direct password
  mysql_admin_username = "mysqladmin"
  mysql_admin_password = random_password.mysql.result

  tags = local.common_tags

  depends_on = [module.networking, module.aks]
}

# AKS Module
module "aks" {
  source = "../../modules/aks"

  cluster_name        = "${local.name_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.aks_subnet_id

  # Enterprise Production Configuration
  kubernetes_version = var.kubernetes_version
  vm_size            = var.vm_size
  node_count         = var.node_count
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count
  enable_autoscaling = true
  enable_multi_az    = true

  # Enterprise Security Features
  enable_azure_policy       = true
  private_cluster_enabled   = var.private_cluster_enabled
  local_account_disabled    = true
  sku_tier                  = "Standard"
  automatic_channel_upgrade = "patch"

  # Network Security
  api_server_authorized_ip_ranges = var.allowed_ip_ranges
  max_pods_per_node               = 50
  os_disk_type                    = "Ephemeral"

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

# REMOVED: Duplicate database module call
# Database module is already called above with proper configuration

# Key Vault Module (Environment-specific)
module "keyvault" {
  source = "../../modules/keyvault"

  name_prefix              = local.name_prefix
  location                 = var.location
  resource_group_name      = azurerm_resource_group.main.name
  random_suffix            = var.random_suffix
  github_actions_object_id = var.github_actions_object_id

  secrets = var.secrets

  tags = local.common_tags
}
