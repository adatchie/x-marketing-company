#!/bin/bash
# quote-poster: 引用ポストでエンゲージメントを高める
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "quote-poster" "引用ポスト候補の検索を開始します"

QUOTE_LOG="${LOG_DIR}/quote-log-${TODAY}.md"

cat > "$QUOTE_LOG" << HEADER
# 引用ポスト候補リスト $(date +%Y-%m-%d)
HEADER

# バズっている投稿を検索（いいね数の多いもの）
for query in "副業 min_faves:500" "AI min_faves:500" "フリーランス min_faves:300" "一人起業 min_faves:300"; do
    log "quote-poster" "検索: ${query}"
    RESULTS=$(xurl_exec search "$query" --max-results 10 2>/dev/null)
    safe_delay 3

    if [ -z "$RESULTS" ]; then
        continue
    fi

    # 投稿情報を抽出
    TWEET_IDS=$(echo "$RESULTS" | grep -o '"id":"[0-9]*"' | sed 's/"id":"//;s/"//' | head -3)
    TWEET_TEXTS=$(echo "$RESULTS" | grep -o '"text":"[^"]*"' | sed 's/"text":"//;s/"$//' | head -3)

    idx=0
    for tweet_id in $TWEET_IDS; do
        # テキストを取得（N行目）
        TWEET_TEXT=$(echo "$TWEET_TEXTS" | sed -n "$((idx+1))p")
        USERNAME=$(echo "$RESULTS" | grep -o '"username":"[^"]*"' | sed -n "$((idx+1))p" | sed 's/"username":"//;s/"//')
        idx=$((idx+1))

        if [ -z "$tweet_id" ] || [ -z "$TWEET_TEXT" ]; then
            continue
        fi

        # 引用コメント案を生成してログに記録
        cat >> "$QUOTE_LOG" << ENTRY

## 引用候補 ${idx}: @${USERNAME} の投稿
- 投稿ID: ${tweet_id}
- 投稿内容: ${TWEET_TEXT}

### 引用コメント案1（補足型）
この視点、大事ですよね。私の場合、〇〇を始めた当初は〇〇に悩んでいました。でも〇〇を取り入れたら行動速度が2倍になりました。皆さんはどうやってモチベーション維持してますか？

### 引用コメント案2（反論型）
これは半分同意、半分違う視点があります。確かに〇〇は大事。でも個人的には〇〇の方が先決だと思います。まず環境を整えてから取り組むと成功率が上がる気がします。どう思いますか？
ENTRY

        log "quote-poster" "候補追加: @${USERNAME} の投稿（ID: ${tweet_id}）"

        # 承認待ちに登録
        draft_data=$(jq -n \
            --arg tid "$tweet_id" \
            --arg tt "$TWEET_TEXT" \
            --arg qt "この視点、大事ですよね。私の場合も同じように感じています。" \
            '{tweet_id: $tid, tweet_text: $tt, quote_text: $qt}')
        draft_id=$(queue_approval "quote" "$draft_data")

        notify_draft_item "quote-poster (@${USERNAME})" "$draft_id" "Quote: ${TWEET_TEXT}"
    done
done

CANDIDATE_COUNT=$(grep -c "^## 引用候補" "$QUOTE_LOG" 2>/dev/null || echo "0")
log "quote-poster" "候補リスト作成完了: ${CANDIDATE_COUNT}件"
log "quote-poster" "保存先: ${QUOTE_LOG}"
