# Backend configuration (required by pipeline)
variable "backend_storage_account_name" {
  description = "Backend storage account name"
  type        = string
  # No default - must be provided by pipeline
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "robot-shop"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West US 2" # Staging in different region from dev
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# Networking (staging-specific to avoid conflicts)
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
  default     = "10.1.0.0/16" # Different from dev (10.0.0.0/16)
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.1.1.0/24" # Different from dev (10.0.1.0/24)
}

# AKS Configuration (Production-Grade Security)
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

# SECURITY: Critical security settings for staging
variable "private_cluster_enabled" {
  description = "Enable private cluster (API server not public)"
  type        = bool
  default     = true # SECURITY FIX: Private API server
}

variable "local_account_disabled" {
  description = "Disable local admin account (use Azure AD only)"
  type        = bool
  default     = true # SECURITY FIX: No shared admin accounts
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server access"
  type        = list(string)
  default     = [] # SECURITY: Configure with corporate IPs
}

# Production-mirror staging (identical to prod for DR)
variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 3 # Same as production
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_D2s_v3" # Same as production
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
  default     = 3 # Same as production
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
  default     = 10 # Same as production
}

# Production-grade storage (identical to prod)
variable "acr_sku" {
  description = "ACR SKU"
  type        = string
  default     = "Standard" # Same as production
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "GRS" # Same as production
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
  description = "Key Vault secrets configuration for staging environment"
  type = map(object({
    name   = string
    length = optional(number, 20)
  }))
  default = {
    grafana = {
      name   = "grafana-admin-password"
      length = 24
    }
    prometheus = {
      name   = "prometheus-password"
      length = 20
    }
    mysql = {
      name   = "mysql-admin-password"
      length = 24
    }
    redis = {
      name   = "redis-password"
      length = 20
    }
  }
}

# Database Configuration (Production-Mirror for DR)
variable "mysql_sku_name" {
  description = "MySQL SKU name for staging (same as production)"
  type        = string
  default     = "B_Standard_B2s" # Same as production
}

variable "mysql_storage_mb" {
  description = "MySQL storage in MB"
  type        = number
  default     = 51200 # Same as production
}

variable "mysql_backup_retention" {
  description = "MySQL backup retention days"
  type        = number
  default     = 35 # Same as production
}

variable "redis_sku_name" {
  description = "Redis SKU name for staging (same as production)"
  type        = string
  default     = "Standard" # Same as production
}

variable "redis_capacity" {
  description = "Redis capacity (Standard C1=1, C2=2, etc)"
  type        = number
  default     = 1 # Same as production
}

variable "cosmosdb_throughput" {
  description = "CosmosDB throughput (RU/s)"
  type        = number
  default     = 400 # Same as production
}

# Security Configuration (Production-Mirror)
variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for staging access"
  type        = list(string)
  default     = [] # Same as production
}

variable "enable_private_endpoints" {
  description = "Enable private endpoints for databases"
  type        = bool
  default     = true # Same as production
}

variable "backup_retention_days" {
  description = "Backup retention for staging"
  type        = number
  default     = 35 # Same as production
}

# RBAC Configuration (Production-Mirror)
variable "rbac_admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS admin access"
  type        = list(string)
  default     = [] # Same as production
}

variable "rbac_developer_group_object_ids" {
  description = "Azure AD group object IDs for developer access"
  type        = list(string)
  default     = [] # Same as production
}

# Compliance Configuration (Production-Mirror)
variable "enable_compliance_policies" {
  description = "Enable compliance policies (PCI-DSS, SOC2)"
  type        = bool
  default     = true # Same as production
}

variable "compliance_frameworks" {
  description = "Compliance frameworks to enable"
  type        = list(string)
  default     = ["PCI-DSS", "SOC2", "ISO27001"] # Same as production
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = true # Same as production
}
