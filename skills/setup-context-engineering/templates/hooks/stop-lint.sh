#!/bin/bash
# Stop hook: lints the files changed in this branch (base...HEAD + working tree + staged)
# ONLY if there was an Edit/Write this turn (sentinel created by mark-edit-pending.sh).
# On failure it returns exit 2 with output on stderr, so Claude is notified and must fix it.
#
# Placeholders to substitute when generating into a target repo:
#   {{REPO_PATH}}  - absolute path to the repo root
#   {{FILE_REGEX}} - regex of lintable file extensions (e.g. '\.(ts|tsx|js|jsx)$')
#   {{LINT_CMD}}   - lint command with auto-fix that accepts file args (e.g. 'npx eslint --fix')

set -u
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
SENTINEL="/tmp/claude-lint-pending-${SESSION}"

if [ ! -f "$SENTINEL" ]; then
  exit 0
fi
rm -f "$SENTINEL"

REPO={{REPO_PATH}}
cd "$REPO" 2>/dev/null || { echo "stop-lint: cannot cd into $REPO, skipping lint" >&2; exit 0; }

BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
BASE_BRANCH=${BASE_BRANCH:-main}

FILES=$( { git diff --name-only "${BASE_BRANCH}...HEAD" 2>/dev/null; \
           git diff --name-only 2>/dev/null; \
           git diff --cached --name-only 2>/dev/null; } \
         | sort -u \
         | grep -E '{{FILE_REGEX}}' \
         | while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done )

if [ -z "$FILES" ]; then
  exit 0
fi

# shellcheck disable=SC2086
OUT=$(echo "$FILES" | xargs {{LINT_CMD}} 2>&1)
RC=$?

if [ $RC -ne 0 ]; then
  {
    echo "Lint failed on files changed in this branch. Fix before finishing:"
    echo "$OUT"
  } >&2
  exit 2
fi
exit 0
