#!/usr/bin/env bats

SCRIPTS_DIR="$(dirname "$BATS_TEST_FILENAME")/../scripts"

# ---------------------------------------------------------------------------
# get-session-id.sh
# ---------------------------------------------------------------------------

@test "get-session-id: returns a non-negative integer" {
    run bash "$SCRIPTS_DIR/get-session-id.sh"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+$ ]]
    [ "$output" -ge 0 ]
}

@test "get-session-id: same call twice returns same value" {
    first=$(bash "$SCRIPTS_DIR/get-session-id.sh")
    second=$(bash "$SCRIPTS_DIR/get-session-id.sh")
    [ "$first" = "$second" ]
}

# ---------------------------------------------------------------------------
# assign.sh
# ---------------------------------------------------------------------------

ANIMALS_FILE="$(dirname "$BATS_TEST_FILENAME")/../animals.json"

@test "assign: outputs '<emoji> <Name>' format" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    run bash "$SCRIPTS_DIR/assign.sh" \
        --session-id 1 \
        --sessions-dir "$tmp_sessions" \
        --animals-file "$ANIMALS_FILE"
    rm -rf "$tmp_sessions"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^.+[[:space:]][A-Z][a-z]+ ]]
}

@test "assign: creates a JSON session file" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    bash "$SCRIPTS_DIR/assign.sh" \
        --session-id 42 \
        --sessions-dir "$tmp_sessions" \
        --animals-file "$ANIMALS_FILE" >/dev/null
    local native_file
    native_file=$(cygpath -m "$tmp_sessions/42.json" 2>/dev/null || echo "$tmp_sessions/42.json")
    local result
    result=$(python3 -c "import json; json.load(open('$native_file', encoding='utf-8')); print('ok')" 2>&1)
    rm -rf "$tmp_sessions"
    [ "$result" = "ok" ]
}

@test "assign: is idempotent -- same result on second call" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    local first second
    first=$(bash "$SCRIPTS_DIR/assign.sh" --session-id 7 --sessions-dir "$tmp_sessions" --animals-file "$ANIMALS_FILE")
    second=$(bash "$SCRIPTS_DIR/assign.sh" --session-id 7 --sessions-dir "$tmp_sessions" --animals-file "$ANIMALS_FILE")
    rm -rf "$tmp_sessions"
    [ "$first" = "$second" ]
}

@test "assign: two different sessions get different animals" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    local a b
    a=$(bash "$SCRIPTS_DIR/assign.sh" --session-id 100 --sessions-dir "$tmp_sessions" --animals-file "$ANIMALS_FILE")
    b=$(bash "$SCRIPTS_DIR/assign.sh" --session-id 200 --sessions-dir "$tmp_sessions" --animals-file "$ANIMALS_FILE")
    rm -rf "$tmp_sessions"
    [ "$a" != "$b" ]
}

@test "assign: cycles animal list when all 12 slots are taken" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    python3 - "$ANIMALS_FILE" "$tmp_sessions" <<'PYEOF'
import json, pathlib, sys
animals = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding='utf-8'))["animals"]
sessions = pathlib.Path(sys.argv[2])
for i, a in enumerate(animals, start=1):
    (sessions / f"{i}.json").write_text(json.dumps(a), encoding='utf-8')
PYEOF
    run bash "$SCRIPTS_DIR/assign.sh" \
        --session-id 999 \
        --sessions-dir "$tmp_sessions" \
        --animals-file "$ANIMALS_FILE"
    rm -rf "$tmp_sessions"
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^.+[[:space:]][A-Z] ]]
}

# ---------------------------------------------------------------------------
# notify.sh
# ---------------------------------------------------------------------------

@test "notify: exits 0 silently when no session file exists" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    run bash "$SCRIPTS_DIR/notify.sh" \
        --session-id 9999 \
        --sessions-dir "$tmp_sessions" \
        --dry-run
    rm -rf "$tmp_sessions"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "notify: prints WAV path in dry-run mode" {
    local tmp_sessions
    tmp_sessions=$(mktemp -d)
    echo '{"name":"Frog","emoji":"🐸","sound_file":"frog.wav"}' \
        > "$tmp_sessions/55.json"
    run bash "$SCRIPTS_DIR/notify.sh" \
        --session-id 55 \
        --sessions-dir "$tmp_sessions" \
        --dry-run
    rm -rf "$tmp_sessions"
    [ "$status" -eq 0 ]
    [[ "$output" == *"frog.wav"* ]]
}
