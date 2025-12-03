output "application_insights_id" {
  description = "Application Insights ID"
  value       = azurerm_application_insights.main.id
}

output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "action_group_id" {
  description = "Action group ID"
  value       = azurerm_monitor_action_group.main.id
}
