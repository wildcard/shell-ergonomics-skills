#!/usr/bin/env bats

load test_helper

@test "outputs 3 lines" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id" "/Users/test/caro")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line_count=$(echo "$output" | wc -l)

    [ "$line_count" -eq 3 ]

    teardown
}

@test "line 1 contains model name" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line1=$(echo "$output" | head -1)

    [[ "$line1" =~ "Claude 3.5 Sonnet" ]]

    teardown
}

@test "line 1 contains context percentage" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line1=$(echo "$output" | head -1)

    # 50000 + 5000 = 55000 out of 200000 = 27%
    [[ "$line1" =~ "27% ctx" ]]

    teardown
}

@test "line 2 contains session ID" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line2=$(echo "$output" | sed -n '2p')

    [[ "$line2" =~ "$session_id" ]]

    teardown
}

@test "get_workspace_emoji returns crab for caro project" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id" "/Users/test/caro")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line1=$(echo "$output" | head -1)

    [[ "$line1" =~ "🦀" ]]

    teardown
}

@test "get_workspace_emoji returns package for node project" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id" "/Users/test/my-node-app")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line1=$(echo "$output" | head -1)

    [[ "$line1" =~ "📦" ]]

    teardown
}

@test "uses cached summary when no new messages" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 5
    mock_starship
    mock_claude

    # Create a cached summary
    echo "Cached summary text" > "/tmp/claude-session-summary-${session_id}.txt"
    echo "5" > "/tmp/claude-session-summary-${session_id}.msgcount"

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line2=$(echo "$output" | sed -n '2p')

    [[ "$line2" =~ "Cached summary text" ]]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-summary-${session_id}."*
}

@test "regenerates summary when new messages exist" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    create_history "$session_id" 10  # 10 messages now
    mock_starship
    mock_claude '{"structured_output":{"task":"New AI summary"}}'

    # Cache shows only 5 messages
    echo "Old summary" > "/tmp/claude-session-summary-${session_id}.txt"
    echo "5" > "/tmp/claude-session-summary-${session_id}.msgcount"

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line2=$(echo "$output" | sed -n '2p')

    # Should regenerate with new summary
    [[ "$line2" =~ "New AI summary" ]] || [[ "$line2" =~ "User message" ]]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-summary-${session_id}."*
    rm -f /tmp/claude-ai-summary-*.json
}

@test "falls back to 'Active session' when no history" {
    export CLAUDE_PLUGIN_ROOT="$(cd .. && pwd)"
    session_id="test-$(date +%s)"
    setup
    # No history created
    mock_starship
    mock_claude

    input=$(create_statusline_input "$session_id")

    output=$(echo "$input" | bash "$BATS_TEST_DIRNAME/../skills/advanced-statusline/scripts/statusline-wrapper.sh")
    line2=$(echo "$output" | sed -n '2p')

    [[ "$line2" =~ "Active session" ]]

    teardown
}
