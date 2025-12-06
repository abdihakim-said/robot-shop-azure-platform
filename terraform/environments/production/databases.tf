module "databases" {
  source = "../../modules/databases"
  
  environment         = "production"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  secondary_location  = var.secondary_location
  
  aks_subnet_id                     = module.networking.aks_subnet_id
  aks_outbound_ip                   = module.aks.outbound_ip
  redis_subnet_id                   = module.networking.redis_subnet_id
  private_endpoint_subnet_id        = module.networking.private_endpoint_subnet_id
  
  mysql_admin_username              = var.mysql_admin_username
  mysql_admin_password              = var.mysql_admin_password
  backup_storage_connection_string  = azurerm_storage_account.backup.primary_connection_string
  
  tags = local.common_tags
}

# Backup storage for Redis
resource "azurerm_storage_account" "backup" {
  name                     = "${var.environment}robotshopbackup"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "mysql_connection" {
  name         = "mysql-connection-string"
  value        = "Server=${module.databases.mysql_fqdn};Database=users;Uid=${module.databases.mysql_admin_username};Pwd=${var.mysql_admin_password};"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "cosmosdb_connection" {
  name         = "cosmosdb-connection-string"
  value        = module.databases.cosmosdb_connection_string
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection-string"
  value        = "${module.databases.redis_hostname}:${module.databases.redis_ssl_port},password=${module.databases.redis_primary_key},ssl=True"
  key_vault_id = azurerm_key_vault.main.id
}
