#!/bin/bash
# run-all.sh: 全社員を一括実行するメインスクリプト
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

echo "========================================="
echo "  X Marketing Company - 全社員起動"
echo "  日付: $(date +%Y-%m-%d)"
echo "  時刻: $(date +%H:%M)"
echo "========================================="
echo ""

# ログディレクトリ確認
mkdir -p "$LOG_DIR"

# Phase 1: アカウント選定（他の社員の依存元）
echo "【Phase 1】account-selector を起動..."
bash "${SCRIPT_DIR}/employees/account-selector/run.sh"
echo ""

# Phase 2: 並列実行可能な社員たち
echo "【Phase 2】各社員を順次起動..."

echo "--- reply-worker ---"
bash "${SCRIPT_DIR}/employees/reply-worker/run.sh"
echo ""

echo "--- like-worker ---"
bash "${SCRIPT_DIR}/employees/like-worker/run.sh"
echo ""

echo "--- quote-poster ---"
bash "${SCRIPT_DIR}/employees/quote-poster/run.sh"
echo ""

echo "--- content-poster ---"
bash "${SCRIPT_DIR}/employees/content-poster/run.sh"
echo ""

echo "--- line-builder ---"
bash "${SCRIPT_DIR}/employees/line-builder/run.sh"
echo ""

echo "========================================="
echo "  全社員の実行が完了しました"
echo "  ログ: ${LOG_DIR}/"
echo ""
echo "  【社長のTodo】"
echo "  1. content-log を確認 → send-post.sh で投稿"
echo "  2. reply-log を確認 → send-reply.sh でリプライ"
echo "  3. quote-log を確認 → send-quote.sh で引用ポスト"
echo "========================================="
