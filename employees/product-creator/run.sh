#!/bin/bash
# product-creator: 販売商品・コンテンツを制作する
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

log "product-creator" "商品企画を開始します"

PRODUCT_DIR="${LOG_DIR}/products"
mkdir -p "$PRODUCT_DIR"

PRODUCT_FILE="${PRODUCT_DIR}/product-plan-$(date +%Y-%m).md"

# 既存企画があるか確認
if [ -f "$PRODUCT_FILE" ]; then
    EXISTING_COUNT=$(grep -c "^## 商品" "$PRODUCT_FILE" 2>/dev/null || echo "0")
    log "product-creator" "今月の既存企画: ${EXISTING_COUNT}件"
fi

# フォロワーの反応からニーズを分析（最近のメンションを確認）
log "product-creator" "フォロワーの反応を分析中..."
MENTIONS=$(xurl_exec mentions --max-results 20 2>/dev/null)
safe_delay 3

# 企画書テンプレート
cat >> "$PRODUCT_FILE" << PLAN

## 商品企画 $(date +%Y-%m-%d)

### 商品名案
1. 「AI副業スタートキット」
2. 「一人起業AI活用ガイド」
3. 「副業AIプロンプト集」

### タイプ
PDF教材 + テンプレート集

### ターゲット
副業を始めたいがAIの使い方が分からない30代〜40代の会社員

### 価格
- フロントエンド：無料（LINE登録特典）
- ミドル：2,980円
- バックエンド：14,800円（個別相談付き）

### 差別化ポイント
1. 「Claude Code」を使った具体的な手順を解説
2. 実際のX運用データに基づくノウハウ
3. すぐ使えるプロンプトテンプレート付き

### 売り文案
「AIを使って、毎日30分で副業を始める方法」
「プログラミング不要。AI社員に仕事を任せるだけ」

### 必要な制作物
- [ ] メインPDF（20〜30ページ）
- [ ] プロンプト集PDF
- [ ] 販売ページ（LP）
- [ ] LINE配信テキスト

---
PLAN

log "product-creator" "商品企画書を作成"
log "product-creator" "保存先: ${PRODUCT_FILE}"
