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
          argocdServerAdminPassword = azurerm_key_vault_secret.argocd_admin_bcrypt.value
        }
      }
    })
  ]

  depends_on = [
    azurerm_kubernetes_cluster.main,
    azurerm_key_vault_secret.argocd_admin_bcrypt
  ]
}
