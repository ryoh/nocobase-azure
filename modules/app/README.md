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
| [azurerm_container_app.nocobase](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app) | resource |
| [azurerm_container_app_environment.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_log_analytics_workspace.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_fqdn"></a> [db\_fqdn](#input\_db\_fqdn) | PostgreSQL Flexible Server の FQDN | `string` | n/a | yes |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | データベース名 | `string` | n/a | yes |
| <a name="input_db_password"></a> [db\_password](#input\_db\_password) | PostgreSQL 管理者パスワード | `string` | n/a | yes |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | PostgreSQL 管理者ユーザー名 | `string` | n/a | yes |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | NocoBase コンテナイメージのタグ | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure リージョン | `string` | n/a | yes |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | Container App の最大レプリカ数 | `number` | n/a | yes |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | Container App の最小レプリカ数 | `number` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | リソース名のプレフィックス | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | リソースグループ名 | `string` | n/a | yes |
| <a name="input_subnet_aca_id"></a> [subnet\_aca\_id](#input\_subnet\_aca\_id) | Container Apps Environment 用サブネットの ID | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | リソースに付与するタグ | `map(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_fqdn"></a> [app\_fqdn](#output\_app\_fqdn) | Container App の公開 FQDN |
<!-- END_TF_DOCS -->