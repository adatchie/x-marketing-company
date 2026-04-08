#!/bin/bash
# like-worker: 戦略的いいね周りを実施する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "like-worker" "いいね回りを開始します"

LIKE_LOG="${LOG_DIR}/like-log-${TODAY}.md"
LIKED_TOTAL=0
MAX_LIKES=${1:-15}  # 1回の実行での上限（1日3回×15＝45）

cat > "$LIKE_LOG" << HEADER
# いいねログ $(date +%Y-%m-%d)
HEADER

# 各ハッシュタグで検索
for query in "#副業 -filter:retweets" "#AI活用 -filter:retweets" "#フリーランス -filter:retweets" "#一人起業 -filter:retweets"; do
    if [ "$LIKED_TOTAL" -ge "$MAX_LIKES" ]; then
        break
    fi

    log "like-worker" "検索: ${query}"
    RESULTS=$(xurl_exec search "$query" --max-results 10 2>/dev/null)
    safe_delay 3

    if [ -z "$RESULTS" ]; then
        continue
    fi

    # 投稿IDを抽出
    TWEET_IDS=$(echo "$RESULTS" | grep -o '"id":"[0-9]*"' | sed 's/"id":"//;s/"//' | head -5)

    for tweet_id in $TWEET_IDS; do
        if [ "$LIKED_TOTAL" -ge "$MAX_LIKES" ]; then
            break
        fi

        # 投稿テキストを取得
        TWEET_TEXT=$(echo "$RESULTS" | grep -o "\"text\":\"[^\"]*${tweet_id}[^\"]*\"" | head -1)
        USERNAME=$(echo "$RESULTS" | grep -o "\"username\":\"[^\"]*\"" | head -1 | sed 's/"username":"//;s/"//')

        # 宣伝っぽい投稿を除外（簡易フィルタ）
        if echo "$TWEET_TEXT" | grep -qiE "DM|無料|購入|申し込み|LINE登録|プロフ"; then
            continue
        fi

        # いいねを実行
        LIKE_RESULT=$(xurl_exec like "$tweet_id" 2>&1)
        safe_delay

        if echo "$LIKE_RESULT" | grep -q "liked"; then
            echo "- 投稿ID: ${tweet_id} | ハッシュタグ: ${query} | ステータス: いいね済み" >> "$LIKE_LOG"
            LIKED_TOTAL=$((LIKED_TOTAL + 1))
            log "like-worker" "いいね: 投稿ID ${tweet_id} (${LIKED_TOTAL}/${MAX_LIKES})"
        fi
    done
done

echo "" >> "$LIKE_LOG"
echo "合計いいね数: ${LIKED_TOTAL}" >> "$LIKE_LOG"

log "like-worker" "いいね回り完了: ${LIKED_TOTAL}件"
log "like-worker" "保存先: ${LIKE_LOG}"
