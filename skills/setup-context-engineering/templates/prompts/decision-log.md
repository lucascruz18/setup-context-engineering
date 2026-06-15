# Decision Log Format

Append-only. Never edit existing entries. Newest at the bottom.

## When to log a decision
Log a decision when you make a choice that is non-obvious, hard to reverse, or that a
future contributor would otherwise have to reverse-engineer:
- choosing a library, pattern, or module boundary
- rejecting an approach for a concrete reason
- a convention the team must follow going forward

## Entry format

    ### [ISO date] - [short title]
    **Context:** what forced the decision.
    **Decision:** what was chosen.
    **Rationale:** why, and what was rejected.
    **Consequences:** trade-offs accepted.
