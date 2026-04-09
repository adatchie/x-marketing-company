#!/bin/bash
# send-post: 承認済みの投稿をポストする（スレッド対応）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

if [ $# -lt 1 ]; then
    echo "Usage: ./send-post.sh <post1> [post2] [post3]"
    echo "  Single post: ./send-post.sh 'text'"
    echo "  Thread:      ./send-post.sh 'first post' 'second post' 'third post'"
    exit 1
fi

log "content-poster" "投稿を実行します (${#}件)"

FIRST_TEXT="$1"
shift

# 1投稿目
log "content-poster" "投稿1/$((${#}+1))"
RESULT=$(xurl_exec post "$FIRST_TEXT" 2>&1)

if ! echo "$RESULT" | grep -q '"id"'; then
    log "content-poster" "投稿失敗: $RESULT"
    echo "Error: $RESULT"
    exit 1
fi

TWEET_ID=$(echo "$RESULT" | grep -o '"id":"[0-9]*"' | head -1 | sed 's/"id":"//;s/"//')
log "content-poster" "投稿成功: ID ${TWEET_ID}"
echo "Post 1 ID: ${TWEET_ID}"
safe_delay 2

# スレッド（2投稿目以降）
idx=2
for text in "$@"; do
    log "content-poster" "投稿${idx}/$((${#}+1)) (thread reply to ${TWEET_ID})"
    RESULT=$(xurl_exec reply "$TWEET_ID" "$text" 2>&1)

    if ! echo "$RESULT" | grep -q '"id"'; then
        log "content-poster" "投稿${idx}失敗: $RESULT"
        echo "Error on post ${idx}: $RESULT"
        exit 1
    fi

    TWEET_ID=$(echo "$RESULT" | grep -o '"id":"[0-9]*"' | head -1 | sed 's/"id":"//;s/"//')
    log "content-poster" "投稿${idx}成功: ID ${TWEET_ID}"
    echo "Post ${idx} ID: ${TWEET_ID}"
    safe_delay 2
    idx=$((idx + 1))
done

log "content-poster" "全投稿完了 (${#}件)"
