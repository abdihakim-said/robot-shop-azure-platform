# Workload Identity for Grafana
resource "azurerm_user_assigned_identity" "grafana" {
  name                = "${var.cluster_name}-grafana-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Federated Identity Credential for Workload Identity
resource "azurerm_federated_identity_credential" "grafana" {
  name                = "${var.cluster_name}-grafana-federated-credential"
  resource_group_name = var.resource_group_name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.grafana.id
  subject             = "system:serviceaccount:monitoring:grafana-workload-identity"

  depends_on = [azurerm_kubernetes_cluster.main, azurerm_user_assigned_identity.grafana]
}
