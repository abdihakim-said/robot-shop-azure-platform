resource "azurerm_redis_cache" "main" {
  name                = "${var.environment}-robot-shop-redis"
  location            = var.location
  resource_group_name = var.resource_group_name

  capacity = var.environment == "production" ? 1 : 0
  family   = var.environment == "production" ? "P" : "C"
  sku_name = var.environment == "production" ? "Premium" : (var.environment == "staging" ? "Standard" : "Basic")

  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    enable_authentication = true
    maxmemory_policy      = "allkeys-lru"

    rdb_backup_enabled            = var.environment == "production" ? true : false
    rdb_backup_frequency          = var.environment == "production" ? 60 : null
    rdb_backup_max_snapshot_count = var.environment == "production" ? 1 : null
    rdb_storage_connection_string = var.environment == "production" ? var.backup_storage_connection_string : null
  }

  zones = var.environment == "production" ? ["1", "2", "3"] : null

  public_network_access_enabled = false
  subnet_id                     = var.environment == "production" ? var.redis_subnet_id : null

  tags = merge(var.tags, {
    Service = "Redis"
  })
}

resource "azurerm_private_endpoint" "redis" {
  count = var.environment != "dev" ? 1 : 0

  name                = "${var.environment}-redis-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "redis-connection"
    private_connection_resource_id = azurerm_redis_cache.main.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
}
