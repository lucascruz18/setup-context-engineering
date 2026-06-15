---
name: pr-review
description: Multi-agent PR reviewer for {{PROJECT}}. Use only when explicitly requested - "review PR #N", "review this PR", "code review", "/pr-review". Does not trigger automatically during coding or feature implementation. Coordinates 6 subagents (Security, Requirements/DoD, Test Coverage, Architecture, Regression/Hallucination, Performance), each with its own checklist and a mandatory second pass; deduplicates inline comments; produces a consolidated summary.
license: MIT
metadata:
  stack: {{HOOKS_STACK}}
  version: 1.0.0
---

# PR Review - Orchestration Protocol

Coordinates 6 specialized subagents via the Task tool, then consolidates into a unified
summary. Each subagent loads only the docs/rules for its front - this skill does not
duplicate that content.

> **Stack-aware template:** the blocks below are wrapped in `<!-- STACK BLOCK: x -->`
> markers. When this skill is generated, only the block matching the detected stack is
> kept; the others and all STACK BLOCK markers are removed. If you see these markers in a
> live skill, the generation step was skipped - clean them up.

## Step 1: Initialize

1. Get the PR number from context or ask.
2. Identify the repo: `gh repo view --json nameWithOwner -q .nameWithOwner`
3. Fetch the diff: `gh pr diff {PR_NUMBER}`
4. Existing inline comments: `gh api repos/{REPO}/pulls/{PR_NUMBER}/comments` - build a
   `{path, line}` set to avoid duplicates.
5. Intent: `gh pr view {PR_NUMBER} --json title,body,headRefName`
6. Look for a linked ticket (regex `[A-Z]+-[0-9]+` in branch or title).

## Step 2: Launch subagents in parallel

**One single message with 6 Task tool calls.** Pass REPO, PR_NUMBER, the diff, the set of
existing comments, and the intent to each subagent.

## Severity labels (all subagents)

- Critical - bugs or logic errors
- Security - vulnerability or data exposure
- Performance - significant bottleneck
- Warning - code smell / maintainability
- Suggestion - optional improvement

## Universal rules (every subagent)

1. **Allowlist:** only comment on `+` lines (never `+++`).
2. **Skip duplicates:** if `{path, line}` +/-3 lines already has a comment, skip.
3. **Resolved:** reply `[RESOLVED] This appears resolved by recent changes.` on old comments whose problem is fixed.
4. **False-positive guard:** 80%+ confidence or skip.
5. **Positive highlight:** include at least one good point before listing issues.
6. **Tone:** specific, actionable, collegial. Always explain the WHY.
7. **Never** approve, request-changes, or modify files. Comment only.
8. **Marker:** every comment starts with `<!-- pr-review:{type} -->` (invisible, used by consolidation).

## Subagent 1: Security

**Marker:** `<!-- pr-review:security -->`

Load `.claude/rules/shared/*.md` and `.claude/rules/{{DOMINANT_SIDE}}/api.md` (if present).
Focus on documented security violations.

<!-- STACK BLOCK: ruby -->
- `skip_before_action :authenticate_user!` without justification
- `params.permit!` or strong params in the service layer
- SQL injection: `where("...#{x}...")` instead of `where("? = ?", x)`
<!-- END STACK BLOCK: ruby -->
<!-- STACK BLOCK: node -->
- Missing `@UseGuards()` on a new controller (NestJS)
- Logging PII (email, token, password)
- Raw query concatenation (TypeORM/Prisma)
- Client SDK instantiated in a service (should be injected via DI)
<!-- END STACK BLOCK: node -->
<!-- STACK BLOCK: python -->
- SQL injection via f-strings in queries
- `assert` in production (stripped by `python -O`)
- `pickle.loads()` on untrusted input
<!-- END STACK BLOCK: python -->

**Second pass:** re-read the whole diff top to bottom. List every file/hunk you did not
comment on. For each, ask: "does it violate a security rule?" Only skip a file if you can
state why it is clean.

**Comment format:**

    <!-- pr-review:security -->
    Security - [short title]
    [what and why it matters]
    Recommendation: [specific fix]

## Subagent 2: Requirements & Definition of Done

**Marker:** `<!-- pr-review:requirements -->`
**Posts:** one PR-level summary comment, no inline comments.

Track A (Jira) and Track B (local specs), in parallel. Use whichever returns content.

**Track A - Jira ticket:**
1. Extract the ticket id from the branch (regex `[A-Z]+-[0-9]+`).
2. If found, fetch: `curl -su "$JIRA_USER:$JIRA_API_TOKEN" "$JIRA_BASE_URL/rest/api/2/issue/$TICKET_ID?fields=summary,description"`
3. Parse acceptance criteria, user stories, DoD.

**Track B - Local spec files:**
1. Scan PR title/body for refs to spec or task files (`specs/`, `memory/tasks/`, `*-spec.md`).
2. Check `specs/` and `memory/tasks/` - fuzzy match on ticket id or branch name.
3. Read each candidate. Extract acceptance criteria, task checklist, goals/non-goals.

**Resolution:**

| Tracks with content | Action |
|---|---|
| A and B | Merge requirements (note each source) |
| A only | Use Jira |
| B only | Use specs |
| None | Post: "No Jira ticket or spec found - requirements check skipped." and stop |

Compare requirements against the diff. Post via `gh pr comment {PR_NUMBER} --body '...'`.

**Second pass:** after drafting, review each item. Mark implemented / missing / DoD.

**Summary format:**

    <!-- pr-review:requirements -->
    ## Requirements Review
    **Sources:** {Jira: ABC-123 | Spec: specs/X.md | Both}
    ### Implemented
    ### Missing or Incomplete
    ### Definition of Done
    ### Notes

## Subagent 3: Test Coverage

**Marker:** `<!-- pr-review:tests -->`

Load `memory/docs/TESTING.md`. Use the **Coverage Matrix** as the reference for what each
layer requires.

<!-- STACK BLOCK: ruby -->
- Modified controller without a spec in `spec/controllers/` -> Critical
- New service without a spec in `spec/services/` -> Critical
- Generic stub (`allow.to receive.and_return(true)` without `.with(args)`) -> Warning
<!-- END STACK BLOCK: ruby -->
<!-- STACK BLOCK: node -->
- New endpoint (controller method) without e2e in `__test__/*.e2e-spec.ts` -> Critical
- New service without `*.spec.ts` in `__test__/` -> Critical
- Hardcoded numeric id in e2e instead of a factory -> Warning
- Raw HTTP status (`200`) instead of `HttpStatus.OK` -> Warning
- Missing `afterEach`/`afterAll` cleanup in e2e -> Warning
<!-- END STACK BLOCK: node -->
<!-- STACK BLOCK: python -->
- New endpoint without a matching test -> Critical
- Mutable shared fixture -> Warning
<!-- END STACK BLOCK: python -->

**Second pass:** re-read the diff top to bottom. List every new/modified public
handler/endpoint/method you did not comment on. For each: "does it have the test type the
Matrix requires?" Only skip if you can assert coverage exists or is N/A.

**Comment format:**

    <!-- pr-review:tests -->
    [Critical/Warning/Suggestion] - [short title]
    Matrix layer: [layer] - required test type: [unit|e2e|integration]
    [specific gap]
    Recommendation: [pattern to follow, with an example path]

## Subagent 4: Architecture & Patterns

**Marker:** `<!-- pr-review:architecture -->`

### Phase 0 - Load all reference documents
Load all of these before touching the diff:
1. `.claude/rules/shared/*.md` (all files)
2. `.claude/rules/{{DOMINANT_SIDE}}/*.md` (all files)
3. `memory/docs/discovery.md`
4. `memory/docs/decisions.md`
5. `AGENTS.md` ("Never Do This" section)

### Phase 1 - Extract rule list
Scan each doc and extract every explicit rule into a single numbered list. This list is your
evaluation matrix.

### Phase 2 - Evaluate matrix
Work file by file. For each modified file, for each rule decide PASS / VIOLATION / N/A. N/A
only when the rule is structurally inapplicable. For each VIOLATION post inline on the exact
`+` line, citing the rule number and source doc.

**Second pass:** after the matrix, re-read the diff top to bottom. Re-run the matrix on any
file you skipped. Only skip if you can state which rules are N/A and why.

**Comment format:**

    <!-- pr-review:architecture -->
    [Critical/Warning/Suggestion] - [short title]
    Rule: [number + doc, e.g. "Rule 8 - backend/api.md anti-patterns"]
    [what in the diff violates it - cite the line]
    Recommendation: [exact fix, snippet if < 6 lines]

## Subagent 5: Regression & Hallucination

**Marker:** `<!-- pr-review:regression -->`

Look for changes unrelated to the PR's purpose or signs of AI-generated output:
- Deleted code unrelated to the change (Critical)
- Phantom imports (nonexistent symbol) (Critical)
- Method calls with the wrong signature (Critical)
- `TODO` left in production
- Type assertions hiding a compiler error
- Logic duplicating something already in the module (grep before commenting)
- Weakened error handling (empty try/catch, silent return)
- Swallowed job/queue error without a log
- Weakened test assertion
- Dead code (function never called)

**Second pass:** re-read the diff top to bottom. List every file you did not comment on. For
each: "unrelated deletion, phantom import, duplicated logic, or weakened assertion?" Only
skip if you can state why.

**Comment format:**

    <!-- pr-review:regression -->
    [Critical/Warning/Suggestion] - [short title]
    Type: [unrelated-deletion | phantom-import | hallucination | duplicate | regression | dead-code]
    [specific description with the line cited]
    Recommendation: [exact fix]

## Subagent 6: Performance

**Marker:** `<!-- pr-review:performance -->`

Only flag what is **clearly visible in the diff** - no speculation.

<!-- STACK BLOCK: ruby -->
- N+1: `.where`/`.find` inside a loop without `includes`
- `.all` on a large collection instead of `find_each`
- Multiple `save!` without a `transaction`
<!-- END STACK BLOCK: ruby -->
<!-- STACK BLOCK: node -->
- N+1: repository call inside a loop with `await`
- `.find()`/`.findAndCount()` without `take`/`skip` on a large query
- Sequential `await` on independent operations that could be `Promise.all`
- Multiple `repository.save()` without `@Transactional`
<!-- END STACK BLOCK: node -->
<!-- STACK BLOCK: python -->
- N+1 in the ORM (Django: missing `select_related`/`prefetch_related`; SQLAlchemy: missing `joinedload`)
- Per-row query in a loop instead of a bulk operation
<!-- END STACK BLOCK: python -->

**Second pass:** re-read the diff top to bottom. List every block/service/repo-call/loop you
did not comment on. For each: "is there a clearly visible issue?" Only skip if you can state why.

**Comment format:**

    <!-- pr-review:performance -->
    Performance - [short title]
    [description with estimated impact, e.g. "O(N) queries per request"]
    Recommendation: [fix with snippet if < 6 lines]

## Step 3: Consolidation

After the 6 subagents finish, spawn one more subagent via the Task tool to consolidate:
1. `gh api repos/{REPO}/pulls/{PR_NUMBER}/comments` - fetch all inline comments.
2. Filter those starting with `<!-- pr-review: -->` and parse the type from the marker.
3. Fetch PR-level comments for the requirements summary.
4. Group by severity: Security -> Critical -> Performance -> Warning -> Suggestion.
5. Dedupe findings at the same `{path, line}` (+/-3 lines) - note both agents.
6. Collect one positive highlight per agent.
7. **Gap detection:** run `gh pr diff {PR_NUMBER} --name-only`. For every file with no inline
   comment from any subagent, add it to "Files Without Inline Comments". Skip config/lock/type-only.
8. Post: `gh pr review {PR_NUMBER} --comment --body '...'`

**Summary format:**

    ## PR Review - {{PROJECT}}
    | | |
    |---|---|
    | Subagents | 6 (Security, Requirements, Tests, Architecture, Regression, Performance) |
    | Rules loaded | .claude/rules/, memory/docs/decisions.md, memory/docs/TESTING.md |
    | Findings | {N} across {M} files |
    ### Security ({N})
    ### Critical ({N})
    ### Performance ({N})
    ### Warnings ({N})
    ### Suggestions ({N})
    ### Files Without Inline Comments
    ### Highlights

If zero findings: post `No issues found across all review dimensions.` with the metadata table.

## Cost estimate

Using Sonnet across all subagents: ~$2-$5 per review (varies with diff size and the size of
`.claude/rules/`).
