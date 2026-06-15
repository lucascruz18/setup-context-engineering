# Structured Outputs

Subagents return only the JSON schema requested - nothing else. The main agent never
processes large output directly; it delegates to a subagent that returns one of these shapes.

## ExploreResult
`{ "schema": "ExploreResult", "found": [...], "patterns": [...], "gaps": [...], "recommendation": "..." }`

## ImplementResult
`{ "schema": "ImplementResult", "created": [...], "modified": [...], "pending": [...], "lint_passed": bool, "notes": "..." }`

## InvestigateResult
`{ "schema": "InvestigateResult", "symptom": "...", "root_cause": "...", "affected_files": [...], "fix": "...", "risk": "..." }`

Pattern details live in [.claude/rules/](../rules/).
