#!/bin/bash
# Desktop notification for AI coding agents (macOS)
# Shows a dialog box with sound when a session needs attention.
# Works with: Claude Code (via hooks), Codex CLI (via cloud-monitor.sh)
#
# Usage: notify.sh "message" [SoundName] [Title]
# Sounds: Glass (default), Hero, Basso, Funk, Ping, Pop, Purr, Sosumi, Submarine, Tink

MSG="$1"
SOUND="${2:-Glass}"
TITLE="${3:-AI Agent}"
CWD="$(pwd)"
DIR_NAME="$(basename "$CWD")"

# Walk up process tree to find the TTY (hook subprocesses don't have one directly)
TTY_PATH=""
PID=$$
while [ -n "$PID" ] && [ "$PID" -gt 1 ] 2>/dev/null; do
  TTY_RAW=$(ps -o tty= -p "$PID" 2>/dev/null | tr -d ' ')
  if [ -n "$TTY_RAW" ] && [ "$TTY_RAW" != "??" ]; then
    TTY_PATH="/dev/$TTY_RAW"
    break
  fi
  PID=$(ps -o ppid= -p "$PID" 2>/dev/null | tr -d ' ')
done

# Play sound in background
afplay "/System/Library/Sounds/${SOUND}.aiff" 2>/dev/null &

# Show dialog with session context
RESULT=$(osascript <<EOF
display dialog "$MSG\n\nSession: $DIR_NAME\nPath: $CWD" with title "$TITLE" buttons {"Go to Tab", "Dismiss"} default button "Go to Tab" giving up after 15 with icon caution
EOF
)

# If user clicked "Go to Tab", find and activate the right iTerm2 tab
if [[ "$RESULT" == *"Go to Tab"* ]] && [[ -n "$TTY_PATH" ]]; then
  osascript <<EOF
tell application "iTerm2"
  activate
  repeat with w in windows
    repeat with t in tabs of w
      repeat with s in sessions of t
        if tty of s is "$TTY_PATH" then
          select w
          select t
          select s
          return
        end if
      end repeat
    end repeat
  end repeat
end tell
EOF
fi
