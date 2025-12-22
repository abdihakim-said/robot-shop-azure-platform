resource "azurerm_application_insights" "main" {
  name                = "${var.name_prefix}-appinsights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = var.log_analytics_workspace_id

  tags = var.tags
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.name_prefix}-action-group"
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  dynamic "email_receiver" {
    for_each = var.alert_emails
    content {
      name          = "email-${email_receiver.key}"
      email_address = email_receiver.value
    }
  }

  tags = var.tags
}

# Diagnostic settings for SRE observability and incident response
# Provides AKS logs and metrics for troubleshooting and monitoring  
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "${var.name_prefix}-diagnostics"
  target_resource_id         = var.aks_cluster_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.enabled_log_categories
    content {
      category = enabled_log.value
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  # Prevent replacement - import existing settings
  lifecycle {
    ignore_changes = all
  }
}
