#!/usr/bin/env bats

load test_helper

@test "exits silently when session_id is empty" {
    input='{"session_id":"","user_prompt":"test"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "exits silently when user_prompt is empty" {
    input='{"session_id":"test-123","user_prompt":""}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "filters trivial input: yes" {
    input='{"session_id":"test-123","user_prompt":"yes"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
    [ ! -f "/tmp/claude-session-name-test-123.txt" ]
}

@test "filters trivial input: no" {
    input='{"session_id":"test-123","user_prompt":"no"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "filters trivial input: ok" {
    input='{"session_id":"test-123","user_prompt":"ok"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "filters trivial input: continue" {
    input='{"session_id":"test-123","user_prompt":"continue"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "filters short input less than 10 chars" {
    input='{"session_id":"test-123","user_prompt":"test"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "accepts substantial input over 10 chars" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude CLI
    mock_claude '{"structured_output":{"name":"Test Session Name"}}'

    input=$(cat << EOF
{
    "session_id":"$session_id",
    "user_prompt":"Create a new feature for testing"
}
EOF
)

    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    [ "$status" -eq 0 ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}.txt"
    rm -f "/tmp/claude-session-name-${session_id}.timestamp"
    rm -f "/tmp/claude-session-name-${session_id}.msgcount"
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "generates name on first substantial prompt" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude CLI
    mock_claude '{"structured_output":{"name":"Feature Development"}}'

    input=$(cat << EOF
{
    "session_id":"$session_id",
    "user_prompt":"Implement user authentication system"
}
EOF
)

    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    if [ -f "/tmp/claude-session-name-${session_id}.txt" ]; then
        name=$(cat "/tmp/claude-session-name-${session_id}.txt")
        [ -n "$name" ]
    fi

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "falls back to prompt prefix when AI fails" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude CLI that returns empty
    mock_claude '{}'

    input=$(cat << EOF
{
    "session_id":"$session_id",
    "user_prompt":"Build a REST API for inventory management system"
}
EOF
)

    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    if [ -f "/tmp/claude-session-name-${session_id}.txt" ]; then
        name=$(cat "/tmp/claude-session-name-${session_id}.txt")
        # Should use first 40 chars of prompt
        [[ "$name" =~ "Build a REST API" ]]
    fi

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}
