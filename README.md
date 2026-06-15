# setup-context-engineering

A Claude Code [Agent Skill](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
that bootstraps a running codebase for AI-agent operation. Point it at a project that has no
AI scaffolding and it produces a complete context-engineering layer — `AGENTS.md`, rules,
prompts, memory docs, deterministic git hooks, and a multi-agent PR reviewer — grounded in the
patterns it actually observes in your code, never generic boilerplate.

## Why

Most "AI-ready" setups are hand-written once, drift immediately, and assert conventions the
codebase doesn't really follow. This skill instead **discovers** the repo's real patterns
(with `path:line` evidence), writes them down as verifiable rules, and wires up the gates that
keep an agent honest. It is built for **brownfield** projects: existing, running code that you
want an agent to work in safely.

## What it generates (in the target project)

```
target-project/
├── AGENTS.md                      # source of truth for agents
├── CLAUDE.md                      # thin shim: @AGENTS.md + Claude Code specifics
├── specs/template.md              # feature spec template
├── memory/
│   ├── STATE.md                   # functional memory across sessions
│   ├── tasks/example-task.md      # atomic task spec (Tests/Gate/Reuses)
│   └── docs/{discovery,decisions,TESTING}.md
└── .claude/
    ├── rules/{shared,backend,frontend}/*.md   # observed patterns + evidence
    ├── prompts/*.md               # reusable, task-type-routed instructions
    ├── hooks/*.sh                 # stack-aware lint/test gates
    ├── skills/pr-review/SKILL.md  # 6-subagent code reviewer
    └── scripts/validate-setup.sh  # deterministic self-check
```

## Requirements

- **Claude Code** (the skill runs inside it).
- **git** — discovery and the hooks operate on the working tree and branch diff.
- **jq** — the generated hooks parse hook input from stdin.
- **gh** (GitHub CLI) — used by the generated `pr-review` skill.
- The target project's own **lint / test commands** (auto-detected in Layer 1).

## Installation

```bash
git clone https://github.com/lucascruz18/setup-context-engineering.git

# Personal — available in all your projects:
cp -r setup-context-engineering/skills/setup-context-engineering ~/.claude/skills/

# Or per-project — commit it with the repo:
cp -r setup-context-engineering/skills/setup-context-engineering <project>/.claude/skills/
```

## Usage

Open Claude Code in the target project and ask it to run the skill. Modes are natural language:

- `set up context engineering here` — lite discovery (~3 subagents), with checkpoints
- `set up context engineering, full mode` — complete discovery (~6 subagents)
- `... full, auto` — skip the human checkpoints between layers
- `... skip-hooks` / `... skip-skills` — omit the hooks or the pr-review skill

The skill pauses at a checkpoint after each layer (unless `auto`) so you can confirm or adjust
the plan before it writes anything.

## How it works

Three layers, one at a time, each on the cheapest model that fits:

1. **Triage (Haiku)** — one subagent classifies the stack, maturity, and real lint/test
   commands. No code reading, just structure.
2. **Discovery (Sonnet, parallel)** — per-front subagents read 2–3 representative files each
   and write evidence-backed rules directly to `.claude/rules/`. Nothing large flows back
   through the main context.
3. **Synthesis (session model)** — materializes the templates into `AGENTS.md`, memory docs,
   hooks, and the pr-review skill, then runs `validate-setup.sh` as a deterministic gate.

Templates live in [`templates/`](skills/setup-context-engineering/templates/) and are loaded
only when a layer needs them, keeping the manifest small.

## What it writes to your machine

This skill is transparent by design, but you should know what it does before running it:

- Creates `AGENTS.md`, `CLAUDE.md`, `specs/`, `memory/`, and `.claude/` in the **target project**.
- Installs git hooks that run lint on `Stop` and can **block `git push` / `git commit`** when
  tests fail on changed specs.
- Merges hook configuration into `.claude/settings.local.json`.
- **Never overwrites human content** — if an artifact already exists it reads it first,
  preserves your edits, and proposes a diff before writing.

## Customizing

The generated artifacts are yours to edit. The skill leaves `[lowercase]` slots and `TBD`
markers wherever it lacks evidence — fill those in. To regenerate after the stack changes,
re-run the skill; it diffs against existing files rather than clobbering them.

## License

[MIT](LICENSE) © 2026 Lucas Cruz
