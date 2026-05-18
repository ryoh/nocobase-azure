output "app_fqdn" {
  description = "Container App の公開 FQDN"
  value       = azurerm_container_app.nocobase.ingress[0].fqdn
}
