---
name: animal-session-notifier
description: >
  Assigns this Claude Code session a unique animal with a real audio notification.
  When Claude finishes generating a response, the animal's sound plays so you know
  which window is ready. Invoke once per session when running multiple Claude
  instances in parallel.
---

# Animal Session Notifier

When invoked, assign a unique animal to this Claude Code session and announce it.

## Steps

1. Run the assign script using the Bash tool:

```bash
bash ~/.claude/skills/animal-session-notifier/scripts/assign.sh
```

2. The script prints one line like `🐸 Frog`. Capture the emoji and animal name.

3. Look up the animal's `sound_file` in `~/.claude/skills/animal-session-notifier/animals.json` to get the filename (e.g. `frog.wav`).

4. Announce to the user using this exact format (substituting real values):

> **This session is the 🐸 Frog session.**
>
> Whenever I finish generating a response, you'll hear a frog sound from this window.
> Open other Claude sessions and run `/animal-session-notifier` there too — each will make a different sound when ready for input.

## Notes

- Re-invoking this skill in the same session returns the already-assigned animal — no re-assignment happens.
- If all 12 animals are already claimed across simultaneous sessions, the next session gets a duplicate (unlikely with typical ≤4 concurrent sessions).
- If the user reports no sound, verify the Stop hook in `~/.claude/settings.json` points to `notify.sh`:
  ```json
  "command": "bash \"$HOME/.claude/skills/animal-session-notifier/scripts/notify.sh\""
  ```
