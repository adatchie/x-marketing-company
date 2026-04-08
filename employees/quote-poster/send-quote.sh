#!/bin/bash
# send-quote: 社長承認済みの引用ポストを投稿する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

if [ $# -lt 2 ]; then
    echo "使い方: ./send-quote.sh <元投稿ID> <引用コメント>"
    echo "例: ./send-quote.sh 1234567890 'この視点、大事ですよね。私の場合は...'"
    exit 1
fi

TWEET_ID="$1"
QUOTE_TEXT="$2"

log "quote-poster" "引用ポスト投稿: 元投稿ID=${TWEET_ID}"

RESULT=$(xurl_exec quote "$TWEET_ID" "$QUOTE_TEXT" 2>&1)

if echo "$RESULT" | grep -q '"id"'; then
    log "quote-poster" "引用ポスト投稿成功"
    echo "$RESULT"
else
    log "quote-poster" "引用ポスト投稿失敗: $RESULT"
    echo "エラー: $RESULT"
fi
