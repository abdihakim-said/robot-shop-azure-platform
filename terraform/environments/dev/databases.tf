module "databases" {
  source = "../../modules/databases"

  environment         = "dev"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location

  aks_subnet_id              = module.networking.aks_subnet_id
  aks_outbound_ip            = module.aks.outbound_ip
  private_endpoint_subnet_id = module.networking.private_endpoint_subnet_id

  mysql_admin_username = var.mysql_admin_username
  mysql_admin_password = var.mysql_admin_password

  tags = local.common_tags
}

# Store connection strings in Key Vault
resource "azurerm_key_vault_secret" "mysql_connection" {
  name         = "mysql-connection-string"
  value        = "Server=${module.databases.mysql_fqdn};Database=users;Uid=${module.databases.mysql_admin_username};Pwd=${var.mysql_admin_password};"
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

}

resource "azurerm_key_vault_secret" "cosmosdb_connection" {
  name         = "cosmosdb-connection-string"
  value        = module.databases.cosmosdb_connection_string
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

}

resource "azurerm_key_vault_secret" "redis_connection" {
  name         = "redis-connection-string"
  value        = "${module.databases.redis_hostname}:${module.databases.redis_ssl_port},password=${module.databases.redis_primary_key},ssl=True"
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

}
