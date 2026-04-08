#!/bin/bash
# send-reply: 社長承認済みのリプライを送信する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

if [ $# -lt 2 ]; then
    echo "使い方: ./send-reply.sh <投稿ID> <リプライテキスト>"
    echo "例: ./send-reply.sh 1234567890 '素晴らしい投稿ですね！私も同じように感じています。'"
    exit 1
fi

TWEET_ID="$1"
REPLY_TEXT="$2"

log "reply-worker" "リプライ送信: 投稿ID=${TWEET_ID}"

# リプライを送信
RESULT=$(xurl_exec reply "$TWEET_ID" "$REPLY_TEXT" 2>&1)

if echo "$RESULT" | grep -q '"id"'; then
    log "reply-worker" "リプライ送信成功"
    echo "$RESULT"
else
    log "reply-worker" "リプライ送信失敗: $RESULT"
    echo "エラー: $RESULT"
fi
