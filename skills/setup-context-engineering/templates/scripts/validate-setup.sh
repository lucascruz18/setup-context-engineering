#!/usr/bin/env bash
# Validates the setup produced by the setup-context-engineering skill.
# Usage: bash .claude/scripts/validate-setup.sh

set -euo pipefail
ERRORS=0
WARNINGS=0

fail() { echo "FAIL: $1"; ERRORS=$((ERRORS+1)); }
warn() { echo "WARN: $1"; WARNINGS=$((WARNINGS+1)); }
ok()   { echo "OK:   $1"; }

# --- Core required files ---
for f in "memory/docs/discovery.md" "AGENTS.md" "CLAUDE.md" "memory/docs/decisions.md" "memory/docs/TESTING.md" "memory/STATE.md" "specs/template.md"; do
  [ -f "$f" ] && ok "$f exists" || fail "$f missing"
done

# --- AGENTS.md minimum sections ---
for section in "Context by Task Type" "Never Do This" "Stack" "Commands" "Memory"; do
  grep -q "$section" AGENTS.md 2>/dev/null && ok "AGENTS.md has section '$section'" || fail "AGENTS.md missing '$section'"
done

# --- CLAUDE.md is a shim ---
grep -q "@AGENTS.md" CLAUDE.md 2>/dev/null && ok "CLAUDE.md is a shim importing @AGENTS.md" || warn "CLAUDE.md does not import AGENTS.md via @"

# --- 'Never Do This' should have >= 3 path-anchored items ---
count=$(grep -c "src/\|app/\|lib/\|package/" AGENTS.md 2>/dev/null || echo 0)
[ "$count" -ge 3 ] && ok "AGENTS.md has $count path-anchored items" || fail "'Never Do This' has fewer than 3 path-anchored items"

# --- TESTING.md has Coverage Matrix + Gate Commands ---
for section in "Coverage Matrix" "Gate Check Commands" "Parallelism"; do
  grep -q "$section" memory/docs/TESTING.md 2>/dev/null && ok "TESTING.md has '$section'" || fail "TESTING.md missing '$section'"
done

# --- STATE.md functional sections ---
for section in "Current snapshot" "Active blockers" "Decisions taken"; do
  grep -q "$section" memory/STATE.md 2>/dev/null && ok "STATE.md has '$section'" || warn "STATE.md missing '$section'"
done

# --- Rules: max 40 lines and must cite evidence ---
find .claude/rules -name "*.md" 2>/dev/null | while read -r f; do
  lines=$(wc -l < "$f")
  [ "$lines" -le 40 ] && ok "$f has $lines lines (<=40)" || fail "$f has $lines lines (max 40)"
  grep -qi "evidence\|src/\|app/\|package/" "$f" || warn "$f may be missing path-anchored evidence"
done

# --- Prompts: max 50 lines ---
find .claude/prompts -name "*.md" 2>/dev/null | while read -r f; do
  lines=$(wc -l < "$f")
  [ "$lines" -le 50 ] && ok "$f has $lines lines (<=50)" || fail "$f has $lines lines (max 50)"
done

# --- Hooks ---
if [ -d ".claude/hooks" ]; then
  for h in "mark-edit-pending.sh" "stop-lint.sh" "pre-push-test.sh"; do
    if [ -f ".claude/hooks/$h" ]; then
      [ -x ".claude/hooks/$h" ] && ok "$h is executable" || fail "$h exists but is not executable (chmod +x)"
    fi
  done
fi

# --- pr-review skill ---
if [ -d ".claude/skills/pr-review" ]; then
  [ -f ".claude/skills/pr-review/SKILL.md" ] && ok "pr-review/SKILL.md exists" || fail "pr-review/SKILL.md missing"
  grep -q "^name:" .claude/skills/pr-review/SKILL.md 2>/dev/null && ok "SKILL.md has name frontmatter" || fail "SKILL.md missing frontmatter"
fi

# --- Paths cited in rules should exist ---
grep -rh "src/\|app/\|lib/\|package/" .claude/rules/ 2>/dev/null | grep -oE '(src|app|lib|package)/[^: )]+\.[a-z]+' | sort -u | while read -r p; do
  [ -f "$p" ] || warn "path cited in a rule does not exist: $p"
done

echo ""
RULES=$(find .claude/rules -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
PROMPTS=$(find .claude/prompts -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
HOOKS=$(find .claude/hooks -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
SKILLS=$(find .claude/skills -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')

echo "Inventory: $RULES rules - $PROMPTS prompts - $HOOKS hooks - $SKILLS skills"
echo ""

if [ "$ERRORS" -eq 0 ]; then
  echo "OK - setup valid ($WARNINGS warnings)"
  exit 0
else
  echo "FAIL - $ERRORS error(s), $WARNINGS warnings"
  exit 1
fi
