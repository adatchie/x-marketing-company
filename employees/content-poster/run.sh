#!/bin/bash
# content-poster: ペルソナベース×リサーチ駆動の投稿生成
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
    log "content-poster" "リサーチブリーフなし"
fi

# 共通ルール
PROMPT_RULES='【絶対ルール】
1. 以下の提供されたリサーチデータのみを使うこと。リサーチデータにないツール名・モデル名・出来事は絶対に書かない。知識からの捏造は厳禁。
2. ペルソナ設定に従うこと。
3. 禁止表現：「〜の時代になりました」「〜ではないでしょうか」「皆さん」「ぜひ」「革新的な」「画期的な」「〜について考えてみましょう」「〜の重要性」
4. 口調は「だ・である」混じりのラフなSNS口調。一人称は「ぼく」または省略。
5. 具体的なツール名・技術名・数字を必ず入れる。
6. 「〇〇を使ってみた」という書き出しは禁止。まず「何をしているか（副業の文脈）」から入る。
7. 140字を超えるならスレッド形式に。
8. ハッシュタグ2〜3個を最後に。
9. 出力は投稿文のみ。前置き・説明・タイトル不要。'

# ペルソナコンテキスト
PERSONA_CTX='【ペルソナ設定】
あなたはnoteでノウハウを販売しつつ、X・Threads・YouTubeで収益化を目指して試行錯誤している30代男性です。
AIツールを活用してコンテンツ制作や発信を効率化しています。
立ち位置：「AI×発信で収益化を目指す実践者」
→ そのため、投稿は常に「発信活動やnote販売の文脈」で書くこと。
→ 「〇〇というAIツールがある」ではなく「note用の記事を〇〇使って書いてみたら〇〇だった」という書き方にする。
→ 禁止事項：Polymarket、予測市場、BOTトレード、仮想通貨ギャンブル、具体的な収益額の誇示'

# 朝：最新トレンドを実体験風に
MORNING_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

${PERSONA_CTX}

【テーマ】リサーチデータから最新のAIニュースを1つ選び、自分の発信活動やnote執筆に絡めて語る
【文字数】80〜140字
【構成】今日見つけたニュース → 自分の活動にどう影響するか / どう使ってみようと思ったか

【提供されたリサーチデータ（これだけを使う）】
${RESEARCH_BRIEF}

【良い例】
Claude Code Coreがリポジトリ全体を自律的に読んでバグ直すらしい。これnote用の長文記事の推敲に使えるかもと思って試したら、普通に誤字脱字から論理矛盾まで拾ってくれた。手動レビューの時間が3分の1になった。

#AI副業 #note"

# 昼：リサーチベースのノウハウ記事
NOON_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

${PERSONA_CTX}

【テーマ】リサーチデータから1つ技術を取り上げ、「発信・コンテンツ制作・note販売にどう使えるか」を実例付きで解説
【文字数】140〜280字（スレッド可）
【構成】悩み・課題 → 具体的な使い方 → 結果 or 感想
【必須】「noteで〇〇の記事を書いた」「YouTube用の台本作りに使った」等、発信活動に絡める

【提供されたリサーチデータ（これだけを使う）】
${RESEARCH_BRIEF}

【良い例】
noteの記事を量産するのに、GLM-5.1のエージェント機能を試してみた。
流れ：
1. テーマだけ伝える
2. AIが自律でリサーチ→構成案作成→執筆
3. 人間が最終チェックして公開

これで1記事あたりの作業時間が2時間→30分になった。品質も手書きと遜色ない。note販売の品揃えを増やすなら、この方式はアリ。

#note #AI副業"

# 夜：問いかけ or インタビュー風
NIGHT_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

${PERSONA_CTX}

【テーマ】リサーチデータから1つピックアップして、発信者としての視点で問いかけ or 気づき
【文字数】60〜140字
【構成】今日の発見 → 自分なりの解釈 or 読者への問いかけ

【提供されたリサーチデータ（これだけを使う）】
${RESEARCH_BRIEF}

【良い例】
Sam AltmanがステージでChatGPTにハルシネーション起こされたの見て、note記事のファクトチェックの重要性を再認識した。AIに書かせた記事、そのまま公開して大丈夫か？

#AI #note"

# フォールバック
fallback_morning() { cat << 'EOF'
Claude Code Coreがリポジトリ全体を自律的に読んでバグ直す機能をつけたらしい。noteの長文記事の推敲に使えないか試してみる。

#AI副業 #note
EOF
}
fallback_noon() { cat << 'EOF'
note記事の量産にAIエージェントを導入してみた。
テーマだけ伝えたら、リサーチ→構成→執筆まで全自動。
最後のチェックだけ人間がやる。これで1記事30分。
品揃え増やすなら悪くない手法。

#note #AI活用
EOF
}
fallback_night() { cat << 'EOF'
AIに記事書かせてる人、ファクトチェックどうしてる？
出力がそれっぽいだけで間違ってること、普通にあるよね。
結局、最後のひと押しは人間がやるしかない。

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
