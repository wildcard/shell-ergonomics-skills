#!/usr/bin/env bats

load test_helper

@test "exits silently when session_id is empty" {
    input='{"hook_event_name":"PostToolUse","session_id":""}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "exits silently on non-PostToolUse events" {
    input='{"hook_event_name":"UserPromptSubmit","session_id":"test-123"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "exits silently when tool_name is empty" {
    input='{"hook_event_name":"PostToolUse","session_id":"test-123","tool_name":""}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "exits silently when tool_name is null" {
    input='{"hook_event_name":"PostToolUse","session_id":"test-123","tool_name":null}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"

    [ "$status" -eq 0 ]
}

@test "records tool action to actions cache" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    input=$(cat << EOF
{
    "hook_event_name":"PostToolUse",
    "session_id":"$session_id",
    "tool_name":"Read",
    "tool_input":"{\"file_path\":\"/test.txt\"}"
}
EOF
)

    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"

    [ "$status" -eq 0 ]
    [ -f "/tmp/claude-assistant-actions-${session_id}.jsonl" ]

    # Cleanup
    rm -f "/tmp/claude-assistant-actions-${session_id}.jsonl"
    rm -f "/tmp/claude-assistant-summary-${session_id}.txt"
}

@test "generates summary of top 3 tools" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"

    # Record multiple tool uses
    for tool in Read Write Edit Read Read Write Read; do
        input=$(cat << EOF
{
    "hook_event_name":"PostToolUse",
    "session_id":"$session_id",
    "tool_name":"$tool",
    "tool_input":"{}"
}
EOF
)
        bash "$BATS_TEST_DIRNAME/../hooks/scripts/assistant-output-sampling.sh" <<< "$input"
    done

    # Check summary contains top tools (Read should be #1)
    summary=$(cat "/tmp/claude-assistant-summary-${session_id}.txt")
    [[ "$summary" =~ "Read" ]]

    # Cleanup
    rm -f "/tmp/claude-assistant-actions-${session_id}.jsonl"
    rm -f "/tmp/claude-assistant-summary-${session_id}.txt"
}
