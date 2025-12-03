variable "name_prefix" {
  description = "Prefix for resource names"
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

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
}

variable "aks_cluster_id" {
  description = "AKS cluster ID"
  type        = string
}

variable "action_group_short_name" {
  description = "Short name for action group"
  type        = string
  default     = "robotshop"
}

variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "enabled_log_categories" {
  description = "Log categories to enable"
  type        = list(string)
  default = [
    "kube-apiserver",
    "kube-controller-manager",
    "kube-scheduler",
    "kube-audit",
    "cluster-autoscaler"
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
