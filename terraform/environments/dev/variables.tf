variable "max_pods_per_node" {
  description = "Maximum number of pods per node"
  type        = number
  default     = 30
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "robot-shop"
}

# Backend configuration variables
variable "backend_resource_group_name" {
  description = "Backend resource group name"
  type        = string
  default     = "robot-shop-tfstate-rg"
}

variable "backend_storage_account_name" {
  description = "Backend storage account name"
  type        = string
  # No default - must be provided by pipeline
}

variable "backend_container_name" {
  description = "Backend container name"
  type        = string
  default     = "tfstate"
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
variable "secrets" {
  description = "Key Vault secrets configuration for dev environment"
  type = map(object({
    name   = string
    length = optional(number, 16)
  }))
  default = {
    # Monitoring secrets
    grafana = {
      name   = "grafana-admin-password"
      length = 20
    }
    prometheus = {
      name   = "prometheus-password"
      length = 16
    }

    # Database secrets (align with SecretProviderClass expectations)
    mysql_root = {
      name   = "mysql-root-password"
      length = 20
    }
    mysql_user = {
      name   = "mysql-user-password"
      length = 20
    }
    mongodb_root = {
      name   = "mongodb-root-password"
      length = 20
    }
    mongodb_catalogue = {
      name   = "mongodb-catalogue-password"
      length = 20
    }
    mongodb_users = {
      name   = "mongodb-users-password"
      length = 20
    }
    redis = {
      name   = "redis-password"
      length = 16
    }
    rabbitmq = {
      name   = "rabbitmq-password"
      length = 16
    }
    rabbitmq_cookie = {
      name   = "rabbitmq-erlang-cookie"
      length = 32
    }
  }
}
