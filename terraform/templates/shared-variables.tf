# Shared Variables Template
# Use this as base for all environments to eliminate duplication

# Environment identifier
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Core Configuration
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "robot-shop"
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "engineering"
}

# Backend Configuration
variable "backend_resource_group_name" {
  description = "Backend resource group name"
  type        = string
  default     = "robot-shop-tfstate-rg"
}

variable "backend_storage_account_name" {
  description = "Backend storage account name"
  type        = string
}

variable "backend_container_name" {
  description = "Backend container name"
  type        = string
  default     = "tfstate"
}

# Networking
variable "vnet_address_space" {
  description = "VNet address space"
  type        = string
}

variable "aks_subnet_address_prefix" {
  description = "AKS subnet address prefix"
  type        = string
}

# AKS Configuration
variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
}

variable "vm_size" {
  description = "VM size"
  type        = string
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum node count"
  type        = number
}

variable "max_node_count" {
  description = "Maximum node count"
  type        = number
}

# Security Settings (environment-specific defaults)
variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
}

variable "local_account_disabled" {
  description = "Disable local admin account"
  type        = bool
}

variable "sku_tier" {
  description = "AKS SKU tier"
  type        = string
  default     = "Standard"
}

variable "automatic_channel_upgrade" {
  description = "Automatic channel upgrade"
  type        = string
  default     = "stable"
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 50
}

variable "os_disk_type" {
  description = "OS disk type"
  type        = string
  default     = "Ephemeral"
}

# Storage Configuration
variable "acr_sku" {
  description = "ACR SKU"
  type        = string
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
}

# Monitoring
variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

# Optional Variables (for staging/prod only)
variable "random_suffix" {
  description = "Random suffix from bootstrap"
  type        = string
  default     = ""
}

variable "secrets" {
  description = "Key Vault secrets configuration"
  type = map(object({
    name   = string
    length = optional(number, 20)
  }))
  default = {}
}

variable "mysql_admin_password" {
  description = "MySQL admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mysql_sku_name" {
  description = "MySQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_storage_mb" {
  description = "MySQL storage in MB"
  type        = number
  default     = 20480
}

variable "redis_sku_name" {
  description = "Redis SKU name"
  type        = string
  default     = "Basic"
}

variable "redis_capacity" {
  description = "Redis capacity"
  type        = number
  default     = 0
}

variable "cosmosdb_throughput" {
  description = "CosmosDB throughput"
  type        = number
  default     = 400
}