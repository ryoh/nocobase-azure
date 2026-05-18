output "db_fqdn" {
  description = "PostgreSQL Flexible Server の FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "db_name" {
  description = "NocoBase データベース名"
  value       = azurerm_postgresql_flexible_server_database.nocobase.name
}

output "db_username" {
  description = "PostgreSQL 管理者ユーザー名"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}
