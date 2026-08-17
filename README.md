# animal-session-notifier

> **Invocation:** `/animal-session-notifier`

Assigns this Claude Code session a unique animal. When Claude finishes generating, the animal's real sound plays so you know which window is ready for input — no more switching windows to check.

## When to use

Run this at the start of each Claude session when you have two or more sessions open in parallel for long-running tasks.

## What it does

1. Walks the process tree to identify this Claude instance's PID
2. Picks an unassigned animal from the 12-animal catalog
3. Saves the assignment to `~/.claude/animal-notifier/sessions/<pid>.json`
4. The Stop hook in `settings.json` plays `sounds/<animal>.wav` via the platform's built-in audio player after every Claude response

## Animals

🐱 Cat · 🐶 Dog · 🐮 Cow · 🦆 Duck · 🐸 Frog · 🐴 Horse ·
🐷 Pig · 🐑 Sheep · 🦉 Owl · 🦁 Lion · 🐒 Monkey · 🐓 Rooster

## Platform requirements

| Platform | Audio player | Pre-installed? |
|----------|-------------|----------------|
| macOS | `afplay` | Yes |
| Linux | `aplay` (ALSA) or `paplay` (PulseAudio) | Usually yes |
| Windows (Git Bash) | `powershell.exe SoundPlayer` | Yes |

Python 3 is required for JSON parsing — available on all three platforms.

## Setup: Stop hook

Add this to `~/.claude/settings.json` under `hooks.Stop` to enable audio notifications:

```json
"Stop": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash \"$HOME/.claude/skills/animal-session-notifier/scripts/notify.sh\""
      }
    ]
  }
]
```

## Session files

Assignments live in `~/.claude/animal-notifier/sessions/`. They accumulate over time and do not self-clean. Delete stale `.json` files manually if you run out of unique animals.

## Troubleshooting

**No sound plays after a response:**
```bash
bash ~/.claude/skills/animal-session-notifier/scripts/notify.sh --dry-run
```
If empty: no session assigned yet — run `/animal-session-notifier` first.
If it prints a path: the hook isn't firing — check `settings.json`.

**Both sessions play the same sound:**
Process tree traversal fell back to sentinel `0`. Check the Claude process name:
```bash
ps aux | grep -i claude
```
If it differs from `claude`, update the `grep -qi "claude"` regex in `scripts/get-session-id.sh`.

**Linux: no audio:**
```bash
sudo apt-get install alsa-utils   # Debian/Ubuntu
sudo dnf install alsa-utils       # Fedora
```
