variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
  default     = 3
}

variable "enable_multi_az" {
  description = "Enable multi-availability zone deployment"
  type        = bool
  default     = false
}

variable "vm_size" {
  description = "VM size for nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_autoscaling" {
  description = "Enable autoscaling"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum node count for autoscaling"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum node count for autoscaling"
  type        = number
  default     = 5
}

variable "service_cidr" {
  description = "Service CIDR"
  type        = string
  default     = "10.1.0.0/16"
}

variable "dns_service_ip" {
  description = "DNS service IP"
  type        = string
  default     = "10.1.0.10"
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy"
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Enable private cluster"
  type        = bool
  default     = false
}

variable "local_account_disabled" {
  description = "Disable local admin account"
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "AKS SKU tier - Free or Standard"
  type        = string
  default     = "Free"
}

variable "automatic_channel_upgrade" {
  description = "Cluster upgrade channel"
  type        = string
  default     = null
}

variable "api_server_authorized_ip_ranges" {
  description = "Authorized IP ranges for API server"
  type        = list(string)
  default     = []
}

variable "max_pods_per_node" {
  description = "Maximum pods per node"
  type        = number
  default     = 30
}

variable "os_disk_type" {
  description = "OS disk type - Managed or Ephemeral"
  type        = string
  default     = "Managed"
}

variable "disk_encryption_set_id" {
  description = "Disk encryption set ID for AKS cluster"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
variable "acr_name" {
  description = "Name of the Azure Container Registry for integration"
  type        = string
  default     = null
}

variable "only_critical_addons_enabled" {
  description = "Enable only critical addons on system node pool"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Name prefix for resources (to match KeyVault naming)"
  type        = string
}
