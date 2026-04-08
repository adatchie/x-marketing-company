#!/bin/bash
# content-poster: リサーチベースの投稿・記事の作成
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "content-poster" "コンテンツ作成を開始します"

CONTENT_LOG="${LOG_DIR}/content-log-${TODAY}.md"

cat > "$CONTENT_LOG" << HEADER
# コンテンツ投稿ログ $(date +%Y-%m-%d)
HEADER

# リサーチブリーフを読み込み
RESEARCH_BRIEF=""
BRIEF_FILE="${LOG_DIR}/research-brief-${TODAY}.md"
if [ -f "$BRIEF_FILE" ]; then
    RESEARCH_BRIEF=$(cat "$BRIEF_FILE")
    log "content-poster" "リサーチブリーフを読み込み"
else
    log "content-poster" "リサーチブリーフなし（フォールバック生成）"
fi

# 学習インサイトを読み込み
INSIGHTS_CONTEXT=""
if [ -f "${INSIGHTS_DIR}/latest.md" ]; then
    INSIGHTS_CONTEXT=$(cat "${INSIGHTS_DIR}/latest.md" | head -30)
fi

# 共通ルール
PROMPT_RULES='【絶対守るべきルール】
1. 人間が書いたように自然な日本語。AIっぽい表現は一切禁止。
2. 禁止表現：「〜の時代になりました」「〜ではないでしょうか」「〜を始めてみませんか」「皆さん」「ぜひ」「皆様」「〜をサポートします」「〜を実現しましょう」「〜について考えてみましょう」「〜の重要性が〜」「革新的な」「画期的な」
3. 口調は「だ・である」混じりのラフなSNS口調
4. 一人称は「ぼく」または省略
5. 感嘆符は1投稿1個まで、絵文字は2個まで
6. 具体的な数字・ツール名・手法名を必ず入れる
7. ハッシュタグ2〜3個、最後に改行して置く
8. 出力は投稿文のみ。説明・前置き・タイトル不要
9. 140字を超える場合はスレッド形式にする（投稿1 / 投稿2の形式）'

# コンテキスト構築
build_context() {
    local ctx=""
    if [ -n "$RESEARCH_BRIEF" ]; then
        ctx="${ctx}

【今日のリサーチデータ（これをベースに投稿を作る）】
${RESEARCH_BRIEF}"
    fi
    if [ -n "$INSIGHTS_CONTEXT" ]; then
        ctx="${ctx}

【過去の分析データ】
${INSIGHTS_CONTEXT}"
    fi
    echo "$ctx"
}

CONTEXT=$(build_context)

# 朝：最新トレンドを自分の体験風に語る
MORNING_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【テーマ】最新のAI・自動化ニュースを「自分が試した/発見した」体で語る
【ターゲット】副業やAI活用に興味がある30代〜40代
【文字数】80〜140字（内容が深いならスレッド2投稿可）
【構成】今日見つけた面白い技術/ニュース → 自分の視点・実感
【必須】リサーチデータから具体的なツール名か技術名を1つ以上登場させる

${CONTEXT}

【良い例】
GLM-5.1のエージェント機能、8時間自律でコード書き続けるらしい。試しにちょっとしたツール作らせたら普通に動いた。これ月5万のプログラマーより productive じゃないか。

#AI副業 #GLM"

# 昼：リサーチベースのノウハウ記事
NOON_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【テーマ】リサーチデータから「副業にどう使えるか」を実例付きで解説
【ターゲット】副業やAI活用に興味がある30代〜40代
【文字数】140〜280字（スレッド形式可、最大3投稿）
【構成】共感 → 具体的な手法 → 結果 or 問いかけ
【必須】リサーチデータの技術を「副業収入につながる使い方」として具体化

${CONTEXT}

【良い例】
Claude Code Coreが自律的にバグ修正できるようになった。これを副業に使うなら：
1. クラウドワークスで「バグ修正」案件を受注
2. AIにコード投げて修正案を生成させる
3. レビューして納品

これで月3〜5万は余裕で行ける。プログラミング経験なくても、要件を正確に伝える力さえあればいい。

#副業 #AI活用"

# 夜：問いかけ or インタビュー風
NIGHT_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

【テーマ】今日のリサーチから1つピックアップして、自分の実体験風に語る or 問いかけ
【ターゲット】副業やAI活用に興味がある30代〜40代
【文字数】60〜140字
【構成】今日の発見 → 自分なりの解釈 or 問いかけ

${CONTEXT}

【良い例】
OpenAIのCEOがステージ上でChatGPTに嘘つかれてた。笑笑
でもこれ、AI使って副業やってる人ほど深刻な話で。出力のファクトチェック、結局人間がやるしかないんだよな。

#AI #副業"

# フォールバック
fallback_morning() { cat << 'EOF'
AIのエージェント機能が進化しすぎてる。自律的にタスク分解して8時間ぶっ通しでコード書くやつ、普通にプログラマーの仕事奪い始めてる気がする。

#AI副業 #自動化
EOF
}
fallback_noon() { cat << 'EOF'
AIツールを副業に使うなら、まずはコスト0で始められるやつから：
1. Claude Codeでコード生成（無料枠あり）
2. Canva AIでサムネ・バナー作成
3. ChatGPTでライティング補助

どれも月0円で始められて、クラウドワークス案件にそのまま応募できる。

#副業 #AI活用
EOF
}
fallback_night() { cat << 'EOF'
最近AI関連のニュース追ってて思うけど、変化のスピードが速すぎて情報の取捨選択が一番のスキルになってる。「何を知らないか」より「何を無視するか」が大事。

#AI #フリーランス
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
