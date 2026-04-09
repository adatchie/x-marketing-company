#!/bin/bash
# approve-action.sh: Process approve/revise/regenerate actions
set -e

source lib/utils.sh

DRAFT_ID="$1"
ACTION="$2"
FEEDBACK="$3"

# Git push with retry for concurrent workflow conflicts
git_add_and_push() {
    local msg="$1"
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add employees/logs/pending/
    git commit -m "$msg" || return 0
    for i in 1 2 3; do
        git stash --include-untracked 2>/dev/null || true
        git pull --rebase origin main 2>/dev/null || true
        git stash pop 2>/dev/null || true
        git push && return 0
        sleep 5
    done
    echo "Warning: git push failed after 3 retries"
}

PENDING_FILE="employees/logs/pending/${DRAFT_ID}.json"
if [ ! -f "$PENDING_FILE" ]; then
    echo "Error: Draft not found: $DRAFT_ID"
    notify_discord "Error" "Draft not found: ${DRAFT_ID}" 15158332
    exit 1
fi

TYPE=$(jq -r '.type' "$PENDING_FILE")
ORIGINAL=$(jq -r '.data | (.post_text // .reply_text // .quote_text // "N/A")' "$PENDING_FILE")

if [ "$ACTION" = "revise" ] && [ -n "$FEEDBACK" ]; then
    echo "=== REVISION MODE ==="

    REVISION_PROMPT="Revise this X post according to the feedback.

Original post:
${ORIGINAL}

Feedback:
${FEEDBACK}

Rules:
- Follow the feedback exactly
- Natural conversational Japanese
- No AI-sounding phrases
- Use casual da/dearu tone
- Include specific numbers/examples
- Thread format if over 140 chars
- 2-3 hashtags at the end
- Output only the post text"

    REVISED=$(llm_generate "$REVISION_PROMPT" "You are a social media expert writing natural Japanese posts.")

    if [ -z "$REVISED" ]; then
        notify_discord "Revision Failed" "LLM revision failed for: ${DRAFT_ID}" 15158332
        exit 1
    fi

    V2_DRAFT_ID="${DRAFT_ID}-v2"
    V2_FILE="employees/logs/pending/${V2_DRAFT_ID}.json"

    jq --arg revised "$REVISED" --arg fb "$FEEDBACK" --arg v2 "$V2_DRAFT_ID" '
        .id = $v2 |
        .status = "pending" |
        .feedback = $fb |
        .data.post_text = $revised |
        .data.reply_text = $revised |
        .data.quote_text = $revised
    ' "$PENDING_FILE" > "$V2_FILE"

    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {status: "revised", revised_at: $ts}' "$PENDING_FILE" > "${PENDING_FILE}.tmp"
    mv "${PENDING_FILE}.tmp" "$PENDING_FILE"

    notify_draft_item "${TYPE} (revised)" "$V2_DRAFT_ID" "${REVISED}"

    git_add_and_push "Revision: ${V2_DRAFT_ID}"

elif [ "$ACTION" = "regenerate" ]; then
    echo "=== REGENERATE MODE ==="

    RESEARCH_DATA=""
    RESEARCH_FILE="employees/logs/research-brief-$(date +%Y-%m-%d).md"
    if [ -f "$RESEARCH_FILE" ]; then
        RESEARCH_DATA=$(cat "$RESEARCH_FILE" | head -100)
    fi

    EXTRA_CTX=""
    if [ -n "$FEEDBACK" ]; then
        EXTRA_CTX="Extra instructions: ${FEEDBACK}"
    fi

    REGEN_PROMPT="Create a new X (Twitter) post from scratch.

Rules:
- Use ONLY the provided research data. Never fabricate information.
- Natural conversational Japanese. No AI-sounding phrases.
- Casual da/dearu tone. First person: boku or omit.
- Include specific tool names and numbers from research.
- Thread format if over 140 chars. 2-3 hashtags.
- Persona: 30s male doing 60-day 0-to-1 AI side hustle challenge.
  Trying note sales, X, Threads, YouTube, affiliate. No results yet.
  Never mention: Polymarket, crypto, gambling, specific earnings.
- Output only the post text.

Research data (use only this):
${RESEARCH_DATA}

${EXTRA_CTX}"

    REGENERATED=$(llm_generate "$REGEN_PROMPT" "You are a social media expert writing natural Japanese posts.")

    if [ -z "$REGENERATED" ]; then
        notify_discord "Regenerate Failed" "LLM regenerate failed for: ${DRAFT_ID}" 15158332
        exit 1
    fi

    REGEN_DRAFT_ID="${TYPE}-$(date +%Y%m%d%H%M%S)-regen"
    REGEN_FILE="employees/logs/pending/${REGEN_DRAFT_ID}.json"

    jq -n \
        --arg id "$REGEN_DRAFT_ID" \
        --arg type "$TYPE" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg pt "$REGENERATED" \
        --arg from "$DRAFT_ID" \
        '{id: $id, type: $type, status: "pending", created_at: $ts, regenerated_from: $from, data: {post_text: $pt, reply_text: $pt, quote_text: $pt}}' > "$REGEN_FILE"

    jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {status: "rejected", rejected_at: $ts}' "$PENDING_FILE" > "${PENDING_FILE}.tmp"
    mv "${PENDING_FILE}.tmp" "$PENDING_FILE"

    notify_draft_item "${TYPE} (regenerated)" "$REGEN_DRAFT_ID" "${REGENERATED}"

    git_add_and_push "Regenerate: ${REGEN_DRAFT_ID}"

elif [ "$ACTION" = "approve" ]; then
    echo "=== APPROVE MODE ==="

    approve_pending "$DRAFT_ID"
    notify_draft_item "${TYPE} (approved)" "$DRAFT_ID" "Posted: ${ORIGINAL:0:300}"

    git_add_and_push "Approved: ${DRAFT_ID}"

else
    echo "Unknown action: ${ACTION}"
    notify_discord "Error" "Unknown action: ${ACTION}" 15158332
    exit 1
fi
