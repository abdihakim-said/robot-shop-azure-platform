variable "project_name" {
  description = "Project name"
  type        = string
  default     = "robot-shop"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
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
