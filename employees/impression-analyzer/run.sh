#!/bin/bash
# impression-analyzer: 過去投稿のインプレッションを分析し学習データを生成
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "impression-analyzer" "インプレッション分析を開始します"

mkdir -p "$METRICS_DIR" "$INSIGHTS_DIR"

METRICS_FILE="${METRICS_DIR}/metrics-${TODAY}.json"
INSIGHTS_FILE="${INSIGHTS_DIR}/insights-${TODAY}.md"
LATEST_FILE="${INSIGHTS_DIR}/latest.md"

# 過去の投稿ログから投稿IDを収集
# content-log, quote-log に記録された投稿IDを探す
TWEET_IDS=()

# content-logのsend-post結果から投稿IDを取得
for log_file in "${LOG_DIR}"/daily-*.log; do
    [ -f "$log_file" ] || continue
    # "投稿成功: 投稿ID XXXXX" 形式を探す
    while read -r tid; do
        if [ -n "$tid" ]; then
            TWEET_IDS+=("$tid")
        fi
    done < <(grep '投稿成功: 投稿ID' "$log_file" 2>/dev/null | grep -o '[0-9]\{10,\}' | head -20)
done

# quote-posterの送信結果からも取得
for log_file in "${LOG_DIR}"/daily-*.log; do
    [ -f "$log_file" ] || continue
    while read -r tid; do
        if [ -n "$tid" ]; then
            TWEET_IDS+=("$tid")
        fi
    done < <(grep '引用ポスト投稿成功' "$log_file" 2>/dev/null | grep -o '[0-9]\{10,\}' | head -20)
done

# 重複排除
UNIQUE_IDS=($(echo "${TWEET_IDS[@]}" | tr ' ' '\n' | sort -u))

if [ ${#UNIQUE_IDS[@]} -eq 0 ]; then
    log "impression-analyzer" "分析対象の投稿IDが見つかりません"

    # 初回実行時はインサイトなしでファイル作成
    cat > "$INSIGHTS_FILE" << 'EOF'
# インサイト（初回）

## 現状
まだ投稿データがありません。投稿が蓄積されたら分析を開始します。

## 暫定ガイドライン
- 朝: ポジティブな気づき・名言
- 昼: ノウハウ・リスト型
- 夜: 問いかけ・振り返り
- ハッシュタグ: #副業 #AI活用 #一人起業 をローテーション
EOF
    cp "$INSIGHTS_FILE" "$LATEST_FILE"
    exit 0
fi

log "impression-analyzer" "${#UNIQUE_IDS[@]}件の投稿を分析します"

# メトリクス取得
echo '[' > "$METRICS_FILE"
FIRST=true

for tweet_id in "${UNIQUE_IDS[@]}"; do
    log "impression-analyzer" "投稿 ${tweet_id} のメトリクス取得中..."

    METRICS=$(xurl_exec tweet "$tweet_id" --fields "public_metrics,created_at,text" 2>/dev/null)
    safe_delay 2

    if [ -z "$METRICS" ]; then
        log "impression-analyzer" "投稿 ${tweet_id} の取得に失敗"
        continue
    fi

    # メトリクスをJSONに追加
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ',' >> "$METRICS_FILE"
    fi

    # 必要な項目を抽出して整形
    RETWEETS=$(echo "$METRICS" | jq '.data.public_metrics.retweet_count // 0')
    LIKES=$(echo "$METRICS" | jq '.data.public_metrics.like_count // 0')
    REPLIES=$(echo "$METRICS" | jq '.data.public_metrics.reply_count // 0')
    IMPRESSIONS=$(echo "$METRICS" | jq '.data.public_metrics.impression_count // 0')
    TEXT=$(echo "$METRICS" | jq -r '.data.text // ""')
    CREATED=$(echo "$METRICS" | jq -r '.data.created_at // ""')

    jq -n \
        --arg id "$tweet_id" \
        --arg text "$TEXT" \
        --arg created "$CREATED" \
        --argjson rt "$RETWEETS" \
        --argjson likes "$LIKES" \
        --argjson replies "$REPLIES" \
        --argjson impressions "$IMPRESSIONS" \
        '{
            id: $id,
            text: $text,
            created_at: $created,
            metrics: {
                retweets: $rt,
                likes: $likes,
                replies: $replies,
                impressions: $impressions,
                engagement_rate: (($likes + $rt) * 100 / ($impressions + 1))
            }
        }' >> "$METRICS_FILE"

    log "impression-analyzer" "${tweet_id}: ${LIKES}いいね ${IMPRESSIONS}imp"
done

echo ']' >> "$METRICS_FILE"

log "impression-analyzer" "メトリクス取得完了: ${METRICS_FILE}"

# LLMで分析
METRICS_SUMMARY=$(cat "$METRICS_FILE" | jq -r '.[] | "- 投稿「\(.text[0:50])...」→ いいね\(.metrics.likes)、RT\(.metrics.retweets)、インプレッション\(.metrics.impressions)、エンゲージメント率\(.metrics.engagement_rate | floor)%"' 2>/dev/null)

ANALYSIS_PROMPT="以下は過去のX（Twitter）投稿のパフォーマンスデータです：

${METRICS_SUMMARY}

これを分析して、以下のフォーマットで次回の投稿生成に活かすインサイトを出力してください：

## 傾向分析
### バズった投稿の特徴
（どのテーマ・文字数・構成が伸びたか）

### 伸びなかった投稿の特徴
（どのパターンが不調だったか）

## 次回の投稿への提案
### おすすめテーマ
### おすすめ文字数
### おすすめ構成
### 避けるべきパターン

出力はMarkdown形式で、簡潔にまとめてください。"

if [ -n "$LLM_API_KEY" ]; then
    log "impression-analyzer" "LLMでインサイト分析中..."
    INSIGHTS=$(llm_generate "$ANALYSIS_PROMPT" "あなたはSNSマーケティングのデータアナリストです。数値データから傾向を読み取り、具体的な改善提案をしてください。")

    if [ -n "$INSIGHTS" ]; then
        cat > "$INSIGHTS_FILE" << HEADER
# インサイト $(date +%Y-%m-%d)
## 対象投稿数: ${#UNIQUE_IDS[@]}件

${INSIGHTS}
HEADER
    else
        log "impression-analyzer" "LLM分析失敗、簡易インサイトを生成"
        generate_simple_insights
    fi
else
    generate_simple_insights
fi

cp "$INSIGHTS_FILE" "$LATEST_FILE"

# Discordに通知
notify_draft "impression-analyzer" "$INSIGHTS_FILE"

log "impression-analyzer" "分析完了"
log "impression-analyzer" "メトリクス: ${METRICS_FILE}"
log "impression-analyzer" "インサイト: ${INSIGHTS_FILE}"

# --- 補助関数 ---
generate_simple_insights() {
    # LLMなしの簡易分析
    local best_likes=0 best_text=""
    local total_likes=0 total_impressions=0 count=0

    while IFS= read -r line; do
        local likes=$(echo "$line" | jq -r '.metrics.likes' 2>/dev/null)
        local imp=$(echo "$line" | jq -r '.metrics.impressions' 2>/dev/null)
        local text=$(echo "$line" | jq -r '.text' 2>/dev/null)

        if [ -n "$likes" ]; then
            total_likes=$((total_likes + likes))
            total_impressions=$((total_impressions + imp))
            count=$((count + 1))

            if [ "$likes" -gt "$best_likes" ]; then
                best_likes=$likes
                best_text="$text"
            fi
        fi
    done < <(jq -c '.[]' "$METRICS_FILE" 2>/dev/null)

    local avg_likes=0
    if [ "$count" -gt 0 ]; then
        avg_likes=$((total_likes / count))
    fi

    cat > "$INSIGHTS_FILE" << EOF
# インサイト $(date +%Y-%m-%d)（簡易分析）

## 傾向分析
- 分析投稿数: ${count}件
- 平均いいね数: ${avg_likes}
- 合計インプレッション: ${total_impressions}
- ベスト投稿: 「${best_text:0:50}...」（${best_likes}いいね）

## 次回の投稿への提案
- ベスト投稿と同じテーマ・構成を試す
- エンゲージメント率を意識した投稿文
- ハッシュタグは #副業 #AI活用 を継続
EOF
}
