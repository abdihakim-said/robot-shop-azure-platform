# Multi-AZ Node Pool Configuration
resource "azurerm_kubernetes_cluster_node_pool" "multi_az" {
  count                 = var.enable_multi_az ? 1 : 0
  name                  = "multiaz"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.vm_size
  node_count            = var.node_count

  # Multi-AZ configuration
  zones = ["1", "2", "3"] # Deploy across all 3 availability zones

  # Anti-affinity to spread pods across zones
  node_labels = {
    "topology.kubernetes.io/zone" = "multi"
  }

  # Taints for zone-aware scheduling
  node_taints = []

  tags = var.tags
}

# Kubernetes resources moved to ArgoCD for GitOps best practices
# - Pod Disruption Budget: Deploy via ArgoCD/Helm
# - Storage Class: Deploy via ArgoCD/Helm
# This ensures proper separation of infrastructure (Terraform) and application (ArgoCD)
