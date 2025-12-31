# Azure Key Vault Provider for Secrets Store CSI Driver
# This installs the Azure provider as a DaemonSet to work with the existing CSI driver
resource "kubernetes_daemonset" "csi_secrets_store_provider_azure" {
  metadata {
    name      = "csi-secrets-store-provider-azure"
    namespace = "kube-system"
    labels = {
      app = "csi-secrets-store-provider-azure"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "csi-secrets-store-provider-azure"
      }
    }

    template {
      metadata {
        labels = {
          app = "csi-secrets-store-provider-azure"
        }
      }

      spec {
        service_account_name = "csi-secrets-store-provider-azure"

        container {
          name  = "provider-azure-installer"
          image = "mcr.microsoft.com/oss/azure/secrets-store/provider-azure:v1.5.3"

          args = [
            "--endpoint=unix:///etc/kubernetes/secrets-store-csi-providers/azure.sock",
            "--construct-pem-chain=true",
            "--write-secrets=false",
            "--write-secrets-timeout=20s"
          ]

          resources {
            limits = {
              cpu    = "50m"
              memory = "100Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "100Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1000
            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "providervol"
            mount_path = "/etc/kubernetes/secrets-store-csi-providers"
          }
        }

        volume {
          name = "providervol"
          host_path {
            path = "/etc/kubernetes/secrets-store-csi-providers"
            type = "DirectoryOrCreate"
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        toleration {
          operator = "Exists"
        }
      }
    }
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}

# ServiceAccount for the Azure provider
resource "kubernetes_service_account" "csi_secrets_store_provider_azure" {
  metadata {
    name      = "csi-secrets-store-provider-azure"
    namespace = "kube-system"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}
