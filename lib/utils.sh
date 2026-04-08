#!/bin/bash
# 共通ユーティリティ関数

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$(dirname "${LIB_DIR}")"
source "${SCRIPT_DIR}/config.sh"

# ログ出力
log() {
    local employee="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${employee}] ${message}" | tee -a "${LOG_FILE}"
}

# xurlを実行（認証付き）
xurl_exec() {
    $XURL --auth $AUTH_TYPE "$@"
}

# JSONから値を抽出（簡易版）
json_value() {
    local key="$1"
    local json="$2"
    echo "$json" | grep -o "\"${key}\":\"[^\"]*\"" | head -1 | sed "s/\"${key}\":\"//" | sed 's/"$//'
}

# 安全な待機（API制限回避）
safe_delay() {
    local base=${1:-$ACTION_DELAY}
    local jitter=$((RANDOM % 3))
    sleep $((base + jitter))
}

# LLM API呼び出し
llm_generate() {
    local prompt="$1"
    local system_prompt="${2:-あなたはX（Twitter）のマーケティング専門家です。日本語で回答してください。}"

    if [ -z "$LLM_API_KEY" ]; then
        echo ""
        return 1
    fi

    # JSONを一時ファイルに書き出して送信（Windowsのエンコーディング問題回避）
    local tmp_json
    tmp_json=$(mktemp)
    jq -n \
        --arg model "$LLM_MODEL" \
        --arg system "$system_prompt" \
        --arg user "$prompt" \
        '{
            model: $model,
            max_tokens: 4096,
            messages: [
                {role: "system", content: $system},
                {role: "user", content: $user}
            ]
        }' > "$tmp_json"

    local response
    response=$(curl -s "$LLM_API_URL" \
        -H "Content-Type: application/json; charset=utf-8" \
        -H "Authorization: Bearer $LLM_API_KEY" \
        -d @"$tmp_json")
    rm -f "$tmp_json"

    echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null
}
