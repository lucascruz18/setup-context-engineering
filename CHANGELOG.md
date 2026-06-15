# Changelog

All notable changes to this skill are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-06

Consolidates patterns from IA-First (RPI + Spec-Driven), TLC-spec (deterministic per-task
gates), and a multi-agent PR review flow.

### Added
- 3-layer discovery: Haiku triage -> parallel Sonnet extraction -> session-model synthesis.
- Stack-aware git hooks (Stop lint, pre-push/commit tests) for node / ruby / python / go / generic.
- `memory/docs/TESTING.md` with Coverage Matrix + Gate Commands + Parallelism assessment.
- `memory/STATE.md` functional cross-session memory.
- Multi-agent `pr-review` skill (6 subagents) generated stack-aware.
- `validate-setup.sh` deterministic self-check used as the final gate.
- Task spec template with Tests / Gate / Reuses / Requirement fields.

### Changed
- Packaged as an **Agent Skill** (previously a slash command). Heavy templates moved out of
  the manifest into `templates/`, loaded on demand (progressive disclosure). Manifest went
  from 1152 to 300 lines.
- Translated to English; unified placeholder convention (`{{UPPER_SNAKE}}` substituted at
  generation, `[lowercase]` slots left for the human).
- pr-review stack conditionals now use `STACK BLOCK` markers instead of `{{#if}}` syntax, so
  generated files never leak template syntax.

### Migration from v1 (slash command)
The old `commands/setup-context-engineering.md` is superseded. Behavior is the same; only the
invocation changes — from `/setup-context-engineering lite auto` to asking Claude to run the
skill in "lite, auto" mode.
