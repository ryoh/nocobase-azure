variable "env" {
  description = "環境名（例: prod, dev）"
  type        = string
  validation {
    condition     = contains(["prod", "dev", "staging"], var.env)
    error_message = "env は prod / dev / staging のいずれかを指定してください。"
  }
}

variable "location" {
  description = "Azure リージョン"
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
  description = "PostgreSQL 管理者パスワード（TF_VAR_db_password 環境変数で注入）"
  type        = string
  sensitive   = true
}

variable "aca_min_replicas" {
  description = "Container App の最小レプリカ数"
  type        = number
}

variable "aca_max_replicas" {
  description = "Container App の最大レプリカ数"
  type        = number
}

variable "nocobase_image_tag" {
  description = "NocoBase コンテナイメージのタグ（バージョン固定必須）"
  type        = string
}
