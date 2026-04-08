#!/bin/bash
# content-poster: 投稿・記事の作成とポストを行う
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "content-poster" "コンテンツ作成を開始します"

CONTENT_LOG="${LOG_DIR}/content-log-${TODAY}.md"

cat > "$CONTENT_LOG" << HEADER
# コンテンツ投稿ログ $(date +%Y-%m-%d)
HEADER

# 学習インサイトを読み込み
INSIGHTS_CONTEXT=""
if [ -f "${INSIGHTS_DIR}/latest.md" ]; then
    INSIGHTS_CONTEXT=$(cat "${INSIGHTS_DIR}/latest.md" | head -50)
    log "content-poster" "過去のインサイトを読み込み"
fi

# インサイト付きプロンプトのヘッダー
build_prompt() {
    local base_prompt="$1"
    if [ -n "$INSIGHTS_CONTEXT" ]; then
        echo "${base_prompt}

【過去の投稿分析からの学習】
${INSIGHTS_CONTEXT}
上記のインサイトを参考に、より効果的な投稿を作成してください。"
    else
        echo "$base_prompt"
    fi
}

# ポスト生成プロンプト
MORNING_PROMPT='以下の条件でX（Twitter）の投稿文を1つ作成してください。
テーマ: 気づき・名言・今日の一言
ターゲット: 副業・AI活用に興味がある30代〜40代
文字数: 100〜200文字
ハッシュタグを2〜3個含める
トーン: 親しみやすく、専門的すぎない
出力は投稿文のみ（説明や前置きは不要）'

NOON_PROMPT='以下の条件でX（Twitter）の投稿文を1つ作成してください。
テーマ: ノウハウ・豆知識・実体験（リスト型 or 問題提起型）
ターゲット: 副業・AI活用に興味がある30代〜40代
文字数: 150〜250文字
ハッシュタグを2〜3個含める
トーン: 親しみやすく、専門的すぎない
出力は投稿文のみ（説明や前置きは不要）'

NIGHT_PROMPT='以下の条件でX（Twitter）の投稿文を1つ作成してください。
テーマ: 問いかけ・アンケート・振り返り
ターゲット: 副業・AI活用に興味がある30代〜40代
文字数: 100〜200文字
ハッシュタグを2〜3個含める
トーン: 親しみやすく、専門的すぎない
出力は投稿文のみ（説明や前置きは不要）'

# インサイトを反映
MORNING_PROMPT=$(build_prompt "$MORNING_PROMPT")
NOON_PROMPT=$(build_prompt "$NOON_PROMPT")
NIGHT_PROMPT=$(build_prompt "$NIGHT_PROMPT")

# フォールバック（LLM APIなし用）
fallback_morning() {
    cat << 'EOF'
AIを使えば、一人でも小さな会社が作れる時代になりました。
今日もAI社員たちと一緒に、コツコツ発信していきます。
あなたは、AIを日常で活用してますか？

#AI副業 #一人起業
EOF
}

fallback_noon() {
    cat << 'EOF'
副業で稼ぐ人が共通してやってること3つ：

1️⃣ 毎日15分でもアウトプットする
2️⃣ AIツールを率先で取り入れる
3️⃣ 完璧を目指さず「まず出す」を徹底する

どれか一つでも始めてみませんか？

#副業 #AI活用
EOF
}

fallback_night() {
    cat << 'EOF'
今日一日を振り返ってみて。
「前に進んだな」と思えた日は、
どんなに小さくても成果が出た日。

逆に「何もできなかった」と感じた日は、
大抵、手を動かさず考えてばかりだった日。

明日は手を動かす日にしませんか？

#フリーランス #一人起業
EOF
}

# 投稿生成
generate_post() {
    local phase="$1"
    local prompt="$2"
    local fallback_func="$3"

    local post
    if [ -n "$LLM_API_KEY" ]; then
        log "content-poster" "${phase}の投稿をLLMで生成中..."
        post=$(llm_generate "$prompt")
        if [ -z "$post" ]; then
            log "content-poster" "LLM生成失敗、フォールバックを使用"
            post=$($fallback_func)
        fi
    else
        post=$($fallback_func)
    fi
    echo "$post"
}

MORNING_POST=$(generate_post "朝" "$MORNING_PROMPT" fallback_morning)
NOON_POST=$(generate_post "昼" "$NOON_PROMPT" fallback_noon)
NIGHT_POST=$(generate_post "夜" "$NIGHT_PROMPT" fallback_night)

# 投稿案をログに保存
cat >> "$CONTENT_LOG" << CONTENT

## 朝の投稿案（7:00頃）
${MORNING_POST}

---

## 昼の投稿案（12:00頃）
${NOON_POST}

---

## 夜の投稿案（21:00頃）
${NIGHT_POST}
CONTENT

log "content-poster" "3件の投稿案を作成"
log "content-poster" "保存先: ${CONTENT_LOG}"

# 承認待ちキューに登録 + Discord通知
for phase_name in "朝:morning" "昼:noon" "夜:night"; do
    label="${phase_name%%:*}"
    key="${phase_name##*:}"
    case "$key" in
        morning) post_text="$MORNING_POST" ;;
        noon)    post_text="$NOON_POST" ;;
        night)   post_text="$NIGHT_POST" ;;
    esac

    draft_data=$(jq -n --arg pt "$post_text" '{post_text: $pt}')
    draft_id=$(queue_approval "content" "$draft_data")
    log "content-poster" "承認待ち登録: ${label}の投稿 (ID: ${draft_id})"
done

notify_draft "content-poster" "$CONTENT_LOG"
