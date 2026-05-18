<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.15.3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.73.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 4.73.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_database.nocobase](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [azurerm_private_dns_zone.postgresql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.postgresql](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | PostgreSQL 管理者パスワード | `string` | n/a | yes |
| <a name="input_db_sku_name"></a> [db\_sku\_name](#input\_db\_sku\_name) | PostgreSQL Flexible Server の SKU 名 | `string` | n/a | yes |
| <a name="input_db_storage_mb"></a> [db\_storage\_mb](#input\_db\_storage\_mb) | PostgreSQL Flexible Server のストレージ容量（MB） | `number` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure リージョン | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | リソース名のプレフィックス | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | リソースグループ名 | `string` | n/a | yes |
| <a name="input_subnet_db_id"></a> [subnet\_db\_id](#input\_subnet\_db\_id) | PostgreSQL Flexible Server 用サブネットの ID | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | リソースに付与するタグ | `map(string)` | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | Virtual Network の ID（Private DNS Zone VNet リンク用） | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_fqdn"></a> [db\_fqdn](#output\_db\_fqdn) | PostgreSQL Flexible Server の FQDN |
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | NocoBase データベース名 |
| <a name="output_db_username"></a> [db\_username](#output\_db\_username) | PostgreSQL 管理者ユーザー名 |
<!-- END_TF_DOCS -->