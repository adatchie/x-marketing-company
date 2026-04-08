#!/bin/bash
# 承認管理関数

# 承認待ちキューに追加
# $1: タイプ (content/reply/quote/account)
# $2: データ（JSON文字列）
# 出力: draft_id
queue_approval() {
    local type="$1"
    local data="$2"

    mkdir -p "$PENDING_DIR"

    local draft_id="${type}-$(date +%Y%m%d%H%M%S)-$$"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    local tmp_json
    tmp_json=$(mktemp)

    jq -n \
        --arg id "$draft_id" \
        --arg type "$type" \
        --arg ts "$timestamp" \
        --arg status "pending" \
        --argjson data "$data" \
        '{
            id: $id,
            type: $type,
            status: $status,
            created_at: $ts,
            data: $data
        }' > "$tmp_json"

    mv "$tmp_json" "${PENDING_DIR}/${draft_id}.json"
    echo "$draft_id"
}

# 承認待ちを取得
# $1: draft_id (省略時は全pending一覧)
get_pending() {
    local draft_id="$1"

    if [ -n "$draft_id" ]; then
        if [ -f "${PENDING_DIR}/${draft_id}.json" ]; then
            cat "${PENDING_DIR}/${draft_id}.json"
        fi
        return
    fi

    for f in "${PENDING_DIR}"/*.json; do
        [ -f "$f" ] || continue
        local status
        status=$(jq -r '.status' "$f" 2>/dev/null)
        if [ "$status" = "pending" ]; then
            cat "$f"
        fi
    done
}

# 承認を実行
# $1: draft_id, $2: 修正内容(任意)
approve_pending() {
    local draft_id="$1"
    local new_content="$2"
    local pending_file="${PENDING_DIR}/${draft_id}.json"

    if [ ! -f "$pending_file" ]; then
        echo "Error: draft not found: $draft_id"
        return 1
    fi

    local type
    type=$(jq -r '.type' "$pending_file")

    # ステータスをapprovedに更新
    local tmp_json
    tmp_json=$(mktemp)
    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {status: "approved", approved_at: $ts}' "$pending_file" > "$tmp_json"
    mv "$tmp_json" "$pending_file"

    # タイプ別に実行
    local data
    data=$(cat "$pending_file")

    case "$type" in
        content)
            local post_text
            if [ -n "$new_content" ]; then
                post_text="$new_content"
            else
                post_text=$(echo "$data" | jq -r '.data.post_text')
            fi
            bash "${SCRIPT_DIR}/employees/content-poster/send-post.sh" "$post_text"
            ;;
        reply)
            local tweet_id reply_text
            tweet_id=$(echo "$data" | jq -r '.data.tweet_id')
            if [ -n "$new_content" ]; then
                reply_text="$new_content"
            else
                reply_text=$(echo "$data" | jq -r '.data.reply_text')
            fi
            bash "${SCRIPT_DIR}/employees/reply-worker/send-reply.sh" "$tweet_id" "$reply_text"
            ;;
        quote)
            local tweet_id quote_text
            tweet_id=$(echo "$data" | jq -r '.data.tweet_id')
            if [ -n "$new_content" ]; then
                quote_text="$new_content"
            else
                quote_text=$(echo "$data" | jq -r '.data.quote_text')
            fi
            bash "${SCRIPT_DIR}/employees/quote-poster/send-quote.sh" "$tweet_id" "$quote_text"
            ;;
        account)
            # アカウントリストは承認のみ（実行アクションなし）
            log "account-selector" "アカウントリスト承認済み"
            ;;
    esac
}

# 時間切れの承認待ちを取得
get_expired() {
    local threshold_hours="${1:-$AUTO_APPROVE_HOURS}"
    local now
    now=$(date -u +%s)

    for f in "${PENDING_DIR}"/*.json; do
        [ -f "$f" ] || continue
        local status created_at
        status=$(jq -r '.status' "$f" 2>/dev/null)
        if [ "$status" != "pending" ]; then
            continue
        fi

        created_at=$(jq -r '.created_at' "$f" 2>/dev/null)
        local created_epoch
        # 日付文字列をエポックに変換（GNU dateが必要）
        if date --version &>/dev/null; then
            created_epoch=$(date -d "$created_at" +%s 2>/dev/null)
        else
            created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_at" +%s 2>/dev/null)
        fi

        if [ -n "$created_epoch" ]; then
            local diff=$(( (now - created_epoch) / 3600 ))
            if [ "$diff" -ge "$threshold_hours" ]; then
                jq -r '.id' "$f"
            fi
        fi
    done
}
