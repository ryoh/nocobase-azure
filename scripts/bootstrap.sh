#!/usr/bin/env bash
# Terraform リモートステート用 Storage Account を作成する（初回のみ実行）
# 使い方: bash scripts/bootstrap.sh
set -euo pipefail

CONTAINER_NAME="tfstate"
LOCATION="japaneast"
RESOURCE_GROUP="rg-tfstate"

echo "=== Terraform State Bootstrap ==="

# ログイン確認
if ! az account show &>/dev/null; then
  echo "Azure にログインしていません。az login を実行してください。"
  exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo "Subscription: ${SUBSCRIPTION_ID}"

# サブスクリプション ID の先頭 8 文字でグローバル一意名を生成
SUFFIX=$(echo "${SUBSCRIPTION_ID}" | tr -d '-' | cut -c1-8)
STORAGE_ACCOUNT="stncbtf${SUFFIX}"
echo "Storage Account 名: ${STORAGE_ACCOUNT}"

# Resource Group
echo "[1/3] Resource Group を作成中: ${RESOURCE_GROUP}"
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

# Storage Account（HTTPS のみ、最小 TLS 1.2、パブリックアクセス無効）
echo "[2/3] Storage Account を作成中: ${STORAGE_ACCOUNT}"
az storage account create \
  --name "${STORAGE_ACCOUNT}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --https-only true \
  --output none

# Blob Container
echo "[3/3] Blob Container を作成中: ${CONTAINER_NAME}"
az storage container create \
  --name "${CONTAINER_NAME}" \
  --account-name "${STORAGE_ACCOUNT}" \
  --auth-mode login \
  --output none

echo ""
echo "=== 完了 ==="
echo "Storage Account : ${STORAGE_ACCOUNT}"
echo "Container       : ${CONTAINER_NAME}"
echo ""
echo "次のステップ: 以下を providers.tf の backend ブロックに設定してください"
echo "  storage_account_name = \"${STORAGE_ACCOUNT}\""
