#!/bin/bash
# account-selector: 絡むべき交流アカウントを検索・選定する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "account-selector" "交流アカウント選定を開始します"

OUTPUT_FILE="${LOG_DIR}/account-list-${TODAY}.md"

cat > "$OUTPUT_FILE" << HEADER
# 交流アカウントリスト $(date +%Y-%m-%d)
HEADER

for keyword in "副業 AI" "AI活用" "フリーランス 初心者" "一人起業 AI"; do
    log "account-selector" "キーワード検索: ${keyword}"

    RESULTS=$(xurl_exec search "${keyword}" --max-results 20 2>/dev/null)

    echo "$RESULTS" | grep -o '"username":"[^"]*"' | sed 's/"username":"//;s/"//' | sort -u | head -5 | while read -r username; do
        if [ -n "$username" ] && [ "$username" != "$OPERATING_ACCOUNT" ]; then
            USER_INFO=$(xurl_exec user "$username" 2>/dev/null)
            safe_delay 2

            if [ -n "$USER_INFO" ]; then
                FOLLOWERS=$(echo "$USER_INFO" | grep -o '"followers_count":[0-9]*' | head -1 | sed 's/"followers_count"://')
                NAME=$(echo "$USER_INFO" | grep -o '"name":"[^"]*"' | head -1 | sed 's/"name":"//;s/"//')

                if [ -n "$FOLLOWERS" ] && [ "$FOLLOWERS" -ge 500 ] 2>/dev/null && [ "$FOLLOWERS" -le 5000 ] 2>/dev/null; then
                    echo "" >> "$OUTPUT_FILE"
                    echo "## @${username}" >> "$OUTPUT_FILE"
                    echo "- 表示名: ${NAME}" >> "$OUTPUT_FILE"
                    echo "- フォロワー数: ${FOLLOWERS}" >> "$OUTPUT_FILE"
                    echo "- 検索キーワード: ${keyword}" >> "$OUTPUT_FILE"
                    echo "- 選定日: $(date +%Y-%m-%d)" >> "$OUTPUT_FILE"

                    log "account-selector" "選定: @${username} (${FOLLOWERS}フォロワー)"
                fi
            fi
        fi
    done

    safe_delay 5
done

ACCOUNT_COUNT=$(grep -c "^## @" "$OUTPUT_FILE" 2>/dev/null || echo "0")
log "account-selector" "選定完了: ${ACCOUNT_COUNT}件のアカウントをリストアップ"
log "account-selector" "保存先: ${OUTPUT_FILE}"
