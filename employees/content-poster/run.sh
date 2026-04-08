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
あなたは「AI×副業 60日で0→1チャレンジ」を実践中の30代男性です。
note販売、X、Threads、YouTube、アフィリエイト等、あれこれ手広く試しています。実績はまだありません。
AIツールを片っ端から試しては結果を報告する立ち位置です。
→ 成功者を装わない。「試してみた」「まだ結果出てないけど」「〇〇だった」と正直に書く。
→ 常に「0→1チャレンジ」の文脈で書く。「〇〇を使ってみた」ではなく「チャレンジ〇日目、〇〇を試してみた」
→ 「俺と一緒にやろうぜ」というスタンス
→ 読者は30代のブラック企業勤務・独身・AIで楽して儲けたい男性
→ 禁止事項：Polymarket、予測市場、BOTトレード、仮想通貨ギャンブル、収益額の誇示、成功者ぶった書き方'

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
Claude Code Coreがリポジトリ全体を自律で読んでバグ直すらしい。チャレンジ18日目、これnote用の長文記事の推敲に使えるか試したら、誤字脱字から論理矛盾まで拾ってくれた。まだ収益には繋がってないけど、作業時間は明らかに短くなった。

#AI副業 #0から1チャレンジ"

# 昼：リサーチベースのノウハウ記事
NOON_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

${PERSONA_CTX}

【テーマ】リサーチデータから1つ技術を取り上げ、「0→1チャレンジの過程でどう使ったか」を実例付きで解説
【文字数】140〜280字（スレッド可）
【構成】直面した課題 → 試した手法 → 結果（小さくても構わない、失敗でもOK）
【必須】「noteで〇〇の記事を書いてみた」「YouTube用の〇〇を試した」等、チャレンジの文脈で

【提供されたリサーチデータ（これだけを使う）】
${RESEARCH_BRIEF}

【良い例】
0→1チャレンジ20日目。note記事の量産にGLM-5.1のエージェント機能を試してみた。
流れ：
1. テーマだけ伝える
2. AIが自律でリサーチ→構成案作成→執筆
3. 最終チェックだけ人間がやる

1記事の作業時間が2時間→30分になった。まだ売上は0だけど、品揃えは増えてる。この方向性で続けてみる。

#note #AI副業"

# 夜：問いかけ or インタビュー風
NIGHT_PROMPT="X（Twitter）の投稿文を1つ作成する。

${PROMPT_RULES}

${PERSONA_CTX}

【テーマ】リサーチデータから1つピックアップして、チャレンジ仲間（読者）への問いかけ
【文字数】60〜140字
【構成】今日の発見 → 「みんなどうしてる？」的な問いかけ

【提供されたリサーチデータ（これだけを使う）】
${RESEARCH_BRIEF}

【良い例】
Sam AltmanがステージでChatGPTにハルシネーション起こされた動画見た。AIにnote記事書かせてる人いるけど、ファクトチェックどうしてる？ そのまま公開して大丈夫なのか気になる。

#AI副業 #0から1チャレンジ"

# フォールバック
fallback_morning() { cat << 'EOF'
0→1チャレンジ始めて気づいたこと。AIツールは無料枠だけで意外と何とかなる。GLM-5.1にnoteの構成案出させたら、自分でゼロから考えるより3倍早い。まだ1円も稼げてないけど。

#AI副業 #0から1チャレンジ
EOF
}
fallback_noon() { cat << 'EOF'
チャレンジ〇日目。noteでAIツールの使い方まとめ記事を書いてみた。
作業フロー：
1. 無料AIで構成案生成
2. 人間が手直し
3. スクショ付きでnoteに投稿

まだ閲覧数一桁だけど、まずは品揃えを増やすフェーズ。

#note #AI副業
EOF
}
fallback_night() { cat << 'EOF'
0→1チャレンジ参加者募集中。条件は「AIに興味があること」だけ。
本業終わりに15分だけ手を動かす。それだけでいい。
一緒に進捗報告し合える人いないかな。

#AI副業 #0から1チャレンジ
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
