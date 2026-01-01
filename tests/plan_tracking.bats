#!/usr/bin/env bats

load test_helper

@test "exits silently when session_id is empty" {
    input='{"hook_event_name":"SessionStart","session_id":""}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "detects SessionStart hook event" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    mkdir -p "$HOME/.claude/plans"
    touch "$HOME/.claude/plans/test-plan.md"

    input=$(cat << EOF
{
    "hook_event_name":"SessionStart",
    "session_id":"$session_id"
}
EOF
)

    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "detects UserPromptSubmit hook event" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    mkdir -p "$HOME/.claude/plans"
    touch "$HOME/.claude/plans/test-plan.md"

    input=$(cat << EOF
{
    "hook_event_name":"UserPromptSubmit",
    "session_id":"$session_id"
}
EOF
)

    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "ignores PostToolUse hook event" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    input='{"hook_event_name":"PostToolUse","session_id":"test-123"}'

    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    [ "$status" -eq 0 ]
    # Should not create any plan cache
    [ ! -f "/tmp/claude-session-plan-test-123.txt" ]
}

@test "finds plan modified within 10 minutes" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    mkdir -p "$HOME/.claude/plans"

    # Create a recent plan file
    echo "# Test Plan" > "$HOME/.claude/plans/recent-plan.md"
    touch "$HOME/.claude/plans/recent-plan.md"

    input=$(cat << EOF
{
    "hook_event_name":"SessionStart",
    "session_id":"$session_id"
}
EOF
)

    bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    # Should create session-plan cache
    [ -f "/tmp/claude-session-plan-${session_id}.txt" ]

    # Cleanup
    rm -f "/tmp/claude-session-plan-${session_id}.txt"
    rm -f "/tmp/claude-plan-session-map.jsonl"
}

@test "creates session-plan cache file" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    mkdir -p "$HOME/.claude/plans"
    touch "$HOME/.claude/plans/test-plan.md"

    input=$(cat << EOF
{
    "hook_event_name":"SessionStart",
    "session_id":"$session_id"
}
EOF
)

    bash "$BATS_TEST_DIRNAME/../hooks/scripts/plan-tracking.sh" <<< "$input"

    if [ -f "/tmp/claude-session-plan-${session_id}.txt" ]; then
        plan_name=$(cat "/tmp/claude-session-plan-${session_id}.txt")
        [ "$plan_name" = "test-plan" ]
    fi

    # Cleanup
    rm -f "/tmp/claude-session-plan-${session_id}.txt"
    rm -f "/tmp/claude-plan-session-map.jsonl"
}
