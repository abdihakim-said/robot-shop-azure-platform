# Environment-specific configuration only
environment = "staging"

# AKS Configuration
kubernetes_version = "1.31"
node_count         = 3
vm_size            = "Standard_D4s_v3"
min_node_count     = 2
max_node_count     = 8

# Security Settings (Staging)
private_cluster_enabled = true
local_account_disabled  = true
sku_tier                = "Standard"

# Secrets Configuration
secrets = {
  grafana = {
    name   = "grafana-admin-password"
    length = 24
  }
  prometheus = {
    name   = "prometheus-password"
    length = 20
  }
  mysql = {
    name   = "mysql-admin-password"
    length = 24
  }
  redis = {
    name   = "redis-password"
    length = 20
  }
}
