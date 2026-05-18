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
