#!/bin/bash
# Discord通知関数

# DiscordにWebhookでメッセージ送信
# $1: タイトル, $2: 内容, $3: カラー(任意, デフォルト青)
notify_discord() {
    local title="$1"
    local content="$2"
    local color="${3:-3447003}"

    if [ -z "$DISCORD_WEBHOOK_URL" ]; then
        return 0
    fi

    local tmp_json
    tmp_json=$(mktemp)

    local approve_url="https://github.com/${GITHUB_REPO}/actions/workflows/approve.yml"

    jq -n \
        --arg title "$title" \
        --arg desc "$content" \
        --argjson color "$color" \
        --arg approve "$approve_url" \
        '{
            embeds: [{
                title: $title,
                description: $desc,
                color: $color,
                footer: { text: "⏰ 自動承認まで: 2時間" },
                fields: [
                    { name: "✅ 承認", value: ["[Run workflow](", $approve, "?action=approve)"] | join(""), inline: true },
                    { name: "✏️ 編集して承認", value: ["[Run workflow](", $approve, "?action=edit)"] | join(""), inline: true }
                ]
            }]
        }' > "$tmp_json"

    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d @"$tmp_json" > /dev/null 2>&1

    rm -f "$tmp_json"
}

# 下書きログをDiscordに通知
# $1: 社員名, $2: ログファイルパス
notify_draft() {
    local employee="$1"
    local log_file="$2"

    if [ -z "$DISCORD_WEBHOOK_URL" ]; then
        return 0
    fi

    if [ ! -f "$log_file" ]; then
        return 0
    fi

    local content
    content=$(cat "$log_file" | head -100)

    # Discordのembed description上限2000文字
    if [ ${#content} -gt 1900 ]; then
        content="${content:0:1900}..."
    fi

    notify_discord "【${employee}】下書き $(date +%Y-%m-%d)" "$content"
}

# 実行結果をDiscordに通知
notify_result() {
    local employee="$1"
    local action="$2"
    local result="$3"
    local success="${4:-true}"

    local color=3066993  # 緑=成功
    if [ "$success" = "false" ]; then
        color=15158332    # 赤=失敗
    fi

    local content="${action}\n${result}"
    if [ ${#content} -gt 1900 ]; then
        content="${content:0:1900}..."
    fi

    notify_discord "【${employee}】${action}" "$content" "$color"
}
