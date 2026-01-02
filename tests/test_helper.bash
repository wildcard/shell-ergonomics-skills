#!/bin/bash

# Test session ID
export TEST_SESSION_ID="test-session-$(date +%s)"

# Create isolated temp directory
setup() {
    export TEST_TMP=$(mktemp -d)
    export ORIGINAL_HOME="$HOME"
    export HOME="$TEST_TMP"
    mkdir -p "$HOME/.claude/plans"
    mkdir -p "$HOME/.claude/hooks"
}

teardown() {
    rm -rf "$TEST_TMP"
    export HOME="$ORIGINAL_HOME"
}

# Mock starship command
mock_starship() {
    cat > "$TEST_TMP/starship" << 'EOF'
#!/bin/bash
echo "via 🦀 v1.74.0"
EOF
    chmod +x "$TEST_TMP/starship"
    export PATH="$TEST_TMP:$PATH"
}

# Mock claude CLI
mock_claude() {
    local response="${1:-{\"structured_output\":{\"task\":\"Test Task\"}}}"
    cat > "$TEST_TMP/claude" << EOF
#!/bin/bash
echo '$response'
EOF
    chmod +x "$TEST_TMP/claude"
    export PATH="$TEST_TMP:$PATH"
}

# Create sample history.jsonl
create_history() {
    local session_id="$1"
    local count="${2:-5}"
    mkdir -p "$HOME/.claude"
    for i in $(seq 1 $count); do
        echo "{\"sessionId\":\"$session_id\",\"display\":\"User message $i\"}" >> "$HOME/.claude/history.jsonl"
    done
}

# Create sample statusline input
create_statusline_input() {
    local session_id="${1:-$TEST_SESSION_ID}"
    local cwd="${2:-/Users/test/project}"
    cat << EOF
{
    "session_id": "$session_id",
    "workspace": {"current_dir": "$cwd"},
    "model": {"display_name": "Claude 3.5 Sonnet"},
    "context_window": {
        "current_usage": {
            "input_tokens": 50000,
            "output_tokens": 5000,
            "cache_creation_input_tokens": 0,
            "cache_read_input_tokens": 0
        },
        "context_window_size": 200000
    }
}
EOF
}

# Create sample hook input
create_hook_input() {
    local session_id="${1:-$TEST_SESSION_ID}"
    local hook_event="${2:-UserPromptSubmit}"
    local user_prompt="${3:-Create a new feature}"
    cat << EOF
{
    "session_id": "$session_id",
    "hook_event_name": "$hook_event",
    "user_prompt": "$user_prompt"
}
EOF
}

# Skip test if no API key
skip_if_no_api_key() {
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        skip "ANTHROPIC_API_KEY not set"
    fi
}
