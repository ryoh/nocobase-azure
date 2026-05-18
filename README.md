# nocobase-azure

Azure 上で [NocoBase](https://www.nocobase.com/) を運用するための Terraform インフラストラクチャです。
Azure Container Apps + Azure Database for PostgreSQL Flexible Server を使用し、**月額 $21〜$32** を目標にした個人・小規模チーム向け構成です。

## アーキテクチャ

```
Azure Subscription
└── rg-nocobase-prod
    ├── VNet (10.0.0.0/16)
    │   ├── subnet-aca (10.0.0.0/21) ← Container Apps 専用（/21+ 必須・委任必須）
    │   └── subnet-db  (10.0.8.0/24) ← PostgreSQL 専用（委任必須）
    ├── Azure Database for PostgreSQL Flexible Server
    │   └── B_Standard_B1ms / PostgreSQL 16 / プライベートアクセスのみ
    ├── Container Apps Environment (Consumption / VNet 統合)
    │   └── Container App: nocobase/nocobase:1.6.0
    │       └── ゼロスケール対応（min 0 / max 2）
    └── Private DNS Zone (privatelink.postgres.database.azure.com)

rg-tfstate（本番 RG とは分離）
└── Storage Account: stncbtf<subscription_id_8桁>
    └── Container: tfstate
```

### コスト概算

| リソース | SKU | 月額 |
|---|---|---|
| PostgreSQL Flexible Server | B_Standard_B1ms | ~$14 |
| Container Apps (Consumption) | 使用量次第 | ~$5〜$15 |
| Log Analytics Workspace | 従量課金 | ~$1〜$2 |
| VNet / Private DNS Zone | - | $0〜$1 |
| **合計** | | **~$21〜$32** |

## ディレクトリ構成

```
nocobase-azure/
├── environments/
│   ├── prod.tfvars         # 本番変数値（gitignore 対象）
│   └── prod.tfvars.example # テンプレート
├── modules/
│   ├── networking/         # VNet / Subnet / NSG
│   ├── database/           # PostgreSQL / Private DNS Zone
│   └── app/                # Container Apps Environment / Container App / Log Analytics
├── scripts/
│   └── bootstrap.sh        # tfstate 用 Storage Account 初回作成スクリプト
├── docs/superpowers/specs/ # 設計仕様書・実装計画
├── main.tf                 # Resource Group + モジュール呼び出し
├── variables.tf
├── outputs.tf
├── providers.tf            # azurerm プロバイダ + リモートステート backend
└── locals.tf
```

## 前提条件

- Azure サブスクリプション
- [mise](https://mise.jdx.dev/) インストール済み

```bash
# ツール一式をインストール（terraform, tflint, checkov, trivy, gitleaks 等）
mise install
```

| ツール | バージョン |
|---|---|
| terraform | 1.15.3 |
| tflint | 0.62.1 |
| checkov | 3.2.529 |
| trivy | 0.70.0 |
| gitleaks | 8.30.1 |
| terraform-docs | 0.20.0 |

## セットアップ手順

### 1. Azure 認証

```bash
mise exec -- az login
```

### 2. Azure プロバイダ名前空間の登録（初回のみ）

```bash
mise exec -- az provider register --namespace Microsoft.App --wait
```

### 3. tfstate 用 Storage Account を作成（初回のみ）

```bash
bash scripts/bootstrap.sh
```

スクリプト出力の `Storage Account 名` を `providers.tf` の `backend.storage_account_name` に設定してください。

### 4. 環境変数ファイルを準備

```bash
cp environments/prod.tfvars.example environments/prod.tfvars
# prod.tfvars を編集（必要に応じて）
```

### 5. Terraform デプロイ

```bash
# DB パスワードを環境変数で設定（.tfvars には記載しない）
export TF_VAR_db_password="<安全なパスワード>"

terraform init
terraform plan -var-file=environments/prod.tfvars
terraform apply -var-file=environments/prod.tfvars
```

### 6. アクセス確認

```bash
terraform output app_fqdn
# → https://<fqdn> をブラウザで開く
```

## 開発コマンド

```bash
# フォーマット・Lint
terraform fmt -recursive
tflint --recursive

# セキュリティスキャン
trivy config .
checkov -d .
gitleaks detect --source .

# ドキュメント再生成
terraform-docs markdown table --output-file README.md modules/networking/
terraform-docs markdown table --output-file README.md modules/database/
terraform-docs markdown table --output-file README.md modules/app/
```

## pre-commit フック

`prek install` でコミット前に以下が自動実行されます:

- `terraform fmt`
- `terraform validate`
- `tflint`
- `gitleaks`

## シークレット管理

- DB パスワードは `TF_VAR_db_password` 環境変数で注入（`.tfvars` に平文記載禁止）
- `*.tfvars` は `.gitignore` 対象（`*.tfvars.example` のみコミット）
- Container App は ACA secrets 経由でパスワードを参照（ログに露出しない）

## 設計ドキュメント

- [インフラ設計仕様](docs/superpowers/specs/2026-05-18-azure-nocobase-infrastructure-design.md)
- [実装計画](docs/superpowers/specs/2026-05-18-azure-nocobase-implementation-plan.md)
