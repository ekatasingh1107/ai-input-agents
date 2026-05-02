# AI Input Agents

macOS desktop notifications for AI coding agents. Get a dialog box with sound whenever Claude Code or Codex CLI needs your attention.

![macOS dialog notification](https://img.shields.io/badge/macOS-only-blue) ![Shell](https://img.shields.io/badge/shell-bash-green)

## What it does

When you're running multiple AI coding sessions across terminal tabs, these scripts notify you with:

- A **macOS dialog box** showing which session needs attention
- A **sound alert** (different sounds for different events)
- A **"Go to Tab" button** that jumps to the right iTerm2 tab

## Setup

### Prerequisites

- macOS
- [iTerm2](https://iterm2.com/) (for "Go to Tab" functionality; dialogs work with any terminal)
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and/or [Codex CLI](https://github.com/openai/codex)

### Install

```bash
git clone https://github.com/YOUR_USERNAME/ai-input-agents.git
cd ai-input-agents
chmod +x notify.sh codex-cloud-monitor.sh
```

### Claude Code

Add hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/ai-input-agents/notify.sh 'Claude needs your input' Glass 'Claude Code'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/ai-input-agents/notify.sh 'Task complete' Hero 'Claude Code'"
          }
        ]
      }
    ]
  }
}
```

Replace `/path/to/ai-input-agents` with the actual path where you cloned the repo.

### Codex CLI (Cloud Tasks)

Codex CLI doesn't have hooks, so `codex-cloud-monitor.sh` polls `codex cloud list` for status changes.

**Run manually:**

```bash
./codex-cloud-monitor.sh        # polls every 30s (default)
./codex-cloud-monitor.sh 15     # polls every 15s
```

**Run on login (recommended):**

Create `~/Library/LaunchAgents/com.codex.cloud-monitor.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.codex.cloud-monitor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/path/to/ai-input-agents/codex-cloud-monitor.sh</string>
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
```

Then load it:

```bash
launchctl load ~/Library/LaunchAgents/com.codex.cloud-monitor.plist
```

## Notification sounds

| Event | Sound | When |
|---|---|---|
| Needs input | Glass | Session is waiting for you |
| Task complete | Hero | Session finished its work |
| Task failed | Basso | Something went wrong |
| Task restarted | Glass | A completed task started running again |

Available macOS sounds: Glass, Hero, Basso, Funk, Ping, Pop, Purr, Sosumi, Submarine, Tink

## Files

| File | Purpose |
|---|---|
| `notify.sh` | Core notification script. Shows macOS dialog + plays sound + jumps to iTerm2 tab |
| `codex-cloud-monitor.sh` | Polls Codex Cloud tasks and triggers notify.sh on status changes |

## License

MIT
