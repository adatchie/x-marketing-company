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

    jq -n \
        --arg title "$title" \
        --arg desc "$content" \
        --argjson color "$color" \
        '{
            embeds: [{
                title: $title,
                description: ($desc | .[0:1900]),
                color: $color
            }]
        }' > "$tmp_json"

    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d @"$tmp_json" > /dev/null 2>&1

    rm -f "$tmp_json"
}

# 下書きを個別にDiscordに通知（承認リンク付き）
# $1: 社員名, $2: 下書きID, $3: 下書き内容
notify_draft_item() {
    local employee="$1"
    local draft_id="$2"
    local draft_content="$3"

    if [ -z "$DISCORD_WEBHOOK_URL" ]; then
        return 0
    fi

    local approve_url="https://github.com/${GITHUB_REPO}/actions/workflows/approve.yml"
    local tmp_json
    tmp_json=$(mktemp)

    local truncated_content="$draft_content"
    if [ ${#truncated_content} -gt 600 ]; then
        truncated_content="${truncated_content:0:600}..."
    fi

    local instructions="[Approve/Revise/Regenerate](${approve_url})\nページ右側の「Run workflow ▼」を押して:\ndraft_idに下記をコピペ:\n\`\`\`\n${draft_id}\n\`\`\`\napprove→そのままRun\nrevise→actionをreviseに + feedbackに修正指示\nregenerate→actionをregenerateに + feedback空OK"

    jq -n \
        --arg title "[${employee}] $(date +%Y-%m-%d)" \
        --arg content "$truncated_content" \
        --arg instructions "$instructions" \
        '{
            embeds: [{
                title: $title,
                description: $content,
                color: 3447003,
                fields: [
                    { name: "How to approve/revise", value: $instructions }
                ],
                footer: { text: "Auto-approve in 2h" }
            }]
        }' > "$tmp_json"

    curl -s -X POST "$DISCORD_WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d @"$tmp_json" > /dev/null 2>&1

    rm -f "$tmp_json"
}

# 下書きログ全体をDiscordに通知（サマリー用）
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

    if [ ${#content} -gt 1900 ]; then
        content="${content:0:1900}..."
    fi

    notify_discord "【${employee}】Summary $(date +%Y-%m-%d)" "$content"
}

# 実行結果をDiscordに通知
notify_result() {
    local employee="$1"
    local action="$2"
    local result="$3"
    local success="${4:-true}"

    local color=3066993
    if [ "$success" = "false" ]; then
        color=15158332
    fi

    notify_discord "【${employee}】${action}" "$result" "$color"
}
