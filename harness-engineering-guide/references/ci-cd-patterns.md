# CI/CD Patterns for AI-Assisted Development

## Standard Pipeline Structure

Every AI-assisted project needs these gates, in this order:

### Pre-Commit (local, fast)
```yaml
hooks:
  - format (Prettier/Black/gofmt)
  - lint (ESLint/Ruff/clippy)
  - typecheck (tsc/mypy)
  - secret detection (ggshield/gitleaks)
```
Target: under 10 seconds. Fast feedback is essential — if verification is slow, agents skip it.

### CI Pipeline (on every PR)
```yaml
stages:
  - lint        # Code style and custom rules
  - typecheck   # Type safety
  - test        # Unit + integration tests
  - build       # Compilation / bundling
  - security    # SAST/DAST scanning
  - coverage    # Threshold enforcement
```
Target: under 10 minutes total. All stages must pass before merge.

### Post-Merge (on main)
```yaml
stages:
  - e2e-tests       # Full end-to-end suite
  - deploy-staging   # Staging deployment
  - smoke-tests      # Post-deploy verification
  - deploy-prod      # Production (with approval gate)
```

## AI-Specific CI Additions

### Small Batch Enforcement
```yaml
- name: check-pr-size
  run: |
    ADDITIONS=$(gh pr view $PR_NUMBER --json additions -q '.additions')
    if [ "$ADDITIONS" -gt 500 ]; then
      echo "::error::PR too large ($ADDITIONS lines). Split into smaller PRs."
      exit 1
    fi
```

### Structural Tests (Architecture Enforcement)
```typescript
describe('Architecture', () => {
  it('services should not import from api layer', () => {
    const violations = findImports('src/services/**', 'src/api/**');
    expect(violations).toHaveLength(0);
  });

  it('repos should not import from services', () => {
    const violations = findImports('src/repos/**', 'src/services/**');
    expect(violations).toHaveLength(0);
  });
});
```

### Documentation Freshness
```yaml
- name: check-doc-freshness
  run: |
    STALE_DOCS=$(find docs/ -name "*.md" -mtime +30)
    if [ -n "$STALE_DOCS" ]; then
      echo "::warning::Stale documentation found:"
      echo "$STALE_DOCS"
    fi
```

### AI Commit Tagging
```yaml
- name: tag-ai-commits
  if: contains(github.event.head_commit.message, 'Co-Authored-By: Claude') ||
      contains(github.event.head_commit.message, 'AI-generated')
  run: echo "AI_GENERATED=true" >> $GITHUB_ENV
```

## Custom Linter Error Messages (The Teaching Pattern)

The most impactful harness technique from OpenAI: error messages that teach.

```javascript
module.exports = {
  create(context) {
    return {
      ImportDeclaration(node) {
        if (isViolation(node)) {
          context.report({
            node,
            message: `Architectural violation: ${source} cannot import from ${target}.

REMEDIATION: Move the shared logic to src/types/ or src/shared/.
The dependency direction is: Types -> Config -> Repo -> Service -> Runtime -> UI.
Each layer may only import from layers to its left.
See docs/architecture.md for details.`
          });
        }
      }
    };
  }
};
```

The remediation text becomes part of the agent's context when the linter fails, turning errors into teaching moments.

## Pipeline by Ecosystem

### JavaScript/TypeScript
```yaml
lint: npx eslint . && npx biome check .
typecheck: npx tsc --noEmit
test: npx vitest run --coverage
build: npx vite build
security: npx audit-ci --moderate
```

### Python
```yaml
lint: ruff check . && ruff format --check .
typecheck: mypy src/
test: pytest --cov=src --cov-fail-under=80
build: python -m build
security: pip-audit && bandit -r src/
```

### Go
```yaml
lint: golangci-lint run
typecheck: go vet ./...
test: go test -race -coverprofile=coverage.out ./...
build: go build ./...
security: gosec ./...
```

### Rust
```yaml
lint: cargo clippy -- -D warnings
typecheck: cargo check
test: cargo test
build: cargo build --release
security: cargo audit
```

## Hook Pattern for Agent Feedback

Succeed silently, fail verbosely:

```bash
#!/bin/bash
# Runs after agent edits code

OUTPUT=$(npx tsc --noEmit 2>&1)
if [ $? -ne 0 ]; then
  echo "TYPE ERROR: $OUTPUT"
  exit 1
fi
# Silent on success — don't flood agent context
```

Thousands of lines of passing output in agent context causes hallucinations and context pollution.
