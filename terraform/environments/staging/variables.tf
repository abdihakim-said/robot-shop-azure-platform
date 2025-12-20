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
  default     = 2 # Dev: smaller cluster
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B2s" # Dev: cost-effective
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
  default     = 3 # Dev: limited scale
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
