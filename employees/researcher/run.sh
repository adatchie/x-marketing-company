#!/bin/bash
# researcher: 外部リポジトリからリサーチデータを取得し、投稿用素材ブリーフを作成
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "researcher" "リサーチを開始します"

BRIEF_FILE="${LOG_DIR}/research-brief-${TODAY}.md"
RESEARCH_DIR="${SCRIPT_DIR}/.research-cache"

mkdir -p "$RESEARCH_DIR"

# --- 1. リサーチレポート取得 ---
log "researcher" "AI news reportを取得中..."
RESEARCH_REPORT=""
RESEARCH_FILE="${RESEARCH_DIR}/report-${TODAY}.md"

if command -v gh &>/dev/null; then
    gh api "repos/adatchie/x-article-research/contents/reports/ai-news/latest.md" \
        -H "Accept: application/vnd.github.raw+json" > "$RESEARCH_FILE" 2>/dev/null

    if [ -s "$RESEARCH_FILE" ]; then
        RESEARCH_REPORT=$(cat "$RESEARCH_FILE" | head -200)
        log "researcher" "リサーチレポート取得成功"
    else
        log "researcher" "リサーチレポート取得失敗"
    fi
fi

# --- 2. ブックマーク取得 ---
log "researcher" "ブックマークデータを取得中..."
BOOKMARKS=""
BOOKMARK_FILE="${RESEARCH_DIR}/bookmarks-${TODAY}.json"

if command -v gh &>/dev/null; then
    gh api "repos/adatchie/obsidian-vault/contents/Bookmarks/raw/${TODAY}.json" \
        -H "Accept: application/vnd.github.raw+json" > "$BOOKMARK_FILE" 2>/dev/null

    if [ ! -s "$BOOKMARK_FILE" ]; then
        # 前日のファイルを試す
        YESTERDAY=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
        gh api "repos/adatchie/obsidian-vault/contents/Bookmarks/raw/${YESTERDAY}.json" \
            -H "Accept: application/vnd.github.raw+json" > "$BOOKMARK_FILE" 2>/dev/null
    fi

    if [ -s "$BOOKMARK_FILE" ]; then
        # ブックマークからテキストを抽出（JSONの場合）
        BOOKMARKS=$(jq -r '.[] | .text // .content // .title // empty' "$BOOKMARK_FILE" 2>/dev/null | head -50)
        if [ -z "$BOOKMARKS" ]; then
            BOOKMARKS=$(cat "$BOOKMARK_FILE" | head -100)
        fi
        log "researcher" "ブックマーク取得成功"
    else
        log "researcher" "ブックマークデータなし"
    fi
fi

# --- 3. 記事取得（あれば） ---
log "researcher" "生成済み記事を確認中..."
ARTICLE=""
ARTICLE_FILE="${RESEARCH_DIR}/article-${TODAY}.md"

if command -v gh &>/dev/null; then
    gh api "repos/adatchie/x-article-research/contents/articles/ai-news/latest.md" \
        -H "Accept: application/vnd.github.raw+json" > "$ARTICLE_FILE" 2>/dev/null

    if [ -s "$ARTICLE_FILE" ]; then
        ARTICLE=$(cat "$ARTICLE_FILE" | head -150)
        log "researcher" "記事取得成功"
    fi
fi

# --- 4. LLMで素材ブリーフ生成 ---
BRIEF_PROMPT="あなたはX（Twitter）マーケティングのコンテンツディレクターです。
以下のリサーチデータをもとに、今日のX投稿用素材ブリーフを作成してください。

【リサーチレポート】
${RESEARCH_REPORT}

【ブックマーク】
${BOOKMARKS}

【参考記事（既に書かれたもの）】
${ARTICLE}

---以下のフォーマットで出力---

## トピック1: [見出し]
- 概要: 1文で
- なぜバズった: 共感ポイント
- 副業への応用: 具体的な使い道
- 投稿叩き1: 80〜140字の投稿文（ラフな口調、AIっぽくない、具体的）
- 投稿叩き2: 別の切り口の投稿文（同条件）

## トピック2: [見出し]
（同上）

※ 3〜5トピック取り上げる
※ 投稿文は「〜の時代になりました」「〜ではないでしょうか」等のAI臭い表現を絶対禁止
※ 投稿者はAI×副業の実践者という立場で書く
※ 具体的な数字や実例を必ず含める"

if [ -n "$LLM_API_KEY" ] && [ -n "$RESEARCH_REPORT$BOOKMARKS" ]; then
    log "researcher" "LLMで素材ブリーフを生成中..."
    BRIEF=$(llm_generate "$BRIEF_PROMPT" "あなたはSNSマーケティングのプロです。日本語の自然なSNS投稿を作成する専門家です。")

    if [ -n "$BRIEF" ]; then
        cat > "$BRIEF_FILE" << HEADER
# 素材ブリーフ $(date +%Y-%m-%d)
## データソース
- リサーチレポート: x-article-research
- ブックマーク: obsidian-vault

---

${BRIEF}
HEADER
        log "researcher" "素材ブリーフ生成完了"
    else
        generate_fallback_brief
    fi
else
    generate_fallback_brief
fi

log "researcher" "保存先: ${BRIEF_FILE}"

# --- 補助関数 ---
generate_fallback_brief() {
    log "researcher" "フォールバック: リサーチデータから簡易ブリーフ生成"

    cat > "$BRIEF_FILE" << HEADER
# 素材ブリーフ $(date +%Y-%m-%d)
## データソース
- リサーチレポート: ${RESEARCH_REPORT:+あり}${RESEARCH_REPORT:-なし}
- ブックマーク: ${BOOKMARKS:+あり}${BOOKMARKS:-なし}

---

HEADER

    # リサーチレポートからトピック見出しを抽出
    if [ -n "$RESEARCH_REPORT" ]; then
        echo "$RESEARCH_REPORT" | grep -E "^###|^##" | head -10 >> "$BRIEF_FILE"
    fi

    # ブックマークからテキスト断片を抽出
    if [ -n "$BOOKMARKS" ]; then
        echo "" >> "$BRIEF_FILE"
        echo "## ブックマーク抜粋" >> "$BRIEF_FILE"
        echo "$BOOKMARKS" | head -20 >> "$BRIEF_FILE"
    fi
}
