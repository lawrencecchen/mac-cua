#!/bin/bash
# Takes a screenshot before/after every tool call and logs metadata
# Receives JSON on stdin from Claude Code hooks system

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "unknown"')
TOOL_USE_ID=$(echo "$INPUT" | jq -r '.tool_use_id // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')

SCREENSHOT_DIR="${CUA_SCREENSHOT_DIR:-/tmp/cua-screenshots}"
mkdir -p "$SCREENSHOT_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PHASE=$([ "$HOOK_EVENT" = "PreToolUse" ] && echo "pre" || echo "post")
FILENAME="${SCREENSHOT_DIR}/${TIMESTAMP}_${PHASE}_${TOOL_NAME}_${TOOL_USE_ID:0:12}.png"

# Take screenshot (macOS native, silent)
/usr/sbin/screencapture -x "$FILENAME" 2>/dev/null

# Log metadata
echo "$INPUT" | jq -c "{
  timestamp: \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
  phase: \"$PHASE\",
  tool: .tool_name,
  tool_use_id: .tool_use_id,
  tool_input: .tool_input,
  screenshot: \"$FILENAME\",
  transcript_path: .transcript_path
}" >> "${SCREENSHOT_DIR}/metadata.jsonl"

# Save transcript path for later use
if [ -n "$TRANSCRIPT_PATH" ] && [ "$TRANSCRIPT_PATH" != "null" ]; then
  echo "$TRANSCRIPT_PATH" > "${SCREENSHOT_DIR}/transcript_path.txt"
fi

exit 0
