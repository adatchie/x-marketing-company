#!/bin/bash
# reply-worker: ターゲット投稿へのリプライを実施する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "reply-worker" "リプライ業務を開始します"

ACCOUNT_LIST="${LOG_DIR}/account-list-${TODAY}.md"
REPLY_LOG="${LOG_DIR}/reply-log-${TODAY}.md"

if [ ! -f "$ACCOUNT_LIST" ]; then
    log "reply-worker" "アカウントリストがありません。account-selectorを実行してください"
    exit 1
fi

cat > "$REPLY_LOG" << HEADER
# リプライログ $(date +%Y-%m-%d)
HEADER

USERNAMES=$(grep "^## @" "$ACCOUNT_LIST" | sed 's/## @//')

for username in $USERNAMES; do
    if [ "$username" = "$OPERATING_ACCOUNT" ]; then continue; fi

    log "reply-worker" "@${username} の直近投稿を取得中..."

    TWEETS=$(xurl_exec search "from:${username}" --max-results 5 2>/dev/null)
    safe_delay 3

    if [ -z "$TWEETS" ]; then
        log "reply-worker" "@${username} の投稿取得に失敗、スキップ"
        continue
    fi

    TWEET_ID=$(echo "$TWEETS" | grep -o '"id":"[0-9]*"' | head -1 | sed 's/"id":"//;s/"//')
    TWEET_TEXT=$(echo "$TWEETS" | grep -o '"text":"[^"]*"' | head -1 | sed 's/"text":"//;s/"$//')

    if [ -z "$TWEET_ID" ]; then continue; fi

    cat >> "$REPLY_LOG" << ENTRY

## @${username} へのリプライ案
- 元投稿: ${TWEET_TEXT}
- 投稿ID: ${TWEET_ID}

### リプライ案1（共感型）
> ${TWEET_TEXT} ←これ、すごく分かります！私も同じように感じていて、最近は〇〇するようにしたら少し楽になりました。具体的にはどうやって解決されましたか？

### リプライ案2（質問型）
> なるほど！興味深い視点ですね。私も〇〇について考えているんですが、その場合どういうアプローチがいいと思いますか？

### リプライ案3（経験共有型）
> これ読んで共感しました。私も昨年〇〇で同じ壁にぶつかって、〇〇を試したら上手くいきました。まだ続けてますか？
ENTRY

    log "reply-worker" "@${username} へのリプライ案を3パターン作成（投稿ID: ${TWEET_ID}）"
done

REPLY_COUNT=$(grep -c "投稿ID:" "$REPLY_LOG" 2>/dev/null || echo "0")
log "reply-worker" "リプライ案作成完了: ${REPLY_COUNT}件"
log "reply-worker" "保存先: ${REPLY_LOG}"
log "reply-worker" "※ 社長承認後に send-reply.sh で送信してください"
