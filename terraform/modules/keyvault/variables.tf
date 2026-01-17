variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "random_suffix" {
  description = "Random suffix for unique naming"
  type        = string
}

variable "github_actions_object_id" {
  description = "GitHub Actions service principal object ID"
  type        = string
  default     = ""
}

variable "secrets" {
  description = "Map of secrets to create in Key Vault"
  type = map(object({
    name   = string
    length = optional(number, 16)
  }))
  default = {}
}

variable "access_policies" {
  description = "Additional access policies for Key Vault"
  type = list(object({
    object_id               = string
    secret_permissions      = list(string)
    key_permissions         = optional(list(string), [])
    certificate_permissions = optional(list(string), [])
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "aks_kubelet_identity_object_id" {
  description = "AKS kubelet managed identity object ID for KeyVault access"
  type        = string
  default     = ""
}
