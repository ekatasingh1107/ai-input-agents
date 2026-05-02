# AI Input Agents

macOS desktop notifications for AI coding agents. Never miss when Claude Code or Codex CLI needs your attention.

When you're running multiple AI sessions across terminal tabs, you can't babysit all of them. This repo gives you a native macOS dialog box with sound the moment any session needs input or finishes work, and a single click takes you to the right tab.

Both Claude Code and Codex CLI support lifecycle hooks natively. This repo provides the notification script and the exact hook configs for both.

![macOS dialog notification](https://img.shields.io/badge/macOS-only-blue) ![Shell](https://img.shields.io/badge/shell-bash-green)

---

## How it works

`notify.sh` is the notification engine. When triggered by a hook, it:

1. Plays a macOS system sound (configurable per event)
2. Shows a native dialog box with the message, session name, and working directory
3. Offers a "Go to Tab" button that activates the exact iTerm2 tab running that session

Both Claude Code and Codex CLI have built-in hook systems that call `notify.sh` automatically when events happen. No polling, no background processes.

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
chmod +x notify.sh
```

Note the **full absolute path** to this directory. You'll need it in the steps below.

```bash
# Print it
pwd
# Example output: /Users/yourname/ai-input-agents
```

---

## Step 2: Set up for Claude Code

Claude Code fires hooks on two events:
- **`Notification`** -- when it needs your input
- **`Stop`** -- when it finishes a task

### 2a. Open your settings file

```bash
# Create it if it doesn't exist
mkdir -p ~/.claude
touch ~/.claude/settings.json
```

Open `~/.claude/settings.json` in your editor.

### 2b. Add the hooks

If the file is empty, paste this entire block. If you already have settings, merge the `hooks` key into your existing JSON.

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

Replace **both** instances of `/FULL/PATH/TO/ai-input-agents` with the actual path from Step 1.

Example:
```
/Users/yourname/ai-input-agents/notify.sh 'Claude needs your input' Glass 'Claude Code'
```

### 2d. Test it

1. Open a new Claude Code session in iTerm2
2. Give it a task and let it run
3. When it finishes, you should see a macOS dialog: **"Task complete"** with the Hero sound
4. When it needs input, you should see: **"Claude needs your input"** with the Glass sound
5. Click "Go to Tab" to jump to that session's iTerm2 tab

No background processes needed. The hooks fire automatically inside Claude Code.

---

## Step 3: Set up for Codex CLI

Codex CLI fires hooks on these events:
- **`Stop`** -- when it finishes a task
- **`PermissionRequest`** -- when it needs your approval to run a command

### 3a. Create the hooks file

```bash
# Create it if it doesn't exist
touch ~/.codex/hooks.json
```

Open `~/.codex/hooks.json` in your editor.

### 3b. Add the hooks

Paste this into the file:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/FULL/PATH/TO/ai-input-agents/notify.sh 'Task complete' Hero 'Codex CLI'",
            "timeout": 10
          }
        ]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/FULL/PATH/TO/ai-input-agents/notify.sh 'Codex needs your approval' Glass 'Codex CLI'",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

### 3c. Replace the path

Replace **both** instances of `/FULL/PATH/TO/ai-input-agents` with the actual path from Step 1.

### 3d. Test it

1. Open a new Codex CLI session in iTerm2
2. Give it a task and let it run
3. When it finishes, you should see a macOS dialog: **"Task complete"** with the Hero sound
4. When it asks for permission to run a command, you should see: **"Codex needs your approval"** with the Glass sound
5. Click "Go to Tab" to jump to that session's iTerm2 tab

No background processes needed. The hooks fire automatically inside Codex CLI.

---

## Notification reference

| Agent | Event | Message | Sound |
|---|---|---|---|
| Claude Code | Needs input | "Claude needs your input" | Glass |
| Claude Code | Task complete | "Task complete" | Hero |
| Codex CLI | Needs approval | "Codex needs your approval" | Glass |
| Codex CLI | Task complete | "Task complete" | Hero |

**Available macOS sounds:** Glass, Hero, Basso, Funk, Ping, Pop, Purr, Sosumi, Submarine, Tink

Customize by changing the second argument to `notify.sh` in your hook config.

---

## Customization

### Use a different terminal (not iTerm2)

The "Go to Tab" button uses iTerm2's AppleScript API. If you use a different terminal, the dialog still pops up and the sound still plays, but the button won't switch tabs. To adapt it for your terminal, edit the AppleScript block at the bottom of `notify.sh`.

### Change the dialog timeout

Dialogs auto-dismiss after 15 seconds. Edit `giving up after 15` in `notify.sh` to change this.

### Add more hook events

Both Claude Code and Codex CLI support additional hook events beyond the ones configured above:

| Event | When it fires |
|---|---|
| `SessionStart` | A new session begins |
| `PreToolUse` | Before a tool is called |
| `PostToolUse` | After a tool completes |
| `UserPromptSubmit` | When you submit a prompt |

Add them to your hooks config in the same format to get notifications for those events too.

---

## Files

| File | What it does |
|---|---|
| `notify.sh` | Notification engine. macOS dialog + sound + iTerm2 tab jump |

---

## License

MIT
