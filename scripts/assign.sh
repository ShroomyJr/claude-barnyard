#!/usr/bin/env bash
set -euo pipefail

# Force UTF-8 I/O on Windows Python (emoji in animal names/emojis require it)
export PYTHONUTF8=1

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSIONS_DIR="$HOME/.claude/animal-notifier/sessions"
ANIMALS_FILE="$SKILL_DIR/animals.json"
SESSION_ID=""
ANIMAL_NAME=""
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --session-id)    SESSION_ID="$2";    shift 2 ;;
        --sessions-dir)  SESSIONS_DIR="$2";  shift 2 ;;
        --animals-file)  ANIMALS_FILE="$2";  shift 2 ;;
        --animal)        ANIMAL_NAME="$2";   shift 2 ;;
        --force)         FORCE=true;         shift   ;;
        *) shift ;;
    esac
done

if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(bash "$SKILL_DIR/scripts/get-session-id.sh")
fi

# Convert POSIX path to native OS path for Python.
# On Windows/Git Bash, cygpath -w converts /c/Users/... to C:\Users\...
# On macOS/Linux, cygpath doesn't exist so we fall back to the original path.
to_native() { cygpath -m "$1" 2>/dev/null || echo "$1"; }

SESSION_FILE="$SESSIONS_DIR/$SESSION_ID.json"

# Idempotent: return already-assigned animal (unless --force or --animal overrides)
if [[ -f "$SESSION_FILE" && "$FORCE" != "true" && -z "$ANIMAL_NAME" ]]; then
    python3 - "$(to_native "$SESSION_FILE")" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
print(d['emoji'] + ' ' + d['name'])
PYEOF
    exit 0
fi

mkdir -p "$SESSIONS_DIR"

# Pick an animal: specific name (--animal) or random from available pool
python3 - \
    "$(to_native "$ANIMALS_FILE")" \
    "$(to_native "$SESSIONS_DIR")" \
    "$(to_native "$SESSION_FILE")" \
    "$ANIMAL_NAME" <<'PYEOF'
import json, pathlib, sys

animals_file  = sys.argv[1]
sessions_dir  = pathlib.Path(sys.argv[2])
session_file  = pathlib.Path(sys.argv[3])
wanted        = sys.argv[4].strip().lower() if len(sys.argv) > 4 else ""

all_animals = json.loads(pathlib.Path(animals_file).read_text(encoding='utf-8'))["animals"]

if wanted:
    matches = [a for a in all_animals if a["name"].lower() == wanted]
    if not matches:
        print(f"ERROR: unknown animal '{sys.argv[4]}'", file=__import__('sys').stderr)
        raise SystemExit(1)
    chosen = matches[0]
else:
    taken = set()
    for p in sessions_dir.glob("*.json"):
        try:
            taken.add(json.loads(p.read_text(encoding='utf-8'))["name"])
        except Exception:
            pass
    available = [a for a in all_animals if a["name"] not in taken] or all_animals
    chosen = available[0]

session_file.write_text(json.dumps(chosen, ensure_ascii=False), encoding='utf-8')
print(chosen["emoji"] + " " + chosen["name"])
PYEOF
