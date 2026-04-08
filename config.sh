#!/bin/bash
# X Marketing Company 共通設定

# xurlコマンド（npx経由）
XURL="npx xurl"

# 運用アカウント
OPERATING_ACCOUNT="analaeon"

# 認証方式
AUTH_TYPE="oauth1"

# ログディレクトリ
LOG_DIR="employees/logs"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/daily-${TODAY}.log"

# ターゲット層のキーワード
TARGET_KEYWORDS=("副業" "AI活用" "フリーランス" "一人起業" "AI副業")

# ハッシュタグ
TARGET_HASHTAGS=("#副業" "#AI活用" "#フリーランス" "#一人起業")

# API制限対策：各操作間の待機秒数
ACTION_DELAY=3

# LLM API設定（GLM-5.1 / Z.AI OpenAI互換）
LLM_API_KEY="${LLM_API_KEY:-}"
LLM_MODEL="${LLM_MODEL:-glm-5.1}"
LLM_API_URL="${LLM_API_URL:-https://api.z.ai/api/coding/paas/v4/chat/completions}"

# Discord通知
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"

# 承認設定
AUTO_APPROVE_HOURS="${AUTO_APPROVE_HOURS:-2}"
PENDING_DIR="${LOG_DIR}/pending"

# 学習データ
METRICS_DIR="${LOG_DIR}/metrics"
INSIGHTS_DIR="${LOG_DIR}/insights"

# GitHub（承認リンク用）
GITHUB_REPO="${GITHUB_REPO:-adatchie/x-marketing-company}"
