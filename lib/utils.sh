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

    # URLからAPI種別を判定
    if echo "$LLM_API_URL" | grep -q "anthropic"; then
        # Claude API
        curl -s "$LLM_API_URL" \
            -H "Content-Type: application/json" \
            -H "x-api-key: $LLM_API_KEY" \
            -H "anthropic-version: 2023-06-01" \
            -d "$(cat <<JSON
{
    "model": "$LLM_MODEL",
    "max_tokens": 1024,
    "system": "$system_prompt",
    "messages": [{"role": "user", "content": $(echo "$prompt" | jq -Rs .)}]
}
JSON
)" | jq -r '.content[0].text // empty' 2>/dev/null
    elif echo "$LLM_API_URL" | grep -q "openai"; then
        # OpenAI API
        curl -s "$LLM_API_URL" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $LLM_API_KEY" \
            -d "$(cat <<JSON
{
    "model": "$LLM_MODEL",
    "max_tokens": 1024,
    "messages": [
        {"role": "system", "content": "$system_prompt"},
        {"role": "user", "content": $(echo "$prompt" | jq -Rs .)}
    ]
}
JSON
)" | jq -r '.choices[0].message.content // empty' 2>/dev/null
    else
        # 汎用（OpenAI互換）
        curl -s "$LLM_API_URL" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $LLM_API_KEY" \
            -d "$(cat <<JSON
{
    "model": "$LLM_MODEL",
    "max_tokens": 1024,
    "messages": [
        {"role": "system", "content": "$system_prompt"},
        {"role": "user", "content": $(echo "$prompt" | jq -Rs .)}
    ]
}
JSON
)" | jq -r '.choices[0].message.content // .content[0].text // empty' 2>/dev/null
    fi
}
