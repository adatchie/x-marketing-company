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

# ポスト生成プロンプト（共通ルール）
PROMPT_RULES='【絶対守るべきルール】
1. 人間が書いたように自然な日本語で書く。AIっぽい表現は一切禁止。
2. 以下の表現は絶対に使わない：「〜の時代になりました」「〜ではないでしょうか」「〜を始めてみませんか」「皆さん」「 importante」「ぜひ」「皆様」「〜をサポートします」「〜を実現しましょう」
3. 「です・ます」ではなく、ブログやSNSでよくある「だ・である」混じりのラフな口調で書く
4. 一人称は「私」ではなく「ぼく」または省略
5. 感嘆符（！）は1投稿につき1個まで
6. 絵文字は1投稿につき2個まで
7. 具体的な数字や実体験を必ず1つ入れる（架空でもリアルに聞こえるもの）
8. ハッシュタグは2〜3個、本文の最後に改行してから置く
9. 出力は投稿文のみ。説明・前置き・タイトル・括弧書きは一切不要'

# ポスト生成プロンプト
MORNING_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【今回のテーマ】気づき・日々の小さな発見
【ターゲット】副業やAI活用に興味がある30代〜40代の会社員
【文字数】80〜140文字（短めに）
【構成】具体的な出来事や気づき → それに対する率直な感想1文

【良い例】
電車で隣の人がAIで副業のサイト作ってた。普通にエクセルより早い。これもう仕事変わるなと思った。

#副業 #AI活用"

NOON_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【今回のテーマ】ノウハウ・気づいたこと（リスト型）
【ターゲット】副業やAI活用に興味がある30代〜40代の会社員
【文字数】120〜180文字
【構成】共感できる悩み → 解決法を3つリスト → 最後にサラッと問いかけ

【良い例】
副業始める前に悩むこと3つ：
・何から始めればいいか分からない
・失敗したらどうしよう
・時間が足りない

結論：全部AIで解決する。0円で始められて、失敗しても痛くない。時間は1日15分でいい。

#副業 #一人起業"

NIGHT_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【今回のテーマ】問いかけ・悩みへの共感
【ターゲット】副業やAI活用に興味がある30代〜40代の会社員
【文字数】60〜120文字（短く）
【構成】相手の気持ちに寄り添う一文 → 問いかけ

【良い例】
本業だけで家族養える人、今どきどれくらいいるんだろう。
月5万でも別の収入源があるだけで、心持ちだいぶ違う気がする。

#フリーランス #副業"

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

# 承認待ちキューに登録 + Discord通知（個別）
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

    notify_draft_item "content-poster (${label})" "$draft_id" "$post_text"
done
