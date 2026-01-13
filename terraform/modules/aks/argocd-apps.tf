# ArgoCD Applications - Zero Touch Deployment
# Deploy ArgoCD applications automatically after ArgoCD is ready

locals {
  environment = "dev"  # Hardcode for now, can be made dynamic later
}

resource "kubectl_manifest" "robot_shop" {
  yaml_body = file("${path.module}/../../../argocd/robot-shop-${local.environment}.yaml")
  
  depends_on = [
    helm_release.argocd,
    helm_release.secrets_store_csi_driver,
    helm_release.vpa,
    helm_release.cert_manager,
    helm_release.nginx_ingress,
    helm_release.prometheus_operator,
    time_sleep.wait_for_argocd,
    time_sleep.wait_for_cert_manager
  ]
}

# Create monitoring ArgoCD application
resource "kubectl_manifest" "monitoring" {
  yaml_body = templatefile("${path.module}/../../../argocd/monitoring.yaml.tpl", {
    environment = local.environment
    namespace   = "monitoring"
    branch      = local.environment == "prod" ? "main" : (local.environment == "staging" ? "release/*" : "develop")
    key_vault_name = var.keyvault_name
    tenant_id = data.azurerm_client_config.current.tenant_id
    managed_identity_client_id = azurerm_kubernetes_cluster.main.kubelet_identity[0].client_id
    grafana_workload_identity_client_id = azurerm_user_assigned_identity.grafana.client_id
  })
  
  depends_on = [
    helm_release.argocd,
    helm_release.prometheus_operator,
    time_sleep.wait_for_argocd
  ]
}

# Wait for ArgoCD to be fully ready before deploying applications
resource "time_sleep" "wait_for_argocd" {
  depends_on = [helm_release.argocd]
  
  create_duration = "60s"
}

# Required provider for kubectl
terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}
