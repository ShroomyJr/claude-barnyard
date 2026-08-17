#!/usr/bin/env bash
# Return a stable session ID for the current Claude Code session.
# Prefers CLAUDE_CODE_SESSION_ID (set by Claude Code in all child processes).
# Falls back to process-tree walk (macOS/Linux) then sentinel 0.

# Fast path: Claude Code always exports this env var into hook subprocesses
if [[ -n "${CLAUDE_CODE_SESSION_ID:-}" ]]; then
    echo "$CLAUDE_CODE_SESSION_ID"
    exit 0
fi

# Fallback: walk process tree looking for a claude ancestor PID
get_parent_pid() {
    local pid="$1"
    ps -p "$pid" -o ppid= 2>/dev/null | tr -d ' '
}

get_process_name() {
    local pid="$1"
    ps -p "$pid" -o comm= 2>/dev/null | tr -d ' '
}

current=$$
for _ in 1 2 3 4 5 6 7 8; do
    parent=$(get_parent_pid "$current")
    [[ -z "$parent" || "$parent" -le 1 ]] && break

    name=$(get_process_name "$parent")
    if echo "$name" | grep -qi "claude"; then
        echo "$parent"
        exit 0
    fi
    current="$parent"
done

echo "0"
