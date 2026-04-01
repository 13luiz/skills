# Monorepo Patterns for Harness Engineering

Monorepos introduce unique challenges for harness engineering: shared infrastructure must coexist with per-package autonomy, cross-package boundaries need enforcement, and audit scope explodes. This document provides patterns for auditing and designing harnesses in monorepo environments.

---

## Monorepo Detection

The audit script detects monorepos via these markers:

| Marker | Tool | Ecosystem |
|--------|------|-----------|
| `pnpm-workspace.yaml` | pnpm workspaces | Node.js |
| `lerna.json` | Lerna | Node.js |
| `nx.json` | Nx | Node.js (polyglot) |
| `turbo.json` | Turborepo | Node.js |
| `package.json` with `"workspaces"` | npm/Yarn workspaces | Node.js |
| `Cargo.toml` with `[workspace]` | Cargo workspace | Rust |
| `go.work` | Go workspaces | Go |

Package directories are discovered by scanning: `packages/`, `apps/`, `libs/`, `services/`, `modules/`, `crates/`, `internal/`, `cmd/`.

---

## Audit Architecture: Three Layers

A monorepo audit operates at three distinct layers:

### Layer 1: Shared Infrastructure (Root)

Audit the root-level harness that applies to all packages:

- **Root CI pipeline** — Does it run on every PR? Does it support affected-package-only execution?
- **Root linter/formatter config** — Is there a base config that packages extend?
- **Root AGENTS.md** — Does it describe the monorepo structure, package boundaries, and navigation?
- **Root docs/** — Is there top-level architecture documentation?
- **CODEOWNERS** — Are package-level ownership boundaries defined?
- **Workspace tooling** — Is there a task runner (Nx, Turborepo, Lerna) configured?

### Layer 2: Per-Package Audit

Each package is audited individually with its appropriate profile:

- A `packages/ui` frontend package uses the `frontend-spa` profile
- A `packages/api` backend package uses the `backend-api` profile
- A `packages/shared-utils` library uses the `library` profile
- A `packages/cli` tool uses the `cli-tool` profile

Per-package checks:
- Does the package have its own README or AGENTS.md?
- Does it extend or override root lint/type configs?
- Does it have its own test suite?
- Are its dependencies properly declared (no implicit reliance on hoisted deps)?

### Layer 3: Cross-Package Boundaries

The most monorepo-specific dimension — enforcing boundaries between packages:

- **Import rules** — Can package A import directly from package B's internals, or only from its public API?
- **Circular dependencies** — Are there circular dependency chains between packages?
- **Shared type contracts** — Do packages share types via a dedicated shared package?
- **Version consistency** — Do all packages use compatible versions of shared dependencies?

---

## Monorepo-Specific Checklist Items

These augment the standard 45 items:

### Cross-Package Boundary Enforcement (extends 2.5)
- PASS: Import rules between packages are mechanically enforced (e.g., Nx module boundaries, ESLint import restrictions, `depguard`)
- PARTIAL: Boundaries documented but not enforced
- FAIL: Packages freely import each other's internals

### Affected-Package CI (extends 2.1)
- PASS: CI runs only affected packages on PR (via Nx affected, Turborepo filtering, or path-based triggers)
- PARTIAL: CI runs all packages on every PR
- FAIL: No CI or CI doesn't understand package boundaries

### Root AGENTS.md Navigation (extends 1.1)
- PASS: Root AGENTS.md describes monorepo structure, package purposes, and navigation commands
- PARTIAL: Root AGENTS.md exists but doesn't cover monorepo navigation
- FAIL: No root agent instruction file

### Per-Package Documentation (extends 1.2)
- PASS: Each package has at minimum a README describing its purpose, API, and internal structure
- PARTIAL: Some packages documented, others not
- FAIL: No per-package documentation

### Shared Dependency Management (extends 2.7)
- PASS: Dependency versions managed centrally (catalog, constraints); no version drift across packages
- PARTIAL: Some central management but drift exists
- FAIL: Each package manages dependencies independently with no coordination

---

## CI Patterns for Monorepos

### Affected-Only Execution

The most impactful optimization: only run CI for packages affected by the change.

**Nx:**
```bash
npx nx affected --target=lint --base=origin/main
npx nx affected --target=test --base=origin/main
npx nx affected --target=build --base=origin/main
```

**Turborepo:**
```bash
npx turbo run lint test build --filter=...[origin/main]
```

**GitHub Actions path filters:**
```yaml
on:
  pull_request:
    paths:
      - 'packages/api/**'
jobs:
  test-api:
    runs-on: ubuntu-latest
    steps:
      - run: cd packages/api && npm test
```

**Cargo workspace:**
```bash
cargo test -p affected-crate
```

### Shared CI Steps

Some checks should always run regardless of affected packages:
- Root lint config validation
- Cross-package dependency graph analysis
- CODEOWNERS verification
- Root documentation freshness

---

## AGENTS.md for Monorepos

A monorepo AGENTS.md should follow a **hub-and-spoke** pattern:

```markdown
# AGENTS.md (root)

## Monorepo Structure
- `packages/api` — Backend API service (Python/FastAPI)
- `packages/web` — Frontend SPA (React/TypeScript)
- `packages/shared` — Shared types and utilities
- `packages/cli` — Developer CLI tool (TypeScript)

## Package Boundaries
- Packages communicate via shared types in `packages/shared`
- Direct imports between packages are forbidden (use published APIs)
- See `docs/ARCHITECTURE.md` for the dependency graph

## Commands
- `pnpm install` — Install all dependencies
- `pnpm -F api test` — Run tests for api package
- `pnpm -F web dev` — Start web dev server
- `nx affected --target=test` — Test affected packages only

## Per-Package Docs
Each package has its own README. Read the relevant one before working in that package.
```

Per-package AGENTS.md files (optional) extend the root with package-specific commands and conventions.

---

## Entropy Management in Monorepos

Monorepos accumulate entropy faster due to:

1. **Dead packages** — Packages that are no longer used but still exist
2. **Dependency drift** — Different packages using different versions of the same dependency
3. **Circular imports** — Gradual introduction of cycles between packages
4. **Config divergence** — Packages overriding root configs in incompatible ways
5. **Orphaned shared code** — Shared utilities that only one package uses

### Mitigation Patterns

- **Dependency graph validation in CI** — Fail if circular dependencies are introduced
- **Unused package detection** — Periodic scan for packages with no dependents
- **Version catalog enforcement** — Central version management with drift detection
- **Config inheritance audits** — Verify packages extend (not override) root configs
- **Shared code usage analysis** — Alert when shared code has only one consumer

---

## Scoring Adjustments for Monorepos

When using the `monorepo` profile from `data/profiles.json`:

- **Dim 2 (Mechanical): 22%** — Cross-package boundaries increase importance
- **Dim 5 (Context): 12%** — Navigation and cache-friendly design matter more
- **Dim 6 (Entropy): 12%** — Entropy accumulates faster in monorepos

The final score is calculated as:

```
aggregate_score = (infrastructure_layer_score * 0.3) + (average_package_score * 0.5) + (cross_package_score * 0.2)
```

This weights individual package health as the largest contributor while still accounting for shared infrastructure and cross-cutting concerns.

---

## Report Structure for Monorepos

```
reports/
└── 2026-03-31_project-name_monorepo/
    ├── aggregate.md        ← Overall score, infrastructure audit, cross-package findings
    ├── api.md              ← Per-package: backend-api profile
    ├── web.md              ← Per-package: frontend-spa profile
    ├── shared.md           ← Per-package: library profile
    └── cli.md              ← Per-package: cli-tool profile
```

The aggregate report should include:
1. Overall monorepo grade (weighted average)
2. Infrastructure layer findings
3. Cross-package boundary assessment
4. Per-package score summary table
5. Monorepo-specific improvement recommendations
