#!/usr/bin/env bash
# Output JSON describing every animal's assignment status.
# Used by the skill to render the selection table for the user.
#
# Output schema (array, one entry per animal):
#   { name, emoji, sound_file, status, session_id }
#   status: "this_session" | "other_session" | "available"
#   session_id: present when status != "available"

set -euo pipefail
export PYTHONUTF8=1

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSIONS_DIR="$HOME/.claude/animal-notifier/sessions"
ANIMALS_FILE="$SKILL_DIR/animals.json"
SESSION_ID=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --session-id)   SESSION_ID="$2";   shift 2 ;;
        --sessions-dir) SESSIONS_DIR="$2"; shift 2 ;;
        --animals-file) ANIMALS_FILE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(bash "$SKILL_DIR/scripts/get-session-id.sh")
fi

to_native() { cygpath -m "$1" 2>/dev/null || echo "$1"; }

mkdir -p "$SESSIONS_DIR"

python3 - \
    "$(to_native "$ANIMALS_FILE")" \
    "$(to_native "$SESSIONS_DIR")" \
    "$SESSION_ID" <<'PYEOF'
import json, pathlib, sys

animals_file  = sys.argv[1]
sessions_dir  = pathlib.Path(sys.argv[2])
this_session  = sys.argv[3]

all_animals = json.loads(pathlib.Path(animals_file).read_text(encoding='utf-8'))["animals"]

# Build map: animal_name -> session_id
assignments = {}
for p in sessions_dir.glob("*.json"):
    try:
        sid  = p.stem
        data = json.loads(p.read_text(encoding='utf-8'))
        assignments[data["name"]] = sid
    except Exception:
        pass

result = []
for a in all_animals:
    sid = assignments.get(a["name"])
    if sid is None:
        status = "available"
    elif sid == this_session:
        status = "this_session"
    else:
        status = "other_session"
    entry = {**a, "status": status}
    if sid:
        entry["session_id"] = sid
    result.append(entry)

print(json.dumps(result, ensure_ascii=False))
PYEOF
