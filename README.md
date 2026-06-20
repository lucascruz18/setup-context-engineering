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

## When to use it

Use this when a repository is too real for a generic `CLAUDE.md`:

- a brownfield app with conventions that live in people's heads;
- a monorepo or multi-stack repo where backend, frontend, CMS, scripts, and infra each have
  different rules;
- a team adopting spec-driven development but still missing the repo-specific operating layer
  agents need before editing code;
- a project where agent output must respect existing architecture, tests, naming, and delivery
  workflow instead of inventing a new one.

It works especially well as the first step before asking agents to implement features in mixed
repositories: it maps the terrain, then turns that map into reusable rules, memory, prompts, and
gates.

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

## Before / After

| Before | After |
| --- | --- |
| "Read the repo and be careful." | `AGENTS.md` explains how agents must operate in this specific codebase. |
| Generic rules copied from another project. | `.claude/rules/` contains observed conventions with `path:line` evidence. |
| Specs, prompts, memory, and decisions scattered across chat history. | `specs/`, `memory/`, and `.claude/prompts/` create a repeatable workflow. |
| Agents run edits without knowing the quality gates. | Stack-aware hooks and `memory/docs/TESTING.md` document lint, typecheck, and test commands. |
| PR review depends on one model reading everything. | A generated `pr-review` skill splits review across Security, Requirements, Tests, Architecture, Regression, and Performance. |

## Example: mixed-stack repo

For a repo with multiple stacks, the skill first classifies the shape of the project instead of
assuming one global convention:

```txt
project/
├── apps/web/              # React / Next / Vite frontend
├── apps/api/              # Node / Rails / Python / Go backend
├── cms/                   # AEM, CMS, or platform-specific layer
├── packages/shared/       # shared types, utils, contracts
└── scripts/               # automation and release tooling
```

Then it can generate task routing such as:

```txt
Frontend task -> shared rules + frontend rules + api-client prompt
Backend task  -> shared rules + backend rules + api-contracts/error-handling prompts
CMS task      -> shared rules + platform-specific TBDs until enough evidence exists
Fullstack task -> both sides + contract/update checklist
```

The important part is not the folder names. It is that each side gets its own rules only when the
skill has evidence from real files.

See also: [Mixed-stack spec-driven repos](docs/use-cases/mixed-stack-spec-driven.md).

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

## How it fits with spec-driven tools

Spec-driven tools help describe **what should be built**. This skill prepares the repository for
**how agents should safely build it here**.

In practice:

```txt
Spec / ticket / task
  -> setup-context-engineering maps the repo's operating context
  -> AGENTS.md routes the work by stack and task type
  -> rules/prompts/memory keep implementation aligned with the codebase
  -> hooks and pr-review create feedback before merge
```

It does not replace specs, architecture decisions, CI, or human review. It gives those pieces a
repo-native operating layer agents can actually follow.

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

## What it is not

- Not a generic prompt pack.
- Not a replacement for CI.
- Not a code generator.
- Not a promise that every repo has clean conventions.

It documents what is real, marks what is unclear, and gives agents a safer operating surface.

## Used in real brownfield workflows

This skill was shaped from repeated use in private product codebases with split backend/frontend
repos, Electron desktop apps, Go sidecar processes, queue-heavy APIs, and multi-agent review
flows. The public repository keeps the reusable operating layer while leaving product code,
customer data, and private implementation details out of scope.

## License

[MIT](LICENSE) © 2026 Lucas Cruz
