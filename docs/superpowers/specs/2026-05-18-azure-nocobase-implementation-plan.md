# Azure NocoBase インフラ 実装計画

- **日付**: 2026-05-18
- **更新**: 2026-05-19（実デプロイで判明した仕様を反映）
- **ステータス**: 完了
- **対応仕様書**: `2026-05-18-azure-nocobase-infrastructure-design.md`

---

## 前提条件

- `mise install` 済み（terraform 1.15.3, tflint 0.62.1 等）
- `az login` で Azure CLI 認証済み（`mise exec -- az login`）
- terraform-mcp が `.vscode/mcp.json` 経由で利用可能

### ⚠️ Azure リソースプロバイダの事前登録（初回のみ）

Container Apps を初めてデプロイするサブスクリプションでは `Microsoft.App` 名前空間の登録が必要:

```bash
mise exec -- az provider register --namespace Microsoft.App --wait
mise exec -- az provider show --namespace Microsoft.App --query registrationState
# "Registered" と表示されるまで待つ
```

---

## フェーズ 0 — terraform-mcp でバージョン確認（実装開始前に必須）

**目的:** コード生成前に azurerm プロバイダの最新バージョンを確認し、固定バージョンを決定する。

```
手順:
1. terraform-mcp: get_latest_provider_version (hashicorp/azurerm)
2. terraform-mcp: get_provider_capabilities (azurerm, 取得バージョン)
3. terraform-mcp: get_provider_details で以下リソースの仕様を確認
   - azurerm_virtual_network
   - azurerm_subnet
   - azurerm_network_security_group
   - azurerm_postgresql_flexible_server
   - azurerm_container_app_environment
   - azurerm_container_app
   - azurerm_log_analytics_workspace
   - azurerm_private_dns_zone
```

**完了条件:** `providers.tf` に書くべき `version = "~> x.y.z"` が確定している

---

## フェーズ 1 — Bootstrap（tfstate 用ストレージ作成）

**目的:** Terraform リモートステートを保存する Storage Account を手動で作成する。

### 1-1. `scripts/bootstrap.sh` を作成

```bash
# 作成するリソース
# - Resource Group: rg-tfstate
# - Storage Account: stncbtf<subscription_id_先頭8文字> (LRS, HTTPS のみ)
# - Blob Container: tfstate
```

> ⚠️ **Storage Account 名はグローバル一意**: `stnocobasetfstate` 等の固定名は他のユーザーが使用済みの可能性がある。
> スクリプトはサブスクリプション ID の先頭 8 文字（ハイフン除去）を自動付与し一意性を保証する（例: `stncbtfcb1d6159`）。

### 1-2. スクリプトを実行

```bash
bash scripts/bootstrap.sh
```

スクリプト出力の `Storage Account 名` を `providers.tf` の `backend.storage_account_name` に設定する。

**完了条件:** `mise exec -- az storage account show --name stncbtf<suffix>` が成功する

---

## フェーズ 2 — ルートモジュールの骨格

**目的:** Terraform の共通ファイルを作成する。

### 作成ファイル（この順で作成）

| ファイル | 内容 |
|---|---|
| `providers.tf` | terraform ブロック（required_version, backend, azurerm プロバイダ） |
| `variables.tf` | env, location, db_sku_name, db_storage_mb, aca_min_replicas, aca_max_replicas, nocobase_image_tag, db_password（sensitive） |
| `locals.tf` | prefix = "nocobase-${var.env}", tags |
| `main.tf` | azurerm_resource_group + モジュール呼び出し（モジュールが揃うまでコメントアウト） |
| `outputs.tf` | app_fqdn |
| `environments/prod.tfvars` | 本番環境の変数値 |

### 検証

```bash
terraform init
terraform validate
```

**完了条件:** `terraform validate` が成功する

---

## フェーズ 3 — modules/networking

**目的:** VNet / Subnet / NSG を管理するモジュールを実装する。

### 3-1. リソース実装（`modules/networking/main.tf`）

```
azurerm_virtual_network                          10.0.0.0/16
azurerm_subnet (aca)                             10.0.0.0/21  ※ /21 以上必須・Microsoft.App/environments 委任必須
azurerm_subnet (db)                              10.0.8.0/24  ※ Microsoft.DBforPostgreSQL/flexibleServers 委任必須
azurerm_network_security_group (nsg-aca)         HTTPS 443 インバウンド許可
azurerm_network_security_group (nsg-db)          インターネットインバウンド拒否
azurerm_subnet_network_security_group_association × 2（ACA・DB 各サブネット）
```

> ⚠️ **ACA サブネット要件（実デプロイで判明）:**
> - サイズは `/21` 以上が必須（`/23` では `ManagedEnvironmentSubnetDelegationError` が発生）
> - `Microsoft.App/environments` への委任ブロック（delegation）が必須（ないとデプロイエラー）
> - NSG は ACA サブネットにも必要（Checkov CKV2_AZURE_31 対応）

### 3-2. variables.tf / outputs.tf

- **outputs:** `vnet_id`, `subnet_aca_id`, `subnet_db_id`

### 3-3. 検証

```bash
terraform fmt -recursive
tflint --recursive
trivy config .
checkov -d .
terraform plan -var-file=environments/prod.tfvars
```

**完了条件:** plan が差分なし（初回は新規リソースのみ）、Checkov / Trivy エラーなし

---

## フェーズ 4 — modules/database

**目的:** PostgreSQL Flexible Server と Private DNS Zone を実装する。

### 4-1. リソース実装（`modules/database/main.tf`）

```
azurerm_private_dns_zone                    privatelink.postgres.database.azure.com
azurerm_private_dns_zone_virtual_network_link
azurerm_postgresql_flexible_server          B_Standard_B1ms, VNet 統合, SSL 強制
azurerm_postgresql_flexible_server_database nocobase
```

> **注意:** Private DNS Zone は PostgreSQL より先に作成する必要がある（depends_on または参照で制御）

### 4-2. variables.tf / outputs.tf

- **inputs:** `vnet_id`, `subnet_db_id`, `db_password`（sensitive）
- **outputs:** `db_fqdn`, `db_name`, `db_username`

### 4-3. 検証

```bash
terraform fmt -recursive && tflint --recursive
trivy config . && checkov -d .
terraform plan -var-file=environments/prod.tfvars
```

**完了条件:** plan に networking + database のリソースが正しく表示される

---

## フェーズ 5 — modules/app

**目的:** Container Apps Environment と Container App を実装する。

### 5-1. リソース実装（`modules/app/main.tf`）

```
azurerm_log_analytics_workspace
azurerm_container_app_environment   Consumption, VNet 統合（subnet_aca_id）
azurerm_container_app               nocobase イメージ, ゼロスケール, secrets
```

### 5-2. Secrets 設定

Container App に以下を secrets として設定:
- `db-host` → `modules/database` の `db_fqdn` output
- `db-password` → `var.db_password`（sensitive）

環境変数 `DB_HOST`, `DB_PASSWORD` から secrets を参照。

### 5-3. variables.tf / outputs.tf

- **inputs:** `subnet_aca_id`, `log_analytics_workspace_id`, `db_fqdn`, `db_name`, `db_username`, `db_password`, `image_tag`, `min_replicas`, `max_replicas`
- **outputs:** `app_fqdn`

### 5-4. 検証

```bash
terraform fmt -recursive && tflint --recursive
trivy config . && checkov -d .
terraform plan -var-file=environments/prod.tfvars
```

**完了条件:** plan に全リソースが表示され、Checkov / Trivy エラーなし

---

## フェーズ 6 — 統合 apply & 動作確認

**目的:** 全リソースをデプロイし、NocoBase の動作を確認する。

### 6-1. デプロイ

```bash
# DB パスワードを環境変数で設定
export TF_VAR_db_password="<安全なパスワード>"

terraform apply -var-file=environments/prod.tfvars
```

### 6-2. 動作確認

```bash
# ACA の FQDN を取得
terraform output app_fqdn

# ブラウザで https://<fqdn> を開き NocoBase の初期画面が表示されることを確認
```

**完了条件:** `https://<fqdn>` で NocoBase のセットアップ画面が表示される

---

## フェーズ 7 — pre-commit フック設定

**目的:** コミット前の自動チェックを設定する。

### 7-1. `.pre-commit-config.yaml` を作成

> ⚠️ `prek` は `.prek.yml` ではなく `.pre-commit-config.yaml` 形式を使用する。
> hooks 内のコマンドは `mise exec --` を先頭に付けないと mise 管理のツールが PATH 解決できない。

```yaml
repos:
  - repo: local
    hooks:
      - id: terraform-fmt
        name: terraform fmt
        entry: mise exec -- terraform fmt -recursive
        language: system
        pass_filenames: false
      - id: terraform-validate
        name: terraform validate
        entry: mise exec -- terraform validate
        language: system
        pass_filenames: false
      - id: tflint
        name: tflint
        entry: mise exec -- tflint --recursive
        language: system
        pass_filenames: false
      - id: gitleaks
        name: gitleaks
        entry: mise exec -- gitleaks detect --source .
        language: system
        pass_filenames: false
```

### 7-2. フックをインストール

```bash
mise exec -- prek install
```

**完了条件:** `git commit` 時に上記チェックが自動実行される

---

## フェーズ 8 — ドキュメント生成

**目的:** 各モジュールの README.md を自動生成する。

```bash
# terraform-docs を mise.toml に追加してインストール
mise install terraform-docs

# 各モジュールの README を生成
terraform-docs markdown table --output-file README.md modules/networking/
terraform-docs markdown table --output-file README.md modules/database/
terraform-docs markdown table --output-file README.md modules/app/
```

**完了条件:** 各モジュールに `README.md` が生成されている

---

## 実装チェックリスト

- [x] フェーズ 0: terraform-mcp でプロバイダバージョン確認済み（azurerm 4.73.0）
- [x] フェーズ 1: bootstrap.sh 作成・実行、tfstate Storage Account（stncbtfcb1d6159）存在確認
- [x] フェーズ 2: ルートモジュール骨格、`terraform validate` 成功
- [x] フェーズ 3: networking モジュール、plan 正常
- [x] フェーズ 4: database モジュール、plan 正常
- [x] フェーズ 5: app モジュール、plan 正常
- [x] フェーズ 6: `terraform apply` 成功、NocoBase 画面表示確認（https://ca-nocobase-prod.agreeablesea-1392df45.japaneast.azurecontainerapps.io）
- [x] フェーズ 7: pre-commit フック設定済み（.pre-commit-config.yaml）
- [x] フェーズ 8: terraform-docs で README 生成済み
