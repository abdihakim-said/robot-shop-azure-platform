# Staging Environment Configuration - v1.0
# Production-like but smaller for pre-production testing

project_name = "robot-shop"
location     = "eastus"
cost_center  = "engineering"

# Networking
vnet_address_space        = "10.1.0.0/16" # Different from dev
aks_subnet_address_prefix = "10.1.1.0/24"

# AKS - Staging Configuration
kubernetes_version = "1.31.13"          # Match dev for now
node_count         = 2                  # Start with 2 nodes
vm_size            = "Standard_DC2s_v3" # Match dev (subscription restriction)
enable_autoscaling = true
min_node_count     = 2
max_node_count     = 5
max_pods_per_node  = 30

# Storage - Staging Configuration
acr_sku                  = "Standard"
storage_account_tier     = "Standard"
storage_replication_type = "LRS" # Cost-effective for staging

# Monitoring - Staging Configuration
alert_emails            = ["staging-team@example.com"]
prometheus_storage_size = "15Gi"
grafana_storage_size    = "8Gi"
