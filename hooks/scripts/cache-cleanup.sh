#!/bin/bash
# Shared cache cleanup utility - only cleans when total cache > 100MB
# Keeps recent files (last 7 days) even when cleaning up

set -euo pipefail

# Calculate total cache size
cache_size=$(du -sm /tmp/claude-* 2>/dev/null | awk '{sum+=$1} END {print sum+0}')

# Only cleanup if > 100MB
if [ "$cache_size" -lt 100 ]; then
    exit 0
fi

# Cleanup old files (> 7 days) when cache is large
find /tmp -name "claude-session-summary-*.txt" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-summary-*.timestamp" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-summary-*.msgcount" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-name-*.txt" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-name-*.timestamp" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-name-*.msgcount" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-session-plan-*.txt" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-assistant-actions-*.jsonl" -mtime +7 -delete 2>/dev/null
find /tmp -name "claude-assistant-summary-*.txt" -mtime +7 -delete 2>/dev/null

# Also cleanup temporary AI files (always clean these up if > 1 hour old)
find /tmp -name "claude-ai-summary-*.json" -mmin +60 -delete 2>/dev/null
find /tmp -name "claude-session-name-ai-*.json" -mmin +60 -delete 2>/dev/null

exit 0
