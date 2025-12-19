# Development Environment Configuration

project_name = "robot-shop"
location     = "eastus"
cost_center  = "engineering"

# Networking
vnet_address_space        = "10.0.0.0/16"
aks_subnet_address_prefix = "10.0.1.0/24"

# AKS - Dev Configuration (smaller, cost-effective)
# Use Standard tier to support current Kubernetes versions
sku_tier           = "Standard"
kubernetes_version = "1.33" # Supports KubernetesOfficial (non-LTS)
node_count         = 2      # Only used when autoscaling is disabled
vm_size            = "Standard_D2s_v3"
enable_autoscaling = true
min_node_count     = 2 # Keep minimum at 2 for availability
max_node_count     = 5 # Allow scaling to 5 for peak loads

# Storage - Dev Configuration
acr_sku                  = "Basic"
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

# Monitoring - Dev Configuration
alert_emails            = ["dev-team@example.com"]
prometheus_storage_size = "10Gi"
grafana_storage_size    = "5Gi"

# Node pool configuration - match existing cluster
max_pods_per_node = 30
