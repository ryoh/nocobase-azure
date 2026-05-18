resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.prefix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tags                       = var.tags
  logs_destination           = "log-analytics"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = var.subnet_aca_id
}

resource "azurerm_container_app" "nocobase" {
  name                         = "ca-${var.prefix}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  tags                         = var.tags

  secret {
    name  = "db-host"
    value = var.db_fqdn
  }

  secret {
    name  = "db-password"
    value = var.db_password
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = "nocobase"
      image  = "nocobase/nocobase:${var.image_tag}"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DB_DIALECT"
        value = "postgres"
      }

      env {
        name        = "DB_HOST"
        secret_name = "db-host"
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_DATABASE"
        value = var.db_name
      }

      env {
        name  = "DB_USER"
        value = var.db_username
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      env {
        name  = "TZ"
        value = "Asia/Tokyo"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 13000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
