# AI Input Agents

macOS desktop notifications for AI coding agents. Never miss when Claude Code or Codex CLI needs your attention.

When you're running multiple AI sessions across terminal tabs, you can't babysit all of them. These two scripts solve that: you get a native macOS dialog box with sound the moment any session needs input or finishes work, and a single click takes you to the right tab.

![macOS dialog notification](https://img.shields.io/badge/macOS-only-blue) ![Shell](https://img.shields.io/badge/shell-bash-green)

---

## How it works

**`notify.sh`** is the core notification engine. It:

1. Plays a macOS system sound (configurable)
2. Shows a native dialog box with the message, session name, and working directory
3. Offers a "Go to Tab" button that activates the exact iTerm2 tab running that session

**`codex-cloud-monitor.sh`** is a background poller for Codex Cloud tasks. It runs `codex cloud list` on a loop, detects status changes, and calls `notify.sh` when something happens.

For **Claude Code**, no poller is needed. Claude Code has built-in hooks that trigger shell commands on events like "needs input" and "task complete."

---

## Prerequisites

- macOS (uses `osascript` and `afplay`)
- [iTerm2](https://iterm2.com/) for the "Go to Tab" feature (the dialog itself works with any terminal)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or [Codex CLI](https://github.com/openai/codex) installed

---

## Step 1: Clone and make executable

```bash
git clone https://github.com/ekatasingh1107/ai-input-agents.git
cd ai-input-agents
chmod +x notify.sh codex-cloud-monitor.sh
```

Note the full path to this directory, you'll need it below. For example: `/Users/yourname/ai-input-agents`

---

## Step 2: Set up for Claude Code

Claude Code fires shell hooks on two events: `Notification` (when it needs your input) and `Stop` (when it finishes). You wire `notify.sh` into both.

### 2a. Open your Claude Code settings file

```bash
# Create the file if it doesn't exist
touch ~/.claude/settings.json

# Open it
nano ~/.claude/settings.json
# or: code ~/.claude/settings.json
# or: vim ~/.claude/settings.json
```

### 2b. Add the hooks

Paste this into the file. If you already have other settings, merge the `hooks` key into your existing JSON.

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/FULL/PATH/TO/ai-input-agents/notify.sh 'Claude needs your input' Glass 'Claude Code'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/FULL/PATH/TO/ai-input-agents/notify.sh 'Task complete' Hero 'Claude Code'"
          }
        ]
      }
    ]
  }
}
```

### 2c. Replace the path

Replace `/FULL/PATH/TO/ai-input-agents` with the actual path where you cloned the repo. For example:

```
/Users/yourname/ai-input-agents/notify.sh
```

### 2d. Test it

Start a Claude Code session. When it stops or asks for input, you should see a dialog box pop up with the Glass or Hero sound.

That's it for Claude Code. No background processes, no polling. The hooks fire automatically.

---

## Step 3: Set up for Codex CLI (Cloud Tasks)

Codex CLI doesn't have hooks, so `codex-cloud-monitor.sh` polls for changes in the background.

### 3a. Test it manually first

```bash
cd ai-input-agents
./codex-cloud-monitor.sh 10
```

This starts polling every 10 seconds. Open another terminal and submit a Codex Cloud task:

```bash
codex cloud exec "List all files in this repo"
```

When the task finishes, you should see a dialog box pop up.

Press `Ctrl+C` to stop the manual test.

### 3b. Seed existing tasks (optional but recommended)

If you already have Codex Cloud tasks, seed the state file so you don't get a flood of notifications for old tasks:

```bash
STATE_FILE="$HOME/.codex/cloud-monitor-state"
mkdir -p "$(dirname "$STATE_FILE")"

codex cloud list 2>&1 | while IFS= read -r line; do
  if [[ "$line" == *"codex/tasks/task_"* ]]; then
    TASK_ID=$(echo "$line" | grep -o 'task_b_[a-f0-9]*')
  elif [[ -n "$TASK_ID" ]] && echo "$line" | grep -q '^ *\['; then
    STATUS=$(echo "$line" | grep -o '\[[A-Z_]*\]' | tr -d '[]')
    [[ -n "$STATUS" ]] && echo "${TASK_ID}=${STATUS}"
    TASK_ID=""
  fi
done > "$STATE_FILE"

echo "Seeded $(wc -l < "$STATE_FILE" | tr -d ' ') tasks"
```

### 3c. Run on login with launchd

Create the launchd plist:

```bash
cat > ~/Library/LaunchAgents/com.codex.cloud-monitor.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.codex.cloud-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/FULL/PATH/TO/ai-input-agents/codex-cloud-monitor.sh</string>
        <string>30</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/codex-cloud-monitor.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/codex-cloud-monitor.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
```

**Replace `/FULL/PATH/TO/ai-input-agents` with your actual path** in the file, then load it:

```bash
# Edit the path first
nano ~/Library/LaunchAgents/com.codex.cloud-monitor.plist

# Load it (starts immediately and on every login)
launchctl load ~/Library/LaunchAgents/com.codex.cloud-monitor.plist
```

### 3d. Verify it's running

```bash
# Check the process
launchctl list | grep codex

# Check the log
tail -f /tmp/codex-cloud-monitor.log
```

You should see: `Codex Cloud Monitor started (polling every 30s)`

---

## Notification reference

| Event | Sound | Dialog title |
|---|---|---|
| Claude needs input | Glass | Claude Code |
| Claude task complete | Hero | Claude Code |
| Codex task complete | Hero | Codex Cloud |
| Codex task failed | Basso | Codex Cloud |
| Codex needs input | Glass | Codex Cloud |
| Codex task restarted | Glass | Codex Cloud |

**Available macOS sounds:** Glass, Hero, Basso, Funk, Ping, Pop, Purr, Sosumi, Submarine, Tink

You can customize sounds by changing the second argument to `notify.sh`.

---

## Managing the Codex monitor

```bash
# Stop the monitor
launchctl unload ~/Library/LaunchAgents/com.codex.cloud-monitor.plist

# Restart the monitor
launchctl unload ~/Library/LaunchAgents/com.codex.cloud-monitor.plist
launchctl load ~/Library/LaunchAgents/com.codex.cloud-monitor.plist

# Change poll interval (edit the plist, change the "30" argument, then restart)

# View logs
tail -f /tmp/codex-cloud-monitor.log

# Reset state (will re-notify for all current tasks)
rm ~/.codex/cloud-monitor-state
```

---

## Customization

### Use a different terminal (not iTerm2)

The "Go to Tab" button uses iTerm2's AppleScript API. If you use a different terminal, the dialog still works, but the button won't switch tabs. To adapt it for your terminal, edit the AppleScript block at the bottom of `notify.sh`.

### Change the dialog timeout

Dialogs auto-dismiss after 15 seconds. Change `giving up after 15` in `notify.sh` to adjust.

### Change the poll interval

Pass the interval in seconds as the first argument to `codex-cloud-monitor.sh`, or edit the `30` in the launchd plist.

---

## Files

| File | What it does |
|---|---|
| `notify.sh` | Core notification engine. macOS dialog + sound + iTerm2 tab switch |
| `codex-cloud-monitor.sh` | Background poller for Codex Cloud tasks. Triggers notify.sh on status changes |

---

## License

MIT
