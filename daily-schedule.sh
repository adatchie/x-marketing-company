#!/bin/bash
# daily-schedule.sh: 1日のスケジュールに沿って段階的に実行
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/utils.sh"

mkdir -p "$LOG_DIR"

MODE="${1:-morning}"  # morning / noon / evening / all

case "$MODE" in
    morning)
        echo "【朝の業務】(7:00)"
        echo "impression-analyzer: 昨日の投稿を分析"
        bash "${SCRIPT_DIR}/employees/impression-analyzer/run.sh"
        echo ""
        echo "content-poster: 朝の投稿案を作成"
        bash "${SCRIPT_DIR}/employees/content-poster/run.sh"
        echo ""
        echo "account-selector: 今日の交流アカをリストアップ"
        bash "${SCRIPT_DIR}/employees/account-selector/run.sh"
        ;;
    noon)
        echo "【昼の業務】(12:00)"
        echo "like-worker: 昼のいいね回り"
        bash "${SCRIPT_DIR}/employees/like-worker/run.sh"
        echo ""
        echo "reply-worker: リプ案を作成"
        bash "${SCRIPT_DIR}/employees/reply-worker/run.sh"
        ;;
    evening)
        echo "【夜の業務】(18:00-21:00)"
        echo "quote-poster: 引用ポスト案を作成"
        bash "${SCRIPT_DIR}/employees/quote-poster/run.sh"
        echo ""
        echo "content-poster: 夜の投稿案を作成"
        bash "${SCRIPT_DIR}/employees/content-poster/run.sh"
        echo ""
        echo "line-builder: 配信シナリオを更新"
        bash "${SCRIPT_DIR}/employees/line-builder/run.sh"
        ;;
    all)
        bash "$0" morning
        echo ""
        bash "$0" noon
        echo ""
        bash "$0" evening
        ;;
    *)
        echo "使い方: ./daily-schedule.sh [morning|noon|evening|all]"
        exit 1
        ;;
esac
