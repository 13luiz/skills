# Type Checking and Linting Strategy

## Why This Is the Highest-ROI Harness Component

Strongly-typed languages with good linting are the single most effective guardrail for AI-assisted development. Type errors catch hallucinated APIs, wrong signatures, and structural mistakes instantly. Lint rules enforce conventions agents cannot learn from conversation alone.

## Strategy: 3-5 High-Value Custom Rules

Don't create 50 lint rules. Start with 3-5 targeting your most common agent failure patterns. Add more as new patterns emerge.

**How to identify which rules to create:**
1. Review the last 20 AI-generated PRs
2. Categorize issues caught in review
3. For each category appearing 3+ times, write a lint rule
4. Include remediation instructions in the error message

## Setup by Ecosystem

### JavaScript/TypeScript
```json
{
  "scripts": {
    "lint": "eslint . && biome check .",
    "typecheck": "tsc --noEmit",
    "format": "biome format --write ."
  }
}
```

Essential config:
- `strict: true` in tsconfig.json
- `noUncheckedIndexedAccess: true`
- `noImplicitAny: true`
- ESLint with `@typescript-eslint` for type-aware rules

### Python
```toml
[tool.ruff]
line-length = 88
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM", "TCH"]

[tool.mypy]
strict = true
warn_return_any = true
warn_unused_configs = true
```

Essential: mypy strict, ruff for linting AND formatting (replaces flake8 + black + isort). Consider pydantic for runtime validation.

### Go
```yaml
linters:
  enable:
    - govet
    - errcheck
    - staticcheck
    - unused
    - gosimple
    - ineffassign
    - gocritic
```

Go's type system is already strong. Focus custom rules on error handling, interface compliance, and package dependency direction.

### Rust
```toml
[lints.clippy]
pedantic = "warn"
nursery = "warn"
unwrap_used = "deny"
expect_used = "deny"
```

Rust's compiler enforces most safety. Add clippy pedantic and deny unwrap/expect.

## Custom Lint Rules: The Teaching Pattern

Lint error messages ARE the remediation instructions:

```javascript
// Bad
"Import violation: cannot import from api layer"

// Good (teaching pattern)
`Architectural violation: ${file} imports from ${importedModule}.

REMEDIATION: The dependency direction is:
  Types -> Config -> Repo -> Service -> Runtime -> UI
Each layer may only import from layers to its left.

If you need shared logic, move it to src/shared/ or src/types/.
See docs/architecture.md for the full dependency graph.`
```

The detailed message becomes part of the agent's context, teaching it how to fix the issue.

## Pre-Commit Hook Pattern

```bash
#!/bin/bash
# Succeed silently, fail verbosely

npx biome format --write . > /dev/null 2>&1

LINT_OUTPUT=$(npx eslint --quiet . 2>&1)
if [ $? -ne 0 ]; then
  echo "$LINT_OUTPUT"
  exit 1
fi

TYPE_OUTPUT=$(npx tsc --noEmit 2>&1)
if [ $? -ne 0 ]; then
  echo "$TYPE_OUTPUT"
  exit 1
fi
```

## Common Agent Failure Patterns to Lint For

| Pattern | Lint Rule |
|---------|-----------|
| Cross-layer imports | Custom import restriction rule |
| Barrel exports (index.ts) | `no-restricted-exports` or custom |
| Console.log in production | `no-console` |
| Any type in TypeScript | `@typescript-eslint/no-explicit-any` |
| Unused variables | `no-unused-vars` / `F841` |
| Missing error handling | `@typescript-eslint/no-floating-promises` |
| Direct DB access from API | Custom import restriction |
| Hardcoded config values | Custom rule or manual review |
