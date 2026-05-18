variable "prefix" {
  description = "リソース名のプレフィックス"
  type        = string
}

variable "location" {
  description = "Azure リージョン"
  type        = string
}

variable "resource_group_name" {
  description = "リソースグループ名"
  type        = string
}

variable "tags" {
  description = "リソースに付与するタグ"
  type        = map(string)
}

variable "subnet_db_id" {
  description = "PostgreSQL Flexible Server 用サブネットの ID"
  type        = string
}

variable "vnet_id" {
  description = "Virtual Network の ID（Private DNS Zone VNet リンク用）"
  type        = string
}

variable "db_sku_name" {
  description = "PostgreSQL Flexible Server の SKU 名"
  type        = string
}

variable "db_storage_mb" {
  description = "PostgreSQL Flexible Server のストレージ容量（MB）"
  type        = number
}

variable "db_password" {
  description = "PostgreSQL 管理者パスワード"
  type        = string
  sensitive   = true
}
