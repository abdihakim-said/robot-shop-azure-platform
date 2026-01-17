# ArgoCD - GitOps Controller (uses local password generation)
resource "random_password" "argocd_admin" {
  length  = 16
  special = true
}

resource "random_password" "argocd_bcrypt_salt" {
  length  = 22
  special = false
  upper   = true
  lower   = true
  numeric = true
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
      
      # Use locally generated password (no KeyVault dependency)
      configs = {
        secret = {
          argocdServerAdminPassword = "$2a$10$${random_password.argocd_bcrypt_salt.result}"
        }
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.main]
}
