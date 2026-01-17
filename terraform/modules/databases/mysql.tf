resource "azurerm_mysql_flexible_server" "main" {
  name                = "${var.environment}-robot-shop-mysql"
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password

  sku_name = var.environment == "production" ? "GP_Standard_D2ds_v4" : (var.environment == "staging" ? "GP_Standard_D2s_v3" : "B_Standard_B1ms")
  version  = "8.0.21"

  backup_retention_days        = var.environment == "production" ? 35 : (var.environment == "staging" ? 14 : 7)
  geo_redundant_backup_enabled = var.environment == "production" ? true : false

  dynamic "high_availability" {
    for_each = var.environment == "production" ? [1] : []
    content {
      mode = "ZoneRedundant"
    }
  }

  storage {
    size_gb           = var.environment == "production" ? 100 : (var.environment == "staging" ? 50 : 20)
    auto_grow_enabled = true
  }

  tags = merge(var.tags, {
    Service = "MySQL"
  })
}

resource "azurerm_mysql_flexible_database" "users" {
  name                = "users"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_mysql_flexible_database" "cart" {
  name                = "cart"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "aks" {
  name                = "aks-access"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_flexible_server.main.name
  start_ip_address    = var.aks_outbound_ip
  end_ip_address      = var.aks_outbound_ip
}
