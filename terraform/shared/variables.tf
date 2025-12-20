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

variable "github_repository" {
  description = "GitHub repository in format owner/repo"  
  type        = string
  default     = "abdihakim-said/robot-shop-azure-platform"
}
