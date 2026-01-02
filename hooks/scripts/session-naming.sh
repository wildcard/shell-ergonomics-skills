#!/bin/bash
set -euo pipefail

# Read hook input
input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id // ""')
user_prompt=$(echo "$input" | jq -r '.user_prompt // ""')

# Exit if no session ID or prompt
if [ -z "$session_id" ] || [ -z "$user_prompt" ]; then
    exit 0
fi

# Filter out trivial inputs
if echo "$user_prompt" | grep -qiE '^(yes|no|ok|okay|sure|continue|try again|test it|fix it|run it|check|show|nope|yep|go ahead|proceed)\.?$'; then
    exit 0
fi

# Also filter out very short inputs (< 10 chars)
if [ ${#user_prompt} -lt 10 ]; then
    exit 0
fi

# Cache files
cache_file="/tmp/claude-session-name-${session_id}.txt"
timestamp_file="/tmp/claude-session-name-${session_id}.timestamp"
msg_count_file="/tmp/claude-session-name-${session_id}.msgcount"

# Check if we need to regenerate (similar to summary logic)
should_regenerate=false
history_file="$HOME/.claude/history.jsonl"

# Get current message count
current_msg_count=0
if [ -f "$history_file" ]; then
    current_msg_count=$(grep -c "\"sessionId\":\"${session_id}\"" "$history_file" 2>/dev/null || echo "0")
    current_msg_count=$(echo "$current_msg_count" | tr -d '\n\r ')
fi
current_msg_count=${current_msg_count:-0}

if [ ! -f "$cache_file" ]; then
    # No cache exists, generate new name
    should_regenerate=true
else
    cached_name=$(cat "$cache_file" 2>/dev/null || echo "")
    # If cache is empty or invalid, regenerate
    if [ -z "$cached_name" ] || [ ${#cached_name} -lt 5 ]; then
        should_regenerate=true
    else
        # Check if new messages exist since last generation
        last_msg_count=$(cat "$msg_count_file" 2>/dev/null | tr -d '\n\r ' || echo "0")
        last_msg_count=${last_msg_count:-0}
        if [ "$current_msg_count" -gt "$last_msg_count" ]; then
            should_regenerate=true
        fi
    fi
fi

# If we don't need to regenerate, exit early
if [ "$should_regenerate" = false ]; then
    exit 0
fi

# Generate session name using AI (with timeout)
schema='{"type":"object","properties":{"name":{"type":"string","maxLength":40}},"required":["name"]}'
prompt="Generate a concise session name (3-5 words, max 40 chars) for this task: ${user_prompt}"

ai_temp="/tmp/claude-session-name-ai-${session_id}-$$.json"

# Run with timeout (5 seconds - matches settings.json timeout)
(
    echo "$prompt" | claude --model haiku -p --no-session-persistence --output-format json --json-schema "$schema" 2>/dev/null > "$ai_temp"
) &
claude_pid=$!

for i in {1..5}; do
    if ! kill -0 $claude_pid 2>/dev/null; then
        break
    fi
    sleep 1
done

kill $claude_pid >/dev/null 2>&1 || true
wait $claude_pid >/dev/null 2>&1 || true

# Extract name
session_name=""
if [ -f "$ai_temp" ] && [ -s "$ai_temp" ]; then
    session_name=$(jq -r '.structured_output.name // empty' "$ai_temp" 2>/dev/null || echo "")
    rm -f "$ai_temp"
fi

# Fallback: create readable name from prompt
if [ -z "$session_name" ] || [ ${#session_name} -lt 5 ]; then
    # Take complete words until we exceed 37 chars (leave room for "...")
    session_name=""
    for word in $user_prompt; do
        if [ -z "$session_name" ]; then
            # First word - capitalize it
            session_name="$(echo "${word:0:1}" | tr '[:lower:]' '[:upper:]')${word:1}"
        else
            # Check if adding this word would exceed limit
            test_name="$session_name $word"
            if [ ${#test_name} -le 37 ]; then
                session_name="$test_name"
            else
                # Would exceed limit, add ellipsis and break
                session_name="${session_name}..."
                break
            fi
        fi
    done

    # If we got through all words without truncating, don't add ellipsis
    if [[ ! "$session_name" =~ \.\.\.$ ]]; then
        # Ensure it's not too long anyway
        if [ ${#session_name} -gt 40 ]; then
            session_name="${session_name:0:37}..."
        fi
    fi
fi

# Cache the name, timestamp, and message count
echo "$session_name" > "$cache_file"
date +%s > "$timestamp_file"
echo "$current_msg_count" > "$msg_count_file"

# Occasionally run shared cleanup (1% of the time to minimize overhead)
if [ $((RANDOM % 100)) -eq 0 ]; then
    bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/cache-cleanup.sh" &
fi

exit 0
