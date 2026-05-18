# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要
NocoBaseをAzure上で運用するためのインフラストラクチャを構築・管理するTerraformプロジェクトです。
Terraformのベストプラクティスに基づいたクリーン、安全、かつ拡張性の高いコード管理を目指します。
必要に応じて `terraform-mcp` を活用し、リソースの参照や構成の最適化を行ってください。

## 技術スタック
- **IaC:** Terraform
- **環境管理:** mise（ツールバージョンは `mise.toml` で固定）
- **CLI:** azure-cli, WSL (Windows Subsystem for Linux)
- **静的解析・品質管理:** tflint, terraform-docs
- **セキュリティ・スキャン:** trivy, checkov, gitleaks
- **pre-commit:** prek

## ツールバージョン（mise.toml より）

| ツール | バージョン |
|---|---|
| terraform | 1.15.3 |
| tflint | 0.62.1 |
| checkov | 3.2.529 |
| trivy | 0.70.0 |
| gitleaks | 8.30.1 |
| prek | 0.4.0 |
| python | 3.14.5 |

> `terraform-docs` は現時点で `mise.toml` に未登録。必要な場合は `mise.toml` に追加すること。

## セットアップ

```bash
# ツール一式をインストール
mise install

# pre-commit フックをインストール
prek install
```

## 主要コマンド

### 開発・デプロイ
```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### フォーマット・Lint
```bash
# コード変更後は必ず実行すること
terraform fmt -recursive
tflint --recursive
```

### セキュリティスキャン
```bash
trivy config .
checkov -d .
gitleaks detect --source .
```

### ドキュメント生成
```bash
terraform-docs markdown table --output-file README.md .
```

## MCP サーバー（terraform-mcp）

`.vscode/mcp.json` にて Docker 経由で Terraform MCP サーバーを起動する設定が済んでいる。
リソース仕様・プロバイダ情報の参照や構成の最適化に活用すること。

```json
// Docker コンテナとして起動される
"command": "wsl", "args": ["docker", "run", "-i", "--rm", "hashicorp/terraform-mcp-server"]
```

## ファイル構成規約

単一ファイルに詰め込まず、役割ごとに分割すること：

| ファイル | 用途 |
|---|---|
| `main.tf` | リソース定義 |
| `variables.tf` | 入力変数 |
| `outputs.tf` | 出力値 |
| `providers.tf` | プロバイダ・バージョン制約 |
| `locals.tf` | ローカル値（必要な場合） |
| `data.tf` | データソース（必要な場合） |

モジュールは `modules/<name>/` 配下に配置する。

## コーディング規約

HashiCorp 公式スタイルガイド（ https://developer.hashicorp.com/terraform/language/style ）に厳格に従うこと。

- リソース名・変数名はスネークケース（`snake_case`）で統一する
- すべての `variable` に `description` と `type` を定義する
- 必要に応じて `validation` ブロックで不正な入力値を防ぐ
- すべての `output` に `description` を含める

## AIへの独自ルール（重要）

1. **厳格なバージョン指定:**
   Terraform 本体、`azurerm` プロバイダ、外部モジュールすべてにおいて `latest` やバージョン未指定は禁止。必ず特定バージョンまたは安全な範囲固定（例: `~> x.y.z`）を明記すること。

2. **セキュリティファースト:**
   不必要なパブリックアクセスの許可や、平文でのシークレットのハードコードは絶対に避けること。Trivy・Checkov・Gitleaks のチェックを常に意識すること。

3. **環境依存の排除:**
   WSL 環境および `mise` を介したツール管理を前提とし、特定のローカル環境に依存する絶対パスは記述しないこと。
