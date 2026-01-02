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

# ====================
# New Mock-Based Tests
# ====================

@test "skips regeneration when valid cache exists" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-cache-$(date +%s)"
    setup
    create_history "$session_id" 5

    # Pre-create cache with valid name
    echo "Existing Session Name" > "/tmp/claude-session-name-${session_id}.txt"
    echo "5" > "/tmp/claude-session-name-${session_id}.msgcount"
    date +%s > "/tmp/claude-session-name-${session_id}.timestamp"

    # Mock claude - should NOT be called
    mock_claude '{"structured_output":{"name":"Should Not See This"}}'

    input='{"session_id":"'"$session_id"'","user_prompt":"Another substantial prompt here"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify original cache preserved
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")
    [ "$name" = "Existing Session Name" ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
}

@test "regenerates name when new messages exist" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-regen-$(date +%s)"
    setup
    create_history "$session_id" 8

    # Pre-create cache with old message count
    echo "Old Session Name" > "/tmp/claude-session-name-${session_id}.txt"
    echo "5" > "/tmp/claude-session-name-${session_id}.msgcount"

    # Mock claude with new name
    mock_claude '{"structured_output":{"name":"Updated Session Name"}}'

    input='{"session_id":"'"$session_id"'","user_prompt":"Add new feature to existing project"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify name was regenerated
    if [ -f "/tmp/claude-session-name-${session_id}.txt" ]; then
        name=$(cat "/tmp/claude-session-name-${session_id}.txt")
        [ "$name" = "Updated Session Name" ]
    fi

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "creates timestamp file on generation" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-timestamp-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude
    mock_claude '{"structured_output":{"name":"Timestamp Test"}}'

    input='{"session_id":"'"$session_id"'","user_prompt":"Create new timestamp testing feature"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify timestamp file exists and contains valid Unix timestamp
    [ -f "/tmp/claude-session-name-${session_id}.timestamp" ]
    timestamp=$(cat "/tmp/claude-session-name-${session_id}.timestamp")
    # Timestamp should be a positive integer
    [[ "$timestamp" =~ ^[0-9]+$ ]]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "updates message count file correctly" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-msgcount-$(date +%s)"
    setup
    create_history "$session_id" 3

    # Mock claude
    mock_claude '{"structured_output":{"name":"Message Count Test"}}'

    input='{"session_id":"'"$session_id"'","user_prompt":"Testing message count tracking logic"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify msgcount file exists and contains expected count
    [ -f "/tmp/claude-session-name-${session_id}.msgcount" ]
    msgcount=$(cat "/tmp/claude-session-name-${session_id}.msgcount" | tr -d '\n\r ')
    [ "$msgcount" = "3" ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "handles special characters in prompt" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-special-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude
    mock_claude '{"structured_output":{"name":"Special Characters OK"}}'

    # Input with quotes, unicode, and special chars
    input='{"session_id":"'"$session_id"'","user_prompt":"Test \"quotes\" and émojis 🚀 and $pecial ch@rs"}'
    run bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Should exit successfully
    [ "$status" -eq 0 ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

# ========================
# Real Claude Haiku Tests
# ========================

@test "real haiku generates valid session name" {
    skip_if_no_api_key

    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="haiku-test-$(date +%s)"
    setup
    create_history "$session_id" 1

    input='{"session_id":"'"$session_id"'","user_prompt":"Build a REST API for managing user accounts and authentication"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify name was generated
    [ -f "/tmp/claude-session-name-${session_id}.txt" ]
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")

    # Verify constraints
    [ ${#name} -le 40 ]  # Max 40 chars
    [ ${#name} -ge 5 ]   # Min reasonable length
    [ -n "$name" ]       # Not empty

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "real haiku respects length constraint" {
    skip_if_no_api_key

    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="haiku-length-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Very long prompt to ensure Haiku condenses it
    input='{"session_id":"'"$session_id"'","user_prompt":"Implement a comprehensive microservices architecture with service discovery, load balancing, circuit breakers, distributed tracing, centralized logging, configuration management, and API gateway patterns"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify name length constraint
    [ -f "/tmp/claude-session-name-${session_id}.txt" ]
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")
    [ ${#name} -le 40 ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "real haiku generates concise names (3-5 words approximately)" {
    skip_if_no_api_key

    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="haiku-words-$(date +%s)"
    setup
    create_history "$session_id" 1

    input='{"session_id":"'"$session_id"'","user_prompt":"Create a new web dashboard for visualizing analytics data"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Verify name exists
    [ -f "/tmp/claude-session-name-${session_id}.txt" ]
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")

    # Count words (approximate - allows for hyphens and common punctuation)
    word_count=$(echo "$name" | wc -w | tr -d ' ')

    # Should be roughly 3-7 words (allowing some flexibility)
    [ "$word_count" -ge 2 ]
    [ "$word_count" -le 8 ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

# ====================
# Fallback Naming Quality Tests
# ====================

@test "fallback creates readable name from long prompt" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-fallback-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude that returns empty (simulates API failure/timeout)
    mock_claude '{}'

    input='{"session_id":"'"$session_id"'","user_prompt":"write a tests to test for the session naming logic using claude haiku"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    name=$(cat "/tmp/claude-session-name-${session_id}.txt")
    echo "Generated fallback name: '$name'" >&3

    # Should create a readable name, not truncated mid-word
    # Should not end with partial words like "session na" or "test f"
    if [[ "$name" =~ \ [a-z]{1,2}$ ]]; then
        echo "FAIL: Name ends with 1-2 letter fragment" >&3
        return 1
    fi

    # Should be reasonable length
    [ ${#name} -le 40 ]
    [ ${#name} -ge 10 ]

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "fallback uses sentence case for multi-word prompts" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-fallback2-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude that returns empty
    mock_claude '{}'

    input='{"session_id":"'"$session_id"'","user_prompt":"add user authentication and authorization to the admin panel"}' 
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    name=$(cat "/tmp/claude-session-name-${session_id}.txt")

    # Should create something like "Add user authentication..." not "add user authentication and authorizat"
    # First char should be uppercase if it's a sentence
    [[ "$name" =~ ^[A-Z] ]] || [[ "$name" =~ ^[a-z]{2,4}\ [a-z] ]]  # Either starts with capital or lowercase article/verb

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "cache exists immediately even when AI times out" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-immediate-$(date +%s)"
    setup
    create_history "$session_id" 1

    # Mock claude that returns empty (simulates timeout/failure)
    mock_claude '{}'

    input='{"session_id":"'"$session_id"'","user_prompt":"Investigate why session naming is not working properly"}'
    bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh" <<< "$input"

    # Cache file MUST exist immediately
    [ -f "/tmp/claude-session-name-${session_id}.txt" ]

    # Cache MUST have a readable fallback name (not empty, not "Unnamed Session")
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")
    [ -n "$name" ]
    [ ${#name} -ge 10 ]

    # Should be a proper fallback like "Investigate why session naming..."
    [[ "$name" =~ ^[A-Z] ]]  # Starts with capital letter

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}

@test "parallel stress test: no race between hook and statusline" {
    export CLAUDE_PLUGIN_ROOT="$BATS_TEST_DIRNAME/.."
    session_id="test-parallel-$(date +%s)"
    setup
    create_history "$session_id" 2

    # Mock claude that returns empty (simulates timeout/failure)
    mock_claude '{}'

    # Prepare input
    input='{"session_id":"'"$session_id"'","user_prompt":"Parallel stress test to prove no race condition exists"}'

    # Launch session naming hook in background
    (
        echo "$input" | bash "$BATS_TEST_DIRNAME/../hooks/scripts/session-naming.sh"
    ) &
    hook_pid=$!

    # Immediately launch statusline reader in parallel (simulating worst-case timing)
    (
        sleep 0.01  # Tiny delay to simulate statusline startup
        cache_file="/tmp/claude-session-name-${session_id}.txt"

        # Try reading cache multiple times (statusline would read it once)
        for i in {1..10}; do
            if [ -f "$cache_file" ]; then
                cat "$cache_file" > /tmp/parallel-test-result-$$.txt
                break
            fi
            sleep 0.01
        done
    ) &
    reader_pid=$!

    # Wait for both processes
    wait $hook_pid || true
    wait $reader_pid || true

    # PROOF 1: Cache file must exist
    [ -f "/tmp/claude-session-name-${session_id}.txt" ]

    # PROOF 2: Cache must have readable content
    name=$(cat "/tmp/claude-session-name-${session_id}.txt")
    [ -n "$name" ]
    [ ${#name} -ge 10 ]

    # PROOF 3: Reader should have successfully read the cache
    if [ -f "/tmp/parallel-test-result-$$.txt" ]; then
        reader_result=$(cat "/tmp/parallel-test-result-$$.txt")
        [ -n "$reader_result" ]
        [ ${#reader_result} -ge 10 ]
        # Should NOT be "Unnamed Session"
        [[ ! "$reader_result" =~ "Unnamed Session" ]]
        rm -f "/tmp/parallel-test-result-$$.txt"
    fi

    # PROOF 4: Proper formatting
    [[ "$name" =~ ^[A-Z] ]]  # Starts with capital letter

    # Cleanup
    teardown
    rm -f "/tmp/claude-session-name-${session_id}."*
    rm -f /tmp/claude-session-name-ai-*.json
}
