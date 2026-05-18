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

variable "subnet_aca_id" {
  description = "Container Apps Environment 用サブネットの ID"
  type        = string
}

variable "db_fqdn" {
  description = "PostgreSQL Flexible Server の FQDN"
  type        = string
}

variable "db_name" {
  description = "データベース名"
  type        = string
}

variable "db_username" {
  description = "PostgreSQL 管理者ユーザー名"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL 管理者パスワード"
  type        = string
  sensitive   = true
}

variable "image_tag" {
  description = "NocoBase コンテナイメージのタグ"
  type        = string
}

variable "min_replicas" {
  description = "Container App の最小レプリカ数"
  type        = number
}

variable "max_replicas" {
  description = "Container App の最大レプリカ数"
  type        = number
}
