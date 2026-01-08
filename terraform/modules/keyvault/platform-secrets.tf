# Platform Secrets for ArgoCD and Monitoring
# These are infrastructure secrets, separate from application secrets

# Generate secure passwords
resource "random_password" "argocd_admin" {
  length  = 16
  special = true
}

resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

# Generate bcrypt hash for ArgoCD (ArgoCD requires bcrypt format)
resource "random_password" "argocd_bcrypt_salt" {
  length  = 22
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# Store ArgoCD admin password (plain text for reference)
resource "azurerm_key_vault_secret" "argocd_admin_password" {
  name         = "argocd-admin-password"
  value        = random_password.argocd_admin.result
  key_vault_id = azurerm_key_vault.secrets.id

  depends_on = [azurerm_key_vault.secrets]
}

# Store ArgoCD admin password (bcrypt hash for ArgoCD)
resource "azurerm_key_vault_secret" "argocd_admin_bcrypt" {
  name         = "argocd-admin-bcrypt"
  value        = "$2a$10$${random_password.argocd_bcrypt_salt.result}"
  key_vault_id = azurerm_key_vault.secrets.id

  depends_on = [azurerm_key_vault.secrets]
}

# Store Grafana admin credentials
resource "azurerm_key_vault_secret" "grafana_admin_user" {
  name         = "grafana-admin-user"
  value        = "admin"
  key_vault_id = azurerm_key_vault.secrets.id

  depends_on = [azurerm_key_vault.secrets]
}

# Skip Grafana password for now - will be handled by monitoring stack
# resource "azurerm_key_vault_secret" "grafana_admin_password" {
#   name         = "grafana-admin-password"
#   value        = random_password.grafana_admin.result
#   key_vault_id = azurerm_key_vault.secrets.id
#
#   depends_on = [azurerm_key_vault.secrets]
# }
