#!/bin/bash
# PreToolUse hook (Bash): if the command contains `git push` or `git commit`,
# runs tests on the changed spec files. On failure it blocks via permissionDecision=deny.
#
# Placeholders to substitute when generating into a target repo:
#   {{REPO_PATH}}             - absolute path to the repo root
#   {{TEST_FILE_REGEX}}       - regex matching test/spec files (e.g. '\.(spec|test)\.(ts|tsx|js|jsx)$')
#   {{TEST_QUICK_CMD_PREFIX}} - test command that accepts file args (e.g. 'npx jest --testPathPattern')

set -u
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

if ! echo "$CMD" | grep -qE '(^|[[:space:];&|])git[[:space:]]+(push|commit)([[:space:];&|]|$)'; then
  exit 0
fi

REPO={{REPO_PATH}}
cd "$REPO" 2>/dev/null || { echo "pre-push-test: cannot cd into $REPO, skipping" >&2; exit 0; }

BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
BASE_BRANCH=${BASE_BRANCH:-main}

SPECS=$( { git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null; \
           git diff --name-only 2>/dev/null; \
           git diff --cached --name-only 2>/dev/null; } \
         | sort -u \
         | grep -E '{{TEST_FILE_REGEX}}' \
         | while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done )

if [ -z "$SPECS" ]; then
  exit 0
fi

# shellcheck disable=SC2086
OUT=$(echo "$SPECS" | xargs {{TEST_QUICK_CMD_PREFIX}} 2>&1)
RC=$?

if [ $RC -ne 0 ]; then
  jq -n --arg out "$OUT" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("Tests failed on changed specs - push/commit blocked. Fix the tests before pushing:\n\n" + $out)
    }
  }'
  exit 0
fi
exit 0
