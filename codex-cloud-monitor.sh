#!/bin/bash
# Codex Cloud task monitor
# Polls `codex cloud list` for status changes and sends desktop notifications.
# Pairs with notify.sh for the actual notification dialog.
#
# Usage: codex-cloud-monitor.sh [poll_interval_seconds]
# Default poll interval: 30 seconds

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POLL_INTERVAL="${1:-30}"
STATE_FILE="$HOME/.codex/cloud-monitor-state"
NOTIFY="${SCRIPT_DIR}/notify.sh"

if [[ ! -x "$NOTIFY" ]]; then
  echo "Error: notify.sh not found at ${NOTIFY}"
  echo "Make sure notify.sh is in the same directory as this script."
  exit 1
fi

mkdir -p "$(dirname "$STATE_FILE")"
touch "$STATE_FILE"

echo "Codex Cloud Monitor started (polling every ${POLL_INTERVAL}s)"

while true; do
  RAW=$(codex cloud list 2>&1)

  TASK_ID=""
  while IFS= read -r line; do
    if [[ "$line" == *"codex/tasks/task_"* ]]; then
      TASK_ID=$(echo "$line" | grep -o 'task_b_[a-f0-9]*')
      continue
    fi

    if [[ -n "$TASK_ID" ]] && echo "$line" | grep -q '^ *\['; then
      STATUS=$(echo "$line" | grep -o '\[[A-Z_]*\]' | tr -d '[]')
      DESC=$(echo "$line" | sed 's/^ *\[[A-Z_]*\] *//')

      if [[ -n "$STATUS" ]]; then
        PREV=$(grep "^${TASK_ID}=" "$STATE_FILE" 2>/dev/null | cut -d= -f2)

        if [[ "$PREV" != "$STATUS" ]]; then
          if [[ "$STATUS" == "READY" ]]; then
            "$NOTIFY" "Task complete: ${DESC}" "Hero" "Codex Cloud" &
          elif [[ "$STATUS" == "ERROR" ]]; then
            "$NOTIFY" "Task failed: ${DESC}" "Basso" "Codex Cloud" &
          elif [[ "$STATUS" == "WAITING_FOR_INPUT" ]] || [[ "$STATUS" == "NEEDS_INPUT" ]]; then
            "$NOTIFY" "Needs your input: ${DESC}" "Glass" "Codex Cloud" &
          elif [[ "$PREV" == "READY" ]] || [[ "$PREV" == "ERROR" ]]; then
            "$NOTIFY" "Task restarted: ${DESC}" "Glass" "Codex Cloud" &
          fi

          if grep -q "^${TASK_ID}=" "$STATE_FILE" 2>/dev/null; then
            sed -i '' "s/^${TASK_ID}=.*/${TASK_ID}=${STATUS}/" "$STATE_FILE"
          else
            echo "${TASK_ID}=${STATUS}" >> "$STATE_FILE"
          fi
        fi
      fi
      TASK_ID=""
    fi
  done <<< "$RAW"

  sleep "$POLL_INTERVAL"
done
