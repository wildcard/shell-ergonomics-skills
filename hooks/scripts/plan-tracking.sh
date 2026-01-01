#!/bin/bash
set -euo pipefail

# Read hook input
input=$(cat)

session_id=$(echo "$input" | jq -r '.session_id // ""')
hook_event=$(echo "$input" | jq -r '.hook_event_name // ""')

if [ -z "$session_id" ]; then
    exit 0
fi

# Plan tracking file
plan_map="/tmp/claude-plan-session-map.jsonl"

# On SessionStart or UserPromptSubmit, check for recent plans
if [ "$hook_event" = "SessionStart" ] || [ "$hook_event" = "UserPromptSubmit" ]; then
    # Find most recent plan (within last 10 minutes)
    recent_plan=$(find ~/.claude/plans -name "*.md" -mmin -10 -type f 2>/dev/null | head -1)

    if [ -n "$recent_plan" ]; then
        plan_name=$(basename "$recent_plan" .md)

        # Record mapping
        echo "{\"session_id\":\"${session_id}\",\"plan\":\"${plan_name}\",\"timestamp\":$(date +%s)}" >> "$plan_map"

        # Cache current session's plan
        echo "$plan_name" > "/tmp/claude-session-plan-${session_id}.txt"
    fi
fi

# Keep plan map under control (keep only last 1000 entries)
if [ -f "$plan_map" ]; then
    tail -1000 "$plan_map" > "${plan_map}.tmp" && mv "${plan_map}.tmp" "$plan_map"
fi

# Occasionally run shared cleanup (1% of the time)
if [ $((RANDOM % 100)) -eq 0 ]; then
    bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/cache-cleanup.sh" &
fi

exit 0
