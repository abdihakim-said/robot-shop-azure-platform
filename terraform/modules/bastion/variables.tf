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

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "bastion_subnet_prefix" {
  description = "Address prefix for Bastion subnet"
  type        = string
  default     = "10.1.3.0/24"
}

variable "vm_subnet_prefix" {
  description = "Address prefix for VM subnet"
  type        = string
  default     = "10.1.4.0/24"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "aks_cluster_name" {
  description = "AKS cluster name"
  type        = string
}

variable "aks_resource_group_name" {
  description = "AKS resource group name"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
