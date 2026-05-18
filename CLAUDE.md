# CLAUDE.md

## プロジェクト概要
NocoBaseをAzure上で運用するためのインフラストラクチャを構築・管理するTerraformプロジェクトです。
Terraformのベストプラクティスに基づいたクリーン、安全、かつ拡張性の高いコード管理を目指します。
必要に応じて `terraform-mcp` を活用し、リソースの参照や構成の最適化を行ってください。

## 技術スタック
- **IaC:** Terraform
- **環境管理:** mise
- **CLI:** azure-cli, WSL (Windows Subsystem for Linux)
- **静的解析・品質管理:** tflint, terraform-docs
- **セキュリティ・スキャン:** trivy, checkov, pre-commit (prek), gitleaks

## 主要コマンド
日常的な開発、検証、コード品質維持のために以下のコマンドを使用します。

### 1. 開発・デプロイ
```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# 変更の適用
terraform apply

```

### 2. 構文チェック・品質管理

```bash
# 修正とフォーマット（必ず実行すること）
terraform fmt

# 静的解析 (Lint) の実行
tflint

```

### 3. ドキュメント生成

```bash
# README等の自動更新
terraform-docs markdown table --output-file README.md .

```

## コーディング規約・設計ルール

HashiCorp公式のスタイルガイド（ https://developer.hashicorp.com/terraform/language/style ）に厳格に従ってください。

### 1. 配置と命名規則

* 引数や属性は、関連性ごとにグループ分けし、等号（`=`）の位置を揃える（`terraform fmt` で自動整形されますが意識すること）。
* リソース名や変数名はスネークケース（`snake_case`）で統一する。
* 単一ファイルに詰め込まず、`main.tf`, `variables.tf`, `outputs.tf`, `providers.tf` などに適切に分割する。

### 2. 変数（Variables）と出力（Outputs）

* すべての `variable` には、必ず明確な `description` と `type` を定義すること。
* 必要に応じて `validation` ブロックを活用し、不正な入力値を防ぐこと。
* `output` にも必ず `description` を含めること。

## AIへの独自ルール（重要）

1. **厳格なバージョン指定:**
* Terraform本体、Azureプロバイダ（`azurerm`）、その他使用するすべての外部モジュールやツールにおいて、**`latest` やバージョン未指定は一切禁止**とします。必ず特定のバージョン、または安全なバージョン固定（例: `~> x.y.z`）を明記してください。


2. **セキュリティファースト:**
* TrivyやCheckov、Gitleaksによるスキャンを意識し、不必要なパブリックアクセスの許可や、平文でのシークレットの埋め込み（ハードコード）は絶対に避けてください。


3. **環境依存の排除:**
* WSL環境および `mise` を介したツール管理を前提とし、特定のローカル環境に依存する絶対パスの記述などは行わないでください。
