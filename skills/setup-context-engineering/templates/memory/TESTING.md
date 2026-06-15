# Testing - {{PROJECT}}

> Coverage Matrix + Gate Commands + Parallelism. Consumed by `task-spec.md` and the `pr-review` skill.
> Regenerate via the setup-context-engineering skill when the stack or test framework changes.

## Test Coverage Matrix

Which layers require which kind of test - derived from Layer 2 discovery.

| Layer                | Required tests | When "none" is acceptable |
|----------------------|----------------|---------------------------|
| [layer]              | unit           | [rationale]               |
| [layer]              | integration    | [rationale]               |
| [layer]              | e2e            | [rationale]               |
| pure util/helper     | unit           | -                         |
| DTO / type-only file | none           | no logic                  |

**Rule:** when a task creates/modifies a layer listed above, the task MUST include the
matching test type (`Tests:` field in the task-spec). "Tested in another task" is not valid.

## Gate Check Commands

| Gate      | Command                          | Use case                          |
|-----------|----------------------------------|-----------------------------------|
| quick     | `{{TEST_QUICK_CMD_PATTERN}}`     | Per-task - one layer / one file   |
| full      | `{{TEST_FULL_CMD}}`              | Phase / Pre-PR                    |
| build     | `{{BUILD_CMD}}` (or TBD if null) | Pre-release                       |
| lint      | `{{LINT_CMD}}`                   | Always before Done                |
| typecheck | `{{TYPECHECK_CMD}}` (or TBD)     | Always before Done                |

Replace `{file}` in the quick gate with the real path when building a task's command.

## Parallelism Assessment

| Test type   | Parallel-safe? | Prerequisite                                        |
|-------------|----------------|-----------------------------------------------------|
| unit        | Yes            | no shared state                                     |
| integration | Conditional    | isolated DB/Redis per subagent (separate schema/db) |
| e2e         | No (default)   | shared services (HTTP, queue) - run sequentially    |

When a task is marked `[P]` (parallel), the matching test MUST be parallel-safe. Otherwise
drop `[P]` even if the code is independent - the test is the bottleneck.

## Documented anti-patterns

- **Silent test deletion** - a task that reduces test count without justification. The
  `Test count: N` field in the task-spec prevents this.
- **Generic stubs** - stubbing a method without `.with(args)` masks regressions. Stubs must be granular.
- **Test deferral** - postponing a layer's required tests to "another task later" violates co-location.
