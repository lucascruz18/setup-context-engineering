# Mixed-Stack Spec-Driven Repos

Spec-driven development helps a team agree on what should be built. In a mixed-stack repository,
the harder problem is often how agents should move through the codebase without flattening every
stack into one generic convention.

This is common in repos that combine:

- a frontend app;
- a backend service;
- a CMS/platform layer such as AEM;
- shared packages or generated contracts;
- scripts, CI, release tooling, and infra.

## Problem

A single instruction file usually becomes too vague:

```txt
Follow the project conventions.
Run the tests.
Do not break the CMS integration.
```

That does not tell an agent:

- which files define frontend conventions;
- where backend DTOs and API contracts live;
- which CMS layer rules are platform-specific;
- what test command applies to the edited side;
- when a fullstack task must update shared contracts;
- which patterns are real and which are aspirational.

## Where setup-context-engineering fits

`setup-context-engineering` runs before implementation. It classifies the repository, discovers
observed conventions, and creates an agent operating layer:

```txt
Spec / task
  -> classify stack and repo shape
  -> discover real conventions per side
  -> write AGENTS.md routing
  -> write side-specific rules with evidence
  -> write prompts, memory, testing matrix, hooks
  -> run deterministic validation
```

The output is not a generic prompt. It is a repo-local map that can route work by task type:

```txt
Frontend task -> shared + frontend rules + api-client prompt
Backend task  -> shared + backend rules + api-contracts/error-handling prompts
CMS task      -> shared + platform-specific rules or explicit TBDs
Fullstack task -> both sides + contract/testing checklist
```

## Why this matters for agents

Agents are much more useful when they can answer these questions before editing:

- What side of the repo am I touching?
- Which conventions are backed by real files?
- What should I never do in this codebase?
- What tests or checks prove this change?
- What shared contracts or docs must move with this change?

For brownfield repositories, the skill documents what is already true before suggesting what
should improve. That makes it safer for legacy systems and teams with multiple stacks in one repo.

## What it does not replace

It does not replace:

- spec-driven planning;
- architecture decisions;
- CI;
- human review;
- platform expertise for AEM or any other CMS.

It complements them by turning the repository itself into executable context for agents.

