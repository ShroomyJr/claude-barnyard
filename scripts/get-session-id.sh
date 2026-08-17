#!/usr/bin/env bash
# Walk process tree upward looking for a claude ancestor PID.
# Output that PID as the stable session identifier.
# Fall back to 0 if not found (both assign and notify use the same fallback
# so they still agree on the animal even when traversal fails).

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
