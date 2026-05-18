output "vnet_id" {
  description = "Virtual Network の ID"
  value       = azurerm_virtual_network.main.id
}

output "subnet_aca_id" {
  description = "Container Apps Environment 用サブネットの ID"
  value       = azurerm_subnet.aca.id
}

output "subnet_db_id" {
  description = "PostgreSQL Flexible Server 用サブネットの ID"
  value       = azurerm_subnet.db.id
}
