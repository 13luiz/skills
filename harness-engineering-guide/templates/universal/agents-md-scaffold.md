# AGENTS.md

## Project Overview
[Project name] is a [brief description, 2-3 sentences]. Built with [tech stack].

## Quick Reference
- Language: [TypeScript/Python/Go/etc.]
- Package manager: [npm/pnpm/pip/uv/etc.]
- Build: `[build command]`
- Test: `[test command]`
- Lint: `[lint command]`
- Dev server: `[dev command]`

## Directory Structure
src/
├── [domain-a]/     # [Brief description]
├── [domain-b]/     # [Brief description]
├── shared/         # Shared utilities and types
└── index.ts        # Entry point
docs/
├── ARCHITECTURE.md # System architecture and boundaries
├── FRONTEND.md     # Frontend patterns and conventions
└── design-docs/    # Feature design documents
tests/
├── unit/
├── integration/
└── e2e/

## Architecture Rules
- Dependencies flow: Types → Config → Repo → Service → Runtime → UI
- Cross-cutting concerns enter through Providers only
- Never import from a higher layer into a lower layer
- See `docs/ARCHITECTURE.md` for the full dependency graph

## Key Conventions
- Use shared utilities from `src/shared/` — do not create one-off helpers
- Validate data at boundaries — never trust unvalidated shapes
- All new code must have tests. Run `[test command]` before PRs.
- See `docs/QUALITY_SCORE.md` for quality grades per module

## Boundaries
### Always Do
- Run tests before committing
- Check types before pushing
- Read existing code before modifying

### Ask First
- Adding new dependencies
- Changing public API signatures
- Modifying CI configuration

### Never Do
- Delete or skip failing tests
- Commit secrets or credentials
- Modify files outside task scope
- Force push to main

## Documentation
- Design decisions: `docs/design-docs/`
- Product specs: `docs/product-specs/`
- API references: `docs/references/`
- Active plans: `docs/exec-plans/active/`
