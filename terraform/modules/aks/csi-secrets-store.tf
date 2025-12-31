# Azure Key Vault Provider for Secrets Store CSI Driver
# This installs the Azure provider to work with the existing CSI driver
resource "helm_release" "csi_secrets_store_provider_azure" {
  name       = "csi-secrets-store-provider-azure"
  repository = "https://azure.github.io/secrets-store-csi-driver-provider-azure/charts"
  chart      = "csi-secrets-store-provider-azure"
  version    = "1.5.3"
  namespace  = "kube-system"

  # Ensure this doesn't conflict with existing CSI driver
  create_namespace = false

  # Use different release name to avoid conflicts
  depends_on = [azurerm_kubernetes_cluster.main]

  values = [
    yamlencode({
      # Align with your existing Azure Key Vault setup
      linux = {
        image = {
          repository = "mcr.microsoft.com/oss/azure/secrets-store/provider-azure"
          tag        = "v1.5.3"
        }
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
      }

      # Security context aligned with your setup
      securityContext = {
        allowPrivilegeEscalation = false
        readOnlyRootFilesystem   = true
        runAsNonRoot             = true
        runAsUser                = 1000
        capabilities = {
          drop = ["ALL"]
        }
      }

      # Ensure it works with existing managed identity
      nodeSelector = {
        "kubernetes.io/os" = "linux"
      }
    })
  ]

  # Ensure clean deployment
  wait            = true
  timeout         = 300
  cleanup_on_fail = true
}

# Remove the manual DaemonSet and ServiceAccount since Helm chart handles this
