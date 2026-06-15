# CLAUDE.md - {{PROJECT}} (shim)

@AGENTS.md

---

## Claude Code specifics

- **Orchestrator pattern:** the main agent coordinates, subagents execute. Use the Task
  tool with `subagent_type=Explore` to map the codebase before implementing.
- **Plan mode:** use it when planning new features. Subagents return strict JSON following
  the schemas in [.claude/prompts/structured-outputs.md](.claude/prompts/structured-outputs.md).
- **Large output:** never process it directly in the main agent - delegate to a subagent
  that returns only the expected schema.

> Everything else (stack, behavior, context by task type, rules, prompts, memory, commands)
> is inherited via `@AGENTS.md`.
