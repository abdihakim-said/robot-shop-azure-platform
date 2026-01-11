# Secrets Store CSI Driver (base driver, not just Azure provider)
resource "helm_release" "secrets_store_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  version    = "1.4.0"
  namespace  = "kube-system"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Vertical Pod Autoscaler
resource "helm_release" "vpa" {
  name       = "vpa"
  repository = "https://charts.fairwinds.com/stable"
  chart      = "vpa"
  version    = "4.4.2"
  namespace  = "kube-system"

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Cert-Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.13.3"
  namespace  = "cert-manager"
  
  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Nginx Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = "ingress-nginx"
  
  create_namespace = true

  values = [
    yamlencode({
      controller = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path" = "/healthz"
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-interval" = "5"
            "service.beta.kubernetes.io/azure-load-balancer-health-probe-num-of-probe" = "2"
          }
        }
        metrics = {
          enabled = true
        }
        config = {
          "allow-snippet-annotations" = "true"
        }
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.main]
}

# Let's Encrypt ClusterIssuer
resource "kubectl_manifest" "letsencrypt_issuer" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "abdihakimsaid1@gmail.com"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }
        }]
      }
    }
  })

  depends_on = [
    helm_release.cert_manager,
    helm_release.nginx_ingress,
    # Add delay to ensure cert-manager is fully ready
    time_sleep.wait_for_cert_manager
  ]
}

# Wait for cert-manager to be fully ready
resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]
  
  create_duration = "60s"  # Wait for cert-manager to install CRDs and be ready
}

# Prometheus Operator - EXACT same version as monitoring chart
resource "helm_release" "prometheus_operator" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "80.6.0"  # EXACT match with monitoring/Chart.yaml
  namespace  = "monitoring"
  
  create_namespace = true

  # Install ONLY the operator and CRDs, not the full stack
  values = [
    yamlencode({
      prometheus = {
        enabled = false  # ArgoCD monitoring chart will deploy this
      }
      alertmanager = {
        enabled = false  # ArgoCD monitoring chart will deploy this
      }
      grafana = {
        enabled = false  # ArgoCD monitoring chart will deploy this
      }
      kubeStateMetrics = {
        enabled = false
      }
      nodeExporter = {
        enabled = false
      }
      prometheusOperator = {
        enabled = true   # Only install the operator for CRDs
      }
    })
  ]

  depends_on = [azurerm_kubernetes_cluster.main]
}
