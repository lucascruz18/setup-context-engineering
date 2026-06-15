# Task Spec Template

Every non-trivial task starts as a spec in `memory/tasks/<id>.md` before implementation.
A "verifiable" criterion means there is a command, a test, or a concrete observation that
proves "done". Vague verbs (improve, refactor, clean up) are not acceptance criteria -
break them into something observable.

Copy the structure below for each task (delimited by the rules):

---

# [ID]: [imperative title]

## Execution state
**Status:** TODO | IN_PROGRESS | DONE | BLOCKED
**Blockers:** [IDs or none]
**Unblocks:** [IDs or none]
**Track:** [parallel track name, if any]
**Priority:** P0 | P1 | P2

## What
One sentence - the concrete deliverable.

## Where
- `path/to/file.ts` - reason
- `path/to/test.spec.ts` - what to test

## Reuses
- `src/existing/Helper.ts` - established pattern to reference
- Token-saver: always cite what already exists and should be reused.

## Requirement
Ties this task to a verifiable criterion in `specs/<feature>/spec.md` or a roadmap item.

## Tests
unit | integration | e2e | none. Justify from `memory/docs/TESTING.md` (Coverage Matrix).

## Gate
quick | full | build. Exact command from TESTING.md Gate Check Commands.

## Done when
- [ ] verifiable outcome 1
- [ ] verifiable outcome 2
- [ ] Gate check passes (exit code 0)
- [ ] Test count: N tests pass (no silent deletions)
- [ ] Lint + typecheck: zero errors

## Verify
Command that proves it works, plus the expected output.

## Decisions to log
Anything that becomes an entry in `memory/docs/decisions.md`?

## Pre-commit checklist
- [ ] `git diff --name-only` - every changed file is in scope?
- [ ] Removed methods have zero callers (`grep -rn`)?
- [ ] Stubs are granular (`.with(args)`), not generic?

---

Pattern details live in [.claude/rules/](../rules/).
