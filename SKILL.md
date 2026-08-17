---
name: animal-session-notifier
description: >
  Assigns this Claude Code session a unique animal with a real audio notification.
  When Claude finishes generating a response, the animal's sound plays so you know
  which window is ready. Invoke once per session when running multiple Claude
  instances in parallel. Also handles animal selection when the user wants to
  pick a specific animal or change their current one.
---

# Animal Session Notifier

When invoked, either assign a random animal or let the user pick one from a table.

## Detecting intent

- If the user just ran `/animal-session-notifier` with no extra words → **auto-assign** (Steps 1–4)
- If the user said something like "pick", "choose", "select", "change", or "which animals" → **interactive selection** (Steps 5–7)
- If the user already has an animal and didn't ask to change → just remind them which one they have (re-run assign.sh, it is idempotent); still run the hook check (Step 1)

---

## Auto-assign (default)

### Step 1 — Ensure hooks are configured

Check whether both the Stop and Notification hooks point to `notify.sh`:

```bash
python3 - <<'PYEOF'
import json, pathlib, sys
s = pathlib.Path.home() / '.claude' / 'settings.json'
if not s.exists():
    print("MISSING_SETTINGS"); sys.exit(0)
cfg = json.loads(s.read_text(encoding='utf-8'))
notify_cmd = 'bash "$HOME/.claude/skills/animal-session-notifier/scripts/notify.sh"'
missing = []
for hook_type in ('Stop', 'Notification'):
    hooks = cfg.get('hooks', {}).get(hook_type, [])
    found = any(
        hh.get('command', '') == notify_cmd
        for h in hooks for hh in h.get('hooks', [])
    )
    if not found:
        missing.append(hook_type)
print(','.join(missing) if missing else 'OK')
PYEOF
```

- If output is `OK` → skip to Step 2.
- If output lists one or both hook types (e.g. `Stop,Notification` or just `Notification`), update `~/.claude/settings.json` using the Edit tool. For each missing hook type, add or replace its entry under `hooks` with:

```json
[
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

After editing, tell the user: "Configured Stop and Notification hooks — both will play your session's animal sound."

### Step 2 — Run assign

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/assign.sh
```

### Step 3 — Capture output

The script prints one line like `🐸 Frog`. That is the assigned animal for this session.

### Step 4 — Announce

> **This session is the 🐸 Frog session.**
>
> Whenever I finish generating a response, you'll hear a frog sound from this window.
> Open other Claude sessions and run `/animal-session-notifier` there too — each will make a different sound when ready for input.

---

## Interactive selection

### Step 5 — Show the animal table

Run the list script:

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/list-animals.sh
```

It returns a JSON array in alphabetical order. Render it as a markdown table with a 1-based ordinal column — the ordinal tells the user which window number each animal represents:

| # | | Animal | Status |
|---|---|---|---|
| 1 | 🐱 | Cat | **This session** |
| 2 | 🐮 | Cow | Available |
| 3 | 🐶 | Dog | Available |
| 4 | 🦆 | Duck | Other session |
| 5 | 🐸 | Frog | Available |
| 6 | 🐴 | Horse | Available |
| 7 | 🦁 | Lion | Available |
| 8 | 🐒 | Monkey | Available |
| 9 | 🦉 | Owl | Available |
| 10 | 🐷 | Pig | Available |
| 11 | 🐓 | Rooster | Available |
| 12 | 🐑 | Sheep | Available |

- `status: "this_session"` → **This session**
- `status: "other_session"` → Other session
- `status: "available"` → Available

### Step 6 — Ask the user

After rendering the table, ask:

> Which animal would you like for this session?

Wait for the user's reply before continuing.

### Step 7 — Assign the chosen animal

Once the user picks one, run assign with `--animal` and `--force` (force allows changing from a previous assignment):

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/assign.sh --animal "Dog" --force
```

Replace `Dog` with whatever the user chose (use the exact `name` value from the JSON, e.g. `Cat`, `Rooster`).

If the script prints `ERROR: unknown animal`, tell the user the name wasn't recognized and show the table again.

Then announce with the new animal:

> **This session is now the 🐶 Dog session.**
>
> You'll hear a dog bark from this window whenever I finish generating a response.

---

## Notes

- Animals marked "Other session" can still be chosen — `--force` allows it; both sessions will just play the same sound.
- If all 12 animals are claimed, every animal shows "Other session" — the user can still pick any of them.
- If the user reports no sound, re-run Step 1's hook check — it will detect and fix any missing hooks automatically.
