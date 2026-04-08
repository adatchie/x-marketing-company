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

# LLM API設定（環境変数から読み込み、未設定ならデフォルト）
LLM_API_KEY="${LLM_API_KEY:-}"
LLM_MODEL="${LLM_MODEL:-claude-sonnet-4-20250514}"
LLM_API_URL="${LLM_API_URL:-https://api.anthropic.com/v1/messages}"
