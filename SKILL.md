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

- If the user just ran `/animal-session-notifier` with no extra words → **auto-assign** (Steps 1–3)
- If the user said something like "pick", "choose", "select", "change", or "which animals" → **interactive selection** (Steps 4–6)
- If the user already has an animal and didn't ask to change → just remind them which one they have (re-run assign.sh, it is idempotent)

---

## Auto-assign (default)

### Step 1 — Run assign

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/assign.sh
```

### Step 2 — Capture output

The script prints one line like `🐸 Frog`. That is the assigned animal for this session.

### Step 3 — Announce

> **This session is the 🐸 Frog session.**
>
> Whenever I finish generating a response, you'll hear a frog sound from this window.
> Open other Claude sessions and run `/animal-session-notifier` there too — each will make a different sound when ready for input.

---

## Interactive selection

### Step 4 — Show the animal table

Run the list script:

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/list-animals.sh
```

It returns a JSON array. Render it as a markdown table like this example:

| | Animal | Status |
|---|---|---|
| 🐱 | Cat | **This session** |
| 🐶 | Dog | Available |
| 🐮 | Cow | Available |
| 🦆 | Duck | Other session |
| 🐸 | Frog | Available |
| 🐴 | Horse | Available |
| 🐷 | Pig | Available |
| 🐑 | Sheep | Available |
| 🦉 | Owl | Available |
| 🦁 | Lion | Available |
| 🐒 | Monkey | Available |
| 🐓 | Rooster | Available |

- `status: "this_session"` → **This session**
- `status: "other_session"` → Other session
- `status: "available"` → Available

### Step 5 — Ask the user

After rendering the table, ask:

> Which animal would you like for this session?

Wait for the user's reply before continuing.

### Step 6 — Assign the chosen animal

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
- If the user reports no sound, verify the Stop hook in `~/.claude/settings.json` points to `notify.sh`:
  ```json
  "command": "bash \"$HOME/.claude/skills/animal-session-notifier/scripts/notify.sh\""
  ```
