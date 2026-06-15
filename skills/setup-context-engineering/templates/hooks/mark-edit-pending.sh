#!/bin/bash
# PostToolUse(Write|Edit): marks that an edit happened this turn.
# The Stop hook reads this sentinel to decide whether to run lint.
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
touch "/tmp/claude-lint-pending-${SESSION}" 2>/dev/null
exit 0
