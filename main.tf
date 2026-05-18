resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source = "./modules/networking"

  prefix              = local.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

module "database" {
  source = "./modules/database"

  prefix              = local.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  subnet_db_id  = module.networking.subnet_db_id
  vnet_id       = module.networking.vnet_id
  db_sku_name   = var.db_sku_name
  db_storage_mb = var.db_storage_mb
  db_password   = var.db_password
}

module "app" {
  source = "./modules/app"

  prefix              = local.prefix
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  subnet_aca_id = module.networking.subnet_aca_id
  db_fqdn       = module.database.db_fqdn
  db_name       = module.database.db_name
  db_username   = module.database.db_username
  db_password   = var.db_password
  image_tag     = var.nocobase_image_tag
  min_replicas  = var.aca_min_replicas
  max_replicas  = var.aca_max_replicas
}
