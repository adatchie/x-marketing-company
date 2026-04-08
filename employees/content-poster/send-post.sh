#!/bin/bash
# send-post: 社長承認済みの投稿をポストする
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

if [ $# -lt 1 ]; then
    echo "使い方: ./send-post.sh <投稿テキスト>"
    echo "例: ./send-post.sh 'AIを使えば、一人でも小さな会社が作れる時代になりました。'"
    exit 1
fi

POST_TEXT="$1"

log "content-poster" "投稿を実行します"

RESULT=$(xurl_exec post "$POST_TEXT" 2>&1)

if echo "$RESULT" | grep -q '"id"'; then
    TWEET_ID=$(echo "$RESULT" | grep -o '"id":"[0-9]*"' | head -1 | sed 's/"id":"//;s/"//')
    log "content-poster" "投稿成功: 投稿ID ${TWEET_ID}"
    echo "$RESULT"
else
    log "content-poster" "投稿失敗: $RESULT"
    echo "エラー: $RESULT"
fi
