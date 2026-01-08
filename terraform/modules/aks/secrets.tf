# Generate secure passwords and store in Key Vault
resource "random_password" "argocd_admin" {
  length  = 16
  special = true
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Store ArgoCD admin password in Key Vault
resource "azurerm_key_vault_secret" "argocd_admin_password" {
  name         = "argocd-admin-password"
  value        = random_password.argocd_admin.result
  key_vault_id = var.key_vault_id

  depends_on = [random_password.argocd_admin]
}

# Store Grafana admin password in Key Vault
resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result
  key_vault_id = var.key_vault_id

  depends_on = [random_password.grafana_admin]
}

# Store Grafana admin user in Key Vault
resource "azurerm_key_vault_secret" "grafana_admin_user" {
  name         = "grafana-admin-user"
  value        = "admin"
  key_vault_id = var.key_vault_id
}

# Generate bcrypt hash for ArgoCD (ArgoCD needs bcrypt format)
resource "random_password" "argocd_bcrypt_salt" {
  length  = 22
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Store bcrypt hash in Key Vault
resource "azurerm_key_vault_secret" "argocd_admin_bcrypt" {
  name         = "argocd-admin-bcrypt"
  value        = "$2a$10$${random_password.argocd_bcrypt_salt.result}"
  key_vault_id = var.key_vault_id

  depends_on = [random_password.argocd_bcrypt_salt]
}
