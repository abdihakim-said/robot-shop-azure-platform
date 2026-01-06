# Environment-specific configuration
project_name = "robot-shop"
location     = "East US"
cost_center  = "development"

# Network Configuration
vnet_address_space        = "10.0.0.0/16"
aks_subnet_address_prefix = "10.0.1.0/24"

# AKS Configuration
kubernetes_version = "1.32.9"
node_count         = 1
vm_size            = "Standard_D2s_v3"
enable_autoscaling = true
min_node_count     = 1
max_node_count     = 5

# Storage Configuration
acr_sku                  = "Basic"
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

# Monitoring
alert_emails = ["admin@example.com"]

# Secrets Configuration
secrets = {
  grafana = {
    name   = "grafana-admin-password"
    length = 16
  }
  prometheus = {
    name   = "prometheus-password"
    length = 16
  }
  mysql = {
    name   = "mysql-admin-password"
    length = 16
  }
  redis = {
    name   = "redis-password"
    length = 16
  }
}
