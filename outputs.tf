output "app_fqdn" {
  description = "NocoBase アプリケーションの公開 URL（FQDN）"
  value       = "https://${module.app.app_fqdn}"
}

output "resource_group_name" {
  description = "メインリソースグループ名"
  value       = azurerm_resource_group.main.name
}
