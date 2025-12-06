resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.environment}-robot-shop-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "MongoDB"
  
  capabilities {
    name = var.environment == "dev" ? "EnableServerless" : "EnableMongo"
  }
  
  capabilities {
    name = "EnableAggregationPipeline"
  }
  
  capabilities {
    name = "mongoEnableDocLevelTTL"
  }
  
  consistency_policy {
    consistency_level = var.environment == "production" ? "BoundedStaleness" : "Session"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }
  
  geo_location {
    location          = var.location
    failover_priority = 0
  }
  
  dynamic "geo_location" {
    for_each = var.environment == "production" ? [1] : []
    content {
      location          = var.secondary_location
      failover_priority = 1
    }
  }
  
  backup {
    type                = var.environment == "production" ? "Continuous" : "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = var.environment == "production" ? 720 : (var.environment == "staging" ? 336 : 168)
  }
  
  public_network_access_enabled = false
  is_virtual_network_filter_enabled = true
  
  virtual_network_rule {
    id = var.aks_subnet_id
  }
  
  tags = merge(var.tags, {
    Service = "CosmosDB"
  })
}

resource "azurerm_cosmosdb_mongo_database" "catalogue" {
  name                = "catalogue"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  
  dynamic "throughput" {
    for_each = var.environment != "dev" ? [1] : []
    content {
      throughput = var.environment == "production" ? 800 : 400
    }
  }
}

resource "azurerm_cosmosdb_mongo_database" "ratings" {
  name                = "ratings"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.main.name
  
  dynamic "throughput" {
    for_each = var.environment != "dev" ? [1] : []
    content {
      throughput = var.environment == "production" ? 400 : 200
    }
  }
}
