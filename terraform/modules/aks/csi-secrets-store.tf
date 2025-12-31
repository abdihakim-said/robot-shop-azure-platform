# Azure Key Vault Provider for Secrets Store CSI Driver
resource "helm_release" "csi_secrets_store_provider_azure" {
  name       = "csi-secrets-store-provider-azure"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  version    = "1.5.3" # Pin to specific version
  namespace  = "kube-system"

  depends_on = [azurerm_kubernetes_cluster.main]

  values = [
    yamlencode({
      linux = {
        image = {
          repository = "mcr.microsoft.com/oss/azure/secrets-store/provider-azure"
          tag        = "v1.5.3"
        }
      }

      # Resource limits for production
      resources = {
        limits = {
          cpu    = "50m"
          memory = "100Mi"
        }
        requests = {
          cpu    = "50m"
          memory = "100Mi"
        }
      }

      # Security context
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        runAsUser                = 1000
        capabilities = {
          drop = ["ALL"]
        }
      }
    })
  ]

  # Ensure clean upgrades
  force_update    = true
  cleanup_on_fail = true
  wait            = true
  timeout         = 300
}
