output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = azurerm_subnet.aks.id
}

output "private_endpoint_subnet_id" {
  description = "Private endpoint subnet ID"
  value       = azurerm_subnet.private_endpoints.id
}

output "nsg_id" {
  description = "NSG ID"
  value       = azurerm_network_security_group.aks.id
}
