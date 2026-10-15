variable "application_id" {
  description = "GitHub Actions application ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "abdihakim-said/robot-shop-azure-platform"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Use the owner/repo format."
  }
}

variable "branches" {
  description = "List of branches to create federated identity credentials for"
  type        = list(string)
  default     = ["develop", "main"]
}

variable "release_branches" {
  description = "Exact release branch names. Entra ID matches the subject exactly, so wildcards never match."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for b in var.release_branches : !strcontains(b, "*")])
    error_message = "Entra ID federated credentials do not support wildcards; list each branch."
  }
}

variable "environments" {
  description = "List of GitHub environments to create federated identity credentials for"
  type        = list(string)
  default     = ["development", "staging", "production"]
}
