#!/usr/bin/env bash
set -euo pipefail

export PYTHONUTF8=1

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SESSIONS_DIR="$HOME/.claude/animal-notifier/sessions"
SESSION_ID=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --session-id)   SESSION_ID="$2";   shift 2 ;;
        --sessions-dir) SESSIONS_DIR="$2"; shift 2 ;;
        --dry-run)      DRY_RUN=true;      shift   ;;
        *) shift ;;
    esac
done

if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(bash "$SKILL_DIR/scripts/get-session-id.sh")
fi

to_native() { cygpath -m "$1" 2>/dev/null || echo "$1"; }

SESSION_FILE="$SESSIONS_DIR/$SESSION_ID.json"
[[ -f "$SESSION_FILE" ]] || exit 0   # No animal assigned — silent exit

SOUND_FILE=$(python3 - "$(to_native "$SESSION_FILE")" "$(to_native "$SKILL_DIR/sounds")" <<'PYEOF'
import json, sys, pathlib
d = json.load(open(sys.argv[1], encoding='utf-8'))
sounds_dir = pathlib.Path(sys.argv[2])
print(str(sounds_dir / d['sound_file']))
PYEOF
)

if [[ "$DRY_RUN" == "true" ]]; then
    echo "$SOUND_FILE"
    exit 0
fi

[[ -f "$SOUND_FILE" ]] || exit 0   # Missing WAV — silent exit

play_sound() {
    local file="$1"
    case "$(uname -s)" in
        Darwin)
            afplay "$file" &
            ;;
        Linux)
            if command -v aplay &>/dev/null; then
                aplay -q "$file" &
            elif command -v paplay &>/dev/null; then
                paplay "$file" &
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            local win_path
            win_path=$(cygpath -w "$file" 2>/dev/null || echo "$file")
            powershell.exe -c "(New-Object Media.SoundPlayer '$win_path').PlaySync()" &
            ;;
    esac
}

play_sound "$SOUND_FILE"
