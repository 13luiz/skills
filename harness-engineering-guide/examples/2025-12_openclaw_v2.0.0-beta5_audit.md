# Harness Engineering Audit: OpenClaw v2.0.0-beta5

**Date**: 2025-12 (eval baseline)
**Profile**: monorepo | **Stage**: mature
**Ecosystem**: TypeScript/Node.js + Swift + Kotlin (multi-platform)
**Language**: English (en)

## Overall Grade: C+ (69.2/100)

## Executive Summary

OpenClaw v2.0.0-beta5 demonstrates a strong mechanical core with CI, linting (Biome + Oxlint), and TypeScript strict mode enforced on every PR. Architecture documentation is above average with a concise AGENTS.md (~67 lines, well under monorepo threshold) and structured docs/. Key gaps include missing E2E testing in CI, no dependency-direction enforcement, absent entropy management automation, and weak safety rails (no CODEOWNERS, no rollback playbook).

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | monorepo — weight adjustments: dim2 0.22, dim5/dim6 0.12 |
| Stage | mature — 45 of 45 items active |
| Language | English (en) |
| Skipped Items | None |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs | 5 | 4.0/5 | 80.0% | 13% | 10.40 | Goal State |
| 2 | Mechanical Constraints | 7 | 5.5/7 | 78.6% | 22% | 17.29 | Actuator |
| 3 | Feedback & Observability | 5 | 4.0/5 | 80.0% | 13% | 10.40 | Sensor |
| 4 | Testing & Verification | 7 | 4.0/7 | 57.1% | 13% | 7.43 | Sensor+Actuator |
| 5 | Context Engineering | 5 | 3.5/5 | 70.0% | 12% | 8.40 | Goal State |
| 6 | Entropy Management | 4 | 2.0/4 | 50.0% | 12% | 6.00 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 4.0/6 | 66.7% | 10% | 6.67 | Feedback Loop |
| 8 | Safety Rails | 6 | 2.0/6 | 33.3% | 5% | 1.67 | Actuator (Protective) |
| **Total** | | **45** | **29.0/45** | | **68.25** | |

**Grade: C+ (69.2/100)**

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (80.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 1.1 | Agent Instruction File | **PASS** (1.0) | `AGENTS.md` ~67 lines; `CLAUDE.md` is a pointer to `AGENTS.md`. Concise and agent-focused. |
| 1.2 | Structured Knowledge | **PASS** (1.0) | `docs/` with subdirs (`templates/`, `refactor/`, `mac/`, `research/`) and `docs/index.md` with frontmatter + overview. |
| 1.3 | Architecture Docs | **PASS** (1.0) | `docs/architecture.md` defines gateway boundaries, components, wire protocol, invariants. |
| 1.4 | Progressive Disclosure | **PARTIAL** (0.5) | `README.md` ~182 lines (>150); still links into `docs/index.md` and topic docs. |
| 1.5 | Versioned Knowledge | **PARTIAL** (0.5) | No `docs/adr/`; versioned design notes in `docs/architecture.md` (dated), `docs/refactor/*.md`. |

### 2. Mechanical Constraints (78.6%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 2.1 | CI Pipeline Blocks | **PASS** [exemplary] (1.0) | `.github/workflows/ci.yml` on `pull_request` + `push`; failing steps block green CI. |
| 2.2 | Linter Enforcement | **PASS** [exemplary] (1.0) | CI: `pnpm lint` → `biome check src test` + `oxlint` (package.json scripts). |
| 2.3 | Formatter Enforcement | **PASS** [exemplary] (1.0) | Formatting enforced via `biome check` inside `pnpm lint` (Biome formatter enabled in `biome.json`). |
| 2.4 | Type Safety | **PASS** [exemplary] (1.0) | `tsconfig.json`: `"strict": true`; CI runs `pnpm build` (`tsc -p tsconfig.json`). |
| 2.5 | Dependency Direction | **FAIL** (0.0) | No CI-enforced import-layer / dependency-direction rules. |
| 2.6 | Remediation Errors | **PARTIAL** (0.5) | `biome.json` uses `"recommended": true` only; no custom rules with fix hints. |
| 2.7 | Structural Conventions | **PASS** [basic] (1.0) | Two enforced lanes: Biome + Oxlint in `pnpm lint` on CI. |

### 3. Feedback Loops & Observability (80.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 3.1 | Structured Logging | **PASS** (1.0) | `src/logging.ts`: tslog, levels, JSON/pretty, child loggers; used across gateway/web. |
| 3.2 | Metrics & Tracing | **PARTIAL** (0.5) | Health surfaces (`/healthz`); `docs/architecture.md` mentions Prometheus as out-of-spec — no OTel/Prometheus dependency. |
| 3.3 | Agent-Queryable Obs | **PASS** (1.0) | Programmatic health/status via gateway protocol (`src/gateway/server.ts` health cache/broadcast). |
| 3.4 | UI Visibility | **PASS** (1.0) | `playwright-core` + browser session code; AI-oriented snapshot path (`pw-tools-core.ts`). |
| 3.5 | Diagnostic Error Ctx | **PARTIAL** (0.5) | Structured logs exist; not consistently "error + fix recipe" end-to-end. |

### 4. Testing & Verification (57.1%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 4.1 | Test Suite | **PASS** [exemplary] (1.0) | Large Vitest suite under `src/**/*.test.ts` (100+ files); native Swift/Android CI jobs. |
| 4.2 | Tests CI Blocking | **PASS** [exemplary] (1.0) | `pnpm test` in main CI job (standard required check). |
| 4.3 | Coverage Thresholds | **PARTIAL** (0.5) | `vitest.coverage.thresholds` (70%) configured but CI runs `pnpm test` without coverage gate. |
| 4.4 | Formalized Done | **PARTIAL** (0.5) | `CHANGELOG.md` (human); no machine-readable "done" manifest. |
| 4.5 | E2E Verification | **FAIL** (0.0) | No `*.e2e.test.ts` in tree; CI is unit/integration only. |
| 4.6 | Flake Management | **PARTIAL** (0.5) | Workflow retries (submodules, swift build/test); no quarantine/retry policy. |
| 4.7 | Adversarial Verification | **PARTIAL** (0.5) | `pnpm protocol:check` regenerates schema/Swift with `git diff --exit-code` — consistency check, not adversarial. |

### 5. Context Engineering (70.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 5.1 | Externalized Knowledge | **PASS** (1.0) | Security, architecture, onboarding, channels documented under `docs/`. |
| 5.2 | Doc Freshness | **PARTIAL** (0.5) | No doc freshness workflow under `.github/`. |
| 5.3 | Machine-Readable Refs | **FAIL** (0.0) | No `llms.txt` or equivalent curated machine index. |
| 5.4 | Tech Composability | **PASS** (1.0) | TypeScript/Node, Swift, Kotlin/Gradle — mainstream stack. |
| 5.5 | Cache-Friendly Design | **PASS** (1.0) | `AGENTS.md` ~67 lines, well under dynamic threshold (monorepo ~200); deeper context in `docs/` + templates. |

### 6. Entropy Management & Garbage Collection (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 6.1 | Golden Principles | **PASS** (1.0) | `AGENTS.md` encodes multi-agent rules, restart/handoff, platform caveats. |
| 6.2 | Recurring Cleanup | **FAIL** (0.0) | No scheduled/automated cleanup workflow (no Dependabot/Renovate/stale config). |
| 6.3 | Tech Debt Tracking | **PARTIAL** (0.5) | Process via issues/CHANGELOG; no dedicated debt/quality dashboard. |
| 6.4 | AI Slop Detection | **PARTIAL** (0.5) | `CONTRIBUTING.md` AI PR transparency checklist; no lint rules for AI-style patterns. |

### 7. Long-Running Task Support (66.7%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 7.1 | Task Decomposition | **PASS** (1.0) | `docs/templates/*`, wizard/onboarding docs, structured narrative. |
| 7.2 | Progress Tracking | **PARTIAL** (0.5) | Progress mainly via commits/PRs; no standard `PROGRESS.md`. |
| 7.3 | Handoff Bridges | **PASS** (1.0) | `AGENTS.md` covers handoff, restart flows, device checks, gateway lifecycle. |
| 7.4 | Environment Recovery | **PARTIAL** (0.5) | `README.md` quick start; no single init script with health verification. |
| 7.5 | Clean State Discipline | **PASS** (1.0) | Clean-state / branch / stash discipline documented in `AGENTS.md`. |
| 7.6 | Durable Execution | **FAIL** (0.0) | No checkpoint + recovery automation for long agent tasks. |

### 8. Safety Rails (33.3%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 8.1 | Least-Privilege Creds | **PARTIAL** (0.5) | Config/docs: allowlists, gateway token; full least-privilege depends on deployment. |
| 8.2 | Audit Logging | **PARTIAL** (0.5) | File logging (`/tmp/clawdis` per `logging.ts`); not a full audit log. |
| 8.3 | Rollback Capability | **FAIL** (0.0) | No rollback playbook doc found in-repo. |
| 8.4 | Human Confirmation | **PARTIAL** (0.5) | `docs/security.md` threat model + allowlists; destructive shell access still a risk. |
| 8.5 | Security Path Marking | **FAIL** (0.0) | No `CODEOWNERS`. |
| 8.6 | Tool Protocol Trust | **PARTIAL** (0.5) | MCP mentioned in skills/changelog; no central "untrusted tool output" policy. |

## Improvement Roadmap

### Quick Wins (implement in 1 day)
1. Add `CODEOWNERS` file marking security-sensitive paths with stricter review.
2. Add E2E test lane in CI (even a single smoke test).
3. Wire `vitest run --coverage` into CI to enforce the already-configured 70% threshold.
4. Add `.github/workflows/stale.yml` for automated issue/PR cleanup.

### Strategic Investments (1-4 weeks)
1. Implement dependency-direction lint rules (e.g., `eslint-plugin-boundaries` or custom Oxlint rules).
2. Create `llms.txt` or machine-readable reference index for agent consumption.
3. Add rollback playbook documentation.
4. Implement independent adversarial verification pipeline for critical changes.

## Recommended Templates
- `templates/universal/agents-md-scaffold.md` — maintain the already-good AGENTS.md format
- `templates/ci/github-actions/standard-pipeline.yml` — reference for adding E2E job
- `templates/universal/verification-report-format.md` — for adversarial verification
