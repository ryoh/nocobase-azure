resource "azurerm_private_dns_zone" "postgresql" {
  name                = "${var.prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "vnet-link-${var.prefix}"
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags

  depends_on = [azurerm_private_dns_zone.postgresql]
}

resource "azurerm_postgresql_flexible_server" "main" {
  #checkov:skip=CKV_AZURE_136: 小規模・単一リージョン構成のためコスト優先でジオ冗長バックアップを無効化
  #checkov:skip=CKV2_AZURE_57: delegated_subnet_id + private DNS zone による VNet 統合でネットワーク隔離を実現
  name                = "psql-${var.prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  version                       = "16"
  sku_name                      = var.db_sku_name
  storage_mb                    = var.db_storage_mb
  storage_tier                  = "P4"
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  public_network_access_enabled = false
  zone                          = "1"

  delegated_subnet_id = var.subnet_db_id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  administrator_login    = "ncbadmin"
  administrator_password = var.db_password

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

# VNet 統合によるネットワーク隔離でセキュリティを担保するため、
# NocoBase からの SSL なし接続を許可する
resource "azurerm_postgresql_flexible_server_configuration" "require_secure_transport" {
  #checkov:skip=CKV_AZURE_130: VNet 統合によりインターネットからの直接アクセスを遮断済み。NocoBase が SSL なし接続を行うため無効化
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "off"
}

resource "azurerm_postgresql_flexible_server_database" "nocobase" {
  name      = "nocobase"
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
