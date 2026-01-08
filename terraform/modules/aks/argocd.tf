# Data source to read ArgoCD password from Key Vault
data "azurerm_key_vault" "secrets" {
  name                = "${replace(var.name_prefix, "-", "")}kv${substr(md5(var.resource_group_name), 0, 8)}"
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault_secret" "argocd_admin_bcrypt" {
  name         = "argocd-admin-bcrypt"
  key_vault_id = data.azurerm_key_vault.secrets.id
}

# ArgoCD - GitOps Controller
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.6"
  namespace  = "argocd"
  
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
      }
      
      controller = {
        replicas = 1
      }
      
      # Use Key Vault secret for admin password
      configs = {
        secret = {
          argocdServerAdminPassword = data.azurerm_key_vault_secret.argocd_admin_bcrypt.value
        }
      }
    })
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    data.azurerm_key_vault_secret.argocd_admin_bcrypt
  ]
}
