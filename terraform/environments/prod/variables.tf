variable "project_name" {
  description = "Project name"
  type        = string
  default     = "robot-shop"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# Networking
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.0.0.0/16"
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

# AKS
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 3 # Production optimized: Start with 3 nodes (40% reduction)
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3" # Production optimized: 2 vCPU, 8GB RAM (50% cost reduction)
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
  default     = 1 # Dev: can scale to 1
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
  default     = 10 # Production optimized: Scale up to 10 nodes (50% reduction)
}

# Storage
variable "acr_sku" {
  description = "ACR SKU"
  type        = string
  default     = "Basic" # Dev: basic tier
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS" # Dev: locally redundant
}

# Monitoring
variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "prometheus_storage_size" {
  description = "Prometheus storage size"
  type        = string
  default     = "10Gi" # Dev: smaller storage
}

variable "grafana_storage_size" {
  description = "Grafana storage size"
  type        = string
  default     = "5Gi" # Dev: smaller storage
}
variable "random_suffix" {
  description = "Random suffix from bootstrap"
  type        = string
}

variable "github_actions_object_id" {
  description = "GitHub Actions service principal object ID"
  type        = string
}

variable "secrets" {
  description = "Key Vault secrets configuration for production environment"
  type = map(object({
    name   = string
    length = optional(number, 32)
  }))
  default = {
    grafana = {
      name   = "grafana-admin-password"
      length = 32
    }
    prometheus = {
      name   = "prometheus-password"
      length = 28
    }
    mysql = {
      name   = "mysql-admin-password"
      length = 32
    }
    redis = {
      name   = "redis-password"
      length = 28
    }
  }
}
# Database Configuration (Production-Grade)
variable "mysql_sku_name" {
  description = "MySQL SKU name for production"
  type        = string
  default     = "B_Standard_B2s" # Cost optimized: Basic tier (80% cost reduction)
}

variable "mysql_storage_mb" {
  description = "MySQL storage in MB"
  type        = number
  default     = 51200 # Cost optimized: 50GB (50% reduction)
}

variable "mysql_backup_retention" {
  description = "MySQL backup retention days"
  type        = number
  default     = 35
}

variable "redis_sku_name" {
  description = "Redis SKU name for production"
  type        = string
  default     = "Standard" # Cost optimized: Standard tier (70% cost reduction)
}

variable "redis_capacity" {
  description = "Redis capacity (Standard C1=1, C2=2, etc)"
  type        = number
  default     = 1 # Cost optimized: C1 (6GB)
}

variable "cosmosdb_throughput" {
  description = "CosmosDB throughput (RU/s)"
  type        = number
  default     = 400 # Cost optimized: Minimum throughput (60% reduction)
}

# Security Configuration
variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for production access"
  type        = list(string)
  default     = [] # Configure with your corporate IPs
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for databases"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention for production"
  type        = number
  default     = 35
}
# RBAC Configuration
variable "rbac_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS admin access"
  type        = list(string)
  default     = [] # Configure with your Azure AD groups
}

variable "rbac_developer_group_object_ids" {
  description = "Azure AD group object IDs for developer access"
  type        = list(string)
  default     = []
}

# Compliance Configuration
variable "enable_compliance_policies" {
  description = "Enable compliance policies (PCI-DSS, SOC2)"
  type        = bool
  default     = true
}

variable "compliance_frameworks" {
  description = "Compliance frameworks to enable"
  type        = list(string)
  default     = ["PCI-DSS", "SOC2", "ISO27001"]
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true
}
