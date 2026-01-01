#!/bin/bash
set -euo pipefail

# Read hook input
input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id // ""')
hook_event=$(echo "$input" | jq -r '.hook_event_name // ""')

if [ -z "$session_id" ]; then
    exit 0
fi

# Only run on PostToolUse
if [ "$hook_event" != "PostToolUse" ]; then
    exit 0
fi

# Extract tool information
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
tool_input=$(echo "$input" | jq -r '.tool_input // {}')

# Skip empty or system tools
if [ -z "$tool_name" ] || [ "$tool_name" = "null" ]; then
    exit 0
fi

# Cache file for assistant actions
actions_cache="/tmp/claude-assistant-actions-${session_id}.jsonl"

# Record action with timestamp
action_entry=$(jq -n \
    --arg tool "$tool_name" \
    --arg timestamp "$(date +%s)" \
    --argjson input "$tool_input" \
    '{tool: $tool, timestamp: $timestamp, input: $input}')

echo "$action_entry" >> "$actions_cache"

# Keep only last 50 actions
if [ -f "$actions_cache" ]; then
    tail -50 "$actions_cache" > "${actions_cache}.tmp" && mv "${actions_cache}.tmp" "$actions_cache"
fi

# Generate summary of recent actions (last 10)
recent_actions=$(tail -10 "$actions_cache" 2>/dev/null | jq -r '.tool' | sort | uniq -c | sort -rn | head -3 | awk '{print $2}' | paste -sd ', ' -)

if [ -n "$recent_actions" ]; then
    echo "$recent_actions" > "/tmp/claude-assistant-summary-${session_id}.txt"
fi

# Occasionally run shared cleanup (1% of the time)
if [ $((RANDOM % 100)) -eq 0 ]; then
    bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/cache-cleanup.sh" &
fi

exit 0
