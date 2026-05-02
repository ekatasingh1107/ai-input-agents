#!/bin/bash
# Watch a live Codex CLI session transcript for idle periods (waiting for input).
# When no new lines appear for IDLE_THRESHOLD seconds, fires a notification.
#
# Usage: codex-session-watcher.sh [session_file] [idle_seconds]
#   session_file: path to the .jsonl transcript (auto-detects latest if omitted)
#   idle_seconds: seconds of inactivity before notifying (default: 10)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTIFY="${SCRIPT_DIR}/notify.sh"
IDLE_THRESHOLD="${2:-10}"
NOTIFIED=0

if [[ -n "$1" ]]; then
  SESSION_FILE="$1"
else
  SESSION_FILE=$(find "$HOME/.codex/sessions" -name "*.jsonl" -type f -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
fi

if [[ -z "$SESSION_FILE" ]] || [[ ! -f "$SESSION_FILE" ]]; then
  echo "Error: No session file found."
  exit 1
fi

echo "Watching: $SESSION_FILE"
echo "Idle threshold: ${IDLE_THRESHOLD}s"

LAST_LINE_COUNT=$(wc -l < "$SESSION_FILE" | tr -d ' ')
LAST_ACTIVITY=$(date +%s)

while true; do
  CURRENT_COUNT=$(wc -l < "$SESSION_FILE" | tr -d ' ')
  NOW=$(date +%s)

  if [[ "$CURRENT_COUNT" -gt "$LAST_LINE_COUNT" ]]; then
    LAST_LINE_COUNT="$CURRENT_COUNT"
    LAST_ACTIVITY="$NOW"
    NOTIFIED=0
  fi

  IDLE_TIME=$((NOW - LAST_ACTIVITY))

  if [[ "$IDLE_TIME" -ge "$IDLE_THRESHOLD" ]] && [[ "$NOTIFIED" -eq 0 ]]; then
    "$NOTIFY" "Codex is waiting for input" "Glass" "Codex CLI" &
    NOTIFIED=1
  fi

  sleep 2
done
