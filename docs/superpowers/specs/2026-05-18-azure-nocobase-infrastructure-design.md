# Azure NocoBase インフラ設計仕様

- **日付**: 2026-05-18
- **更新**: 2026-05-19（実デプロイで判明した仕様を反映）
- **ステータス**: 承認済み・デプロイ完了

---

## 概要

Azure Container Apps と Azure Database for PostgreSQL Flexible Server を使用し、個人/小規模チーム向けに安価かつセキュアな NocoBase 運用環境を Terraform で構築する。

**設計方針:**
- コスト優先（目標: 月額 $21〜$32）
- VNet 統合による DB のプライベートアクセス隔離
- モジュール分割構成（将来の環境追加に対応）
- Checkov / Trivy / Gitleaks のセキュリティスキャンをすべて通過する構成

**実装時の必須ルール:**
- Terraform コードを書く前に必ず **terraform-mcp** を使用し、プロバイダ・モジュールの最新バージョンおよびリソース仕様を確認すること
  - `get_latest_provider_version` → `get_provider_capabilities` → `get_provider_details` の順で azurerm の最新情報を取得
  - `get_latest_module_version` / `search_modules` で公式モジュールの有無を確認
  - バージョン未指定・`latest` 指定は禁止（CLAUDE.md のルールに従う）

---

## 1. Azure アーキテクチャ

### リソース構成

```
Azure Subscription
└── Resource Group: rg-nocobase-prod
    │
    ├── [module: networking]
    │   ├── Virtual Network: vnet-nocobase-prod (10.0.0.0/16)
    │   │   ├── subnet-aca  10.0.0.0/21  ← Container Apps Environment 用（/21 以上必須）
    │   │   │                               ※ Microsoft.App/environments 委任も必須
    │   │   └── subnet-db   10.0.8.0/24  ← PostgreSQL Flexible Server 用
    │   │                                   ※ Microsoft.DBforPostgreSQL/flexibleServers 委任必須
    │   └── Network Security Group × 2
    │       ├── nsg-aca: allow HTTPS 443 inbound
    │       └── nsg-db:  deny Internet inbound（DB をインターネットから完全遮断）
    │
    ├── [module: database]
    │   ├── Azure DB for PostgreSQL Flexible Server
    │   │   ├── SKU: Burstable B_Standard_B1ms（1 vCore / 2 GB RAM）
    │   │   ├── Storage: 32 GB
    │   │   ├── PostgreSQL バージョン: 16
    │   │   ├── VNet 統合 → subnet-db（プライベートアクセスのみ）
    │   │   ├── SSL 強制: 有効
    │   │   └── バックアップ保持期間: 7 日
    │   ├── PostgreSQL Database: nocobase
    │   └── Private DNS Zone: privatelink.postgres.database.azure.com
    │       └── VNet リンク
    │
    ├── [module: app]
    │   ├── Log Analytics Workspace
    │   ├── Container Apps Environment
    │   │   ├── プラン: Consumption（従量課金）
    │   │   └── VNet 統合 → subnet-aca
    │   └── Container App: nocobase
    │       ├── Image: nocobase/nocobase:${var.nocobase_image_tag}（バージョン固定）
    │       ├── Ingress: external / port 80 → HTTPS 自動管理証明書
    │       ├── Min replicas: 0（未使用時ゼロスケール）
    │       ├── Max replicas: 2
    │       └── Secrets: DB_HOST, DB_PASSWORD（ACA secrets 経由）
    │
    └── [Terraform State ※ Terraform 管理外・別 RG に配置]
        └── Resource Group: rg-tfstate  ← 本番 RG を destroy しても state が消えないよう分離
            └── Storage Account: stncbtf<subscription_id_prefix8>  ← グローバル一意のため
            │                                                         サブスクリプション ID 先頭8桁を付与
            └── Container: tfstate / blob: prod.terraform.tfstate
```

### コスト概算

| リソース | SKU | 月額概算 |
|---|---|---|
| PostgreSQL Flexible Server | B_Standard_B1ms | ~$14 |
| Container Apps (Consumption) | 使用量次第 | ~$5〜$15 |
| Log Analytics Workspace | 従量課金 | ~$1〜$2 |
| VNet / Private DNS Zone | - | $0〜$1 |
| **合計** | | **~$21〜$32/月** |

---

## 2. Terraform ディレクトリ構成

```
nocobase-azure/
├── docs/
│   └── superpowers/specs/          # 設計仕様書
├── environments/
│   └── prod.tfvars                 # 本番環境固有の変数値
├── modules/
│   ├── networking/
│   │   ├── main.tf                 # VNet, Subnet, NSG
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf                 # PostgreSQL Flexible Server, Private DNS Zone
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── app/
│       ├── main.tf                 # Container Apps Environment, Container App, Log Analytics
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   └── bootstrap.sh                # tfstate 用 Storage Account の初回作成スクリプト
├── main.tf                         # Resource Group + モジュール呼び出しのみ
├── variables.tf                    # 共通入力変数
├── outputs.tf                      # 最終出力（app_fqdn 等）
├── providers.tf                    # azurerm プロバイダ + リモートステート backend
└── locals.tf                       # 命名プレフィックス・共通タグ
```

### environments/prod.tfvars

```hcl
env                 = "prod"
location            = "japaneast"
db_sku_name         = "B_Standard_B1ms"
db_storage_mb       = 32768
aca_min_replicas    = 0
aca_max_replicas    = 2
nocobase_image_tag  = "1.6.0"
```

### providers.tf（概要）

```hcl
terraform {
  required_version = "~> 1.15.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # 実装前に terraform-mcp の get_latest_provider_version で最新バージョンを確認し、
      # ~> x.y.z 形式でパッチバージョンまで固定すること
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "stnocobasetfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}
```

### locals.tf（概要）

```hcl
locals {
  prefix = "nocobase-${var.env}"
  tags = {
    environment = var.env
    project     = "nocobase"
    managed_by  = "terraform"
  }
}
```

---

## 3. モジュール詳細

### modules/networking

| リソース | 用途 |
|---|---|
| `azurerm_virtual_network` | アドレス空間 10.0.0.0/16 |
| `azurerm_subnet` (subnet-aca) | ACA Environment 用、/23 サイズ必須 |
| `azurerm_subnet` (subnet-db) | PostgreSQL 用、`Microsoft.DBforPostgreSQL/flexibleServers` 委任 |
| `azurerm_network_security_group` | DB サブネットへのインターネット直接アクセスを拒否 |
| `azurerm_subnet_network_security_group_association` | NSG を DB サブネットに関連付け |

**outputs:** `vnet_id`, `subnet_aca_id`, `subnet_db_id`

### modules/database

| リソース | 用途 |
|---|---|
| `azurerm_postgresql_flexible_server` | B_Standard_B1ms、VNet 統合、SSL 強制 |
| `azurerm_postgresql_flexible_server_database` | nocobase データベース作成 |
| `azurerm_private_dns_zone` | `privatelink.postgres.database.azure.com` |
| `azurerm_private_dns_zone_virtual_network_link` | VNet と DNS Zone を紐付け |

**outputs:** `db_fqdn`, `db_name`, `db_username`

### modules/app

| リソース | 用途 |
|---|---|
| `azurerm_log_analytics_workspace` | Container Apps のログ収集 |
| `azurerm_container_app_environment` | Consumption プラン、VNet 統合 |
| `azurerm_container_app` | NocoBase 本体、ゼロスケール対応 |

**outputs:** `app_fqdn`

---

## 4. シークレット管理

### DB パスワード

- Terraform 変数として `sensitive = true` で定義
- `TF_VAR_db_password` 環境変数で実行時に注入（`.tfvars` に平文で記載しない）
- ACA secrets に格納し、コンテナの環境変数 `DB_PASSWORD` として参照
- `terraform show` / ログに値が露出しない

### Azure 認証

- ローカル実行: `az login` による Azure CLI 認証を使用
- Service Principal は使用しない（個人利用のため）

### pre-commit による自動ガード

prek の pre-commit フックで以下を自動実行:

```
- terraform fmt    # フォーマット
- terraform validate  # 構文チェック
- tflint           # ルール検証
- gitleaks detect  # シークレット漏洩検出
```

---

## 5. 運用フロー

### 初回セットアップ

```bash
# 1. tfstate 用ストレージを作成（一度だけ）
bash scripts/bootstrap.sh

# 2. ツールをインストール
mise install
prek install

# 3. Terraform 初期化・デプロイ
terraform init
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

### 通常の変更デプロイ

```bash
# コード変更後
terraform fmt -recursive
tflint --recursive
trivy config .
checkov -d .

terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

---

## 6. 将来の拡張ポイント

- **dev 環境追加**: `environments/dev.tfvars` を作成し、同じモジュールを異なるパラメータで呼び出す
- **カスタムドメイン**: ACA のカスタムドメイン設定 + Azure DNS Zone を `modules/app` に追加
- **NAT Gateway**: 固定アウトバウンド IP が必要になった場合に `modules/networking` へ追加
- **Key Vault**: チーム運用になりシークレット管理を強化する場合に導入
