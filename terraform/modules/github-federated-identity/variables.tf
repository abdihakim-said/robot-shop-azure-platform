variable "application_id" {
  description = "GitHub Actions application ID"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
}

variable "branches" {
  description = "List of branches to create federated identity credentials for"
  type        = list(string)
  default     = ["develop", "main"]
}

variable "release_branches" {
  description = "List of release branch patterns"
  type        = list(string)
  default     = ["release/*"]
}

variable "environments" {
  description = "List of GitHub environments to create federated identity credentials for"
  type        = list(string)
  default     = ["development", "staging", "production"]
}
