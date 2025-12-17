# Multi-AZ Node Pool Configuration
resource "azurerm_kubernetes_cluster_node_pool" "multi_az" {
  count                = var.enable_multi_az ? 1 : 0
  name                 = "multiaz"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size              = var.vm_size
  node_count           = var.node_count
  
  # Multi-AZ configuration
  zones = ["1", "2", "3"]  # Deploy across all 3 availability zones
  
  # Anti-affinity to spread pods across zones
  node_labels = {
    "topology.kubernetes.io/zone" = "multi"
  }
  
  # Taints for zone-aware scheduling
  node_taints = []
  
  tags = var.tags
}

# Pod Disruption Budget for high availability
resource "kubernetes_pod_disruption_budget" "robot_shop" {
  count = var.enable_multi_az ? 1 : 0
  
  metadata {
    name      = "robot-shop-pdb"
    namespace = "robot-shop"
  }
  
  spec {
    min_available = "50%"  # Always keep 50% of pods running
    
    selector {
      match_labels = {
        app = "robot-shop"
      }
    }
  }
}

# Zone-aware storage class
resource "kubernetes_storage_class" "multi_az" {
  count = var.enable_multi_az ? 1 : 0
  
  metadata {
    name = "managed-premium-multi-az"
  }
  
  storage_provisioner    = "disk.csi.azure.com"
  reclaim_policy        = "Delete"
  volume_binding_mode   = "WaitForFirstConsumer"
  allow_volume_expansion = true
  
  parameters = {
    skuName             = "Premium_LRS"
    cachingmode         = "ReadOnly"
    fsType              = "ext4"
    # Zone-aware provisioning
    "csi.storage.k8s.io/provisioner-secret-name"      = "azure-cloud-provider"
    "csi.storage.k8s.io/provisioner-secret-namespace" = "kube-system"
  }
}
