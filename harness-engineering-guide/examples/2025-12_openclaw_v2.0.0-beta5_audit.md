# Harness Engineering Audit: OpenClaw v2.0.0-beta5

**Date**: 2025-12 (eval baseline)
**Profile**: monorepo | **Stage**: mature
**Ecosystem**: TypeScript/Node.js + Swift + Kotlin (multi-platform)
**Language**: English (en)

## Overall Grade: C (64.6/100)

## Executive Summary

OpenClaw v2.0.0-beta5 has a strong mechanical core with CI, dual linting (Biome + Oxlint), and TypeScript strict mode enforced on every PR. The `AGENTS.md` (~78 lines) is concise and well under the monorepo threshold. Key weaknesses include no E2E testing in CI, no dependency-direction enforcement, absent entropy management tooling, and weak safety rails (no CODEOWNERS, no rollback playbook). Observability is basic — tslog provides structured logging but no metrics/tracing infrastructure exists yet.

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | monorepo — weights: dim1 0.13, dim2 0.22, dim3 0.13, dim4 0.13, dim5 0.12, dim6 0.12, dim7 0.10, dim8 0.05 |
| Stage | mature — 45 of 45 items active |
| Language | English (en) |
| Skipped Items | None |
| Packages | 2 (root + ui) |
| AGENTS.md Threshold | 160 lines (150 + 5×2) |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs | 5 | 3.5/5 | 70.0% | 13% | 9.10 | Goal State |
| 2 | Mechanical Constraints | 7 | 5.0/7 | 71.4% | 22% | 15.71 | Actuator |
| 3 | Feedback & Observability | 5 | 3.5/5 | 70.0% | 13% | 9.10 | Sensor |
| 4 | Testing & Verification | 7 | 4.5/7 | 64.3% | 13% | 8.36 | Sensor+Actuator |
| 5 | Context Engineering | 5 | 3.0/5 | 60.0% | 12% | 7.20 | Goal State |
| 6 | Entropy Management | 4 | 2.0/4 | 50.0% | 12% | 6.00 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 4.0/6 | 66.7% | 10% | 6.67 | Feedback Loop |
| 8 | Safety Rails | 6 | 3.0/6 | 50.0% | 5% | 2.50 | Actuator (Protective) |
| **Total** | | **45** | **28.5/45** | | | **64.63** | |

**Grade: C (64.6/100)**

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (70.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 1.1 | Agent Instruction File | **PASS** (1.0) | `AGENTS.md` ~78 lines; `CLAUDE.md` is a pointer to `AGENTS.md`. Well under monorepo threshold (160 lines for 2 packages). |
| 1.2 | Structured Knowledge Base | **PASS** (1.0) | `docs/` with subdirs (`templates/`, `refactor/`, `ios/`, `research/`) and `docs/index.md` with frontmatter + overview. |
| 1.3 | Architecture Documentation | **PARTIAL** (0.5) | No standalone `ARCHITECTURE.md`; architecture covered in `docs/index.md` (diagram, network model) + `README.md`. Scattered across multiple files. |
| 1.4 | Progressive Disclosure | **PARTIAL** (0.5) | README → `docs/index.md`; docs use YAML `summary`/`read_when`. Root `AGENTS.md` lacks explicit TOC links to deeper docs. |
| 1.5 | Versioned Knowledge | **PARTIAL** (0.5) | No `docs/adr/` or ADR naming; versioned design notes in `docs/refactor/*.md` + `CHANGELOG.md`. |

### 2. Mechanical Constraints (71.4%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 2.1 | CI Pipeline Blocks | **PASS** [exemplary] (1.0) | `.github/workflows/ci.yml` on `pull_request` + `push`; Node job runs lint, test, build, protocol:check; macOS/Android jobs. |
| 2.2 | Linter Enforcement | **PASS** [exemplary] (1.0) | `pnpm lint` = `biome check src test` + `oxlint --type-aware`; runs in CI. |
| 2.3 | Formatter Enforcement | **PASS** (1.0) | Biome formatter via `biome check` inside `pnpm lint`; `format` / `lint:fix` scripts in `package.json`. |
| 2.4 | Type Safety | **PASS** [exemplary] (1.0) | `tsconfig.json`: `"strict": true`; CI `pnpm build` runs `tsc -p tsconfig.json`. |
| 2.5 | Dependency Direction | **FAIL** (0.0) | No dependency-cruiser, eslint-plugin-boundaries, or oxlint import-zone config. |
| 2.6 | Remediation Errors | **PARTIAL** (0.5) | Some remediation-style hints in docs (troubleshooting guides); not systematic across all lint/CI messages. |
| 2.7 | Structural Conventions | **PARTIAL** (0.5) | `scripts/committer`, AGENTS conventions; enforced via lint + convention, not dedicated structural tests. |

### 3. Feedback Loops & Observability (70.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 3.1 | Structured Logging | **PASS** (1.0) | `src/logging.ts`: tslog, structured fields, levels, rolling files, optional JSON console style. |
| 3.2 | Metrics & Tracing | **PARTIAL** (0.5) | Health surfaces (`/healthz`); `docs/architecture` mentions Prometheus as future direction — no OTel/Prometheus dependency yet. |
| 3.3 | Agent-Queryable Obs | **PARTIAL** (0.5) | File logs under `/tmp/clawdis`, child loggers by module; no metrics/OTEL query surface for agents. |
| 3.4 | UI Visibility | **PASS** (1.0) | `playwright-core`: `_snapshotForAI` in `src/browser/pw-tools-core.ts`; `ui` uses `@vitest/browser-playwright`. |
| 3.5 | Diagnostic Error Ctx | **PARTIAL** (0.5) | Structured logs exist; not consistently "error + fix recipe" end-to-end. |

### 4. Testing & Verification (64.3%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 4.1 | Test Suite | **PASS** [exemplary] (1.0) | ~128 `src/**/*.test.ts` files + tests under `test/`. |
| 4.2 | Tests CI Blocking | **PASS** (1.0) | CI blocks on `pnpm test` (Node job, required check). |
| 4.3 | Coverage Thresholds | **PARTIAL** (0.5) | `vitest.config.ts` defines ~70% coverage thresholds; CI runs `pnpm test` not `pnpm test:coverage`, so thresholds don't gate CI. |
| 4.4 | Formalized Done | **PARTIAL** (0.5) | `CONTRIBUTING.md` PR expectations, `scripts/release-check.ts`; no single machine-readable DoD. |
| 4.5 | E2E Verification | **PARTIAL** (0.5) | Large unit suite; no `*.e2e.test.ts` in repo; no full-stack e2e in default CI. |
| 4.6 | Flake Management | **PASS** (1.0) | CI retries submodule checkout & Swift build/test; `src/infra/retry.ts` + tests. |
| 4.7 | Adversarial Verification | **FAIL** (0.0) | No property-based/fuzz/adversarial test harness. `pnpm protocol:check` is a consistency check, not adversarial. |

### 5. Context Engineering (60.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 5.1 | Externalized Knowledge | **PASS** (1.0) | `docs/`, `skills/**`, templates. Key decisions documented in-repo. |
| 5.2 | Doc Freshness | **PARTIAL** (0.5) | `pnpm docs:list` / `scripts/docs-list.ts` checks doc front matter; no CI staleness job. |
| 5.3 | Machine-Readable Refs | **FAIL** (0.0) | No `llms.txt` or equivalent curated machine index. |
| 5.4 | Tech Composability | **PASS** (1.0) | Composable mainstream stack: gateway, providers (Telegram/Discord/Web), skills, Pi RPC. |
| 5.5 | Cache-Friendly Design | **PARTIAL** (0.5) | Docs `read_when` supports selective loading; no explicit cache/token budget strategy for agent context. |

### 6. Entropy Management & Garbage Collection (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 6.1 | Golden Principles | **PASS** (1.0) | `AGENTS.md` encodes multi-agent rules, restart/handoff protocols, platform caveats. |
| 6.2 | Recurring Cleanup | **PARTIAL** (0.5) | CHANGELOG, conventions; no scheduled cleanup workflow (no Dependabot/Renovate/stale config). |
| 6.3 | Tech Debt Tracking | **PARTIAL** (0.5) | Process via issues/CHANGELOG; no dedicated tech-debt/quality dashboard. |
| 6.4 | AI Slop Detection | **FAIL** (0.0) | No automated AI-slop checks; only human AI-assisted PR checklist in `CONTRIBUTING.md`. |

### 7. Long-Running Task Support (66.7%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 7.1 | Task Decomposition | **PASS** (1.0) | `docs/templates/*`, wizard/onboarding docs, structured narrative. |
| 7.2 | Progress Tracking | **PARTIAL** (0.5) | Progress mainly via commits/PRs; no standard `PROGRESS.md`. |
| 7.3 | Handoff Bridges | **PASS** (1.0) | `AGENTS.md` covers handoff, restart flows, device checks, gateway lifecycle. |
| 7.4 | Environment Recovery | **PARTIAL** (0.5) | `README.md` quick start; no single init script with health verification. |
| 7.5 | Clean State Discipline | **PASS** (1.0) | Clean-state / branch / stash discipline documented in `AGENTS.md`. |
| 7.6 | Durable Execution | **FAIL** (0.0) | No checkpoint + recovery automation for long agent tasks. |

### 8. Safety Rails (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 8.1 | Least-Privilege Creds | **PARTIAL** (0.5) | Config/docs: allowlists, gateway token; full least-privilege depends on deployment. |
| 8.2 | Audit Logging | **PARTIAL** (0.5) | File logging (`/tmp/clawdis` per `logging.ts`); not a full audit log. |
| 8.3 | Rollback Capability | **PARTIAL** (0.5) | Git/releases implied rollback; no documented rollback runbook. |
| 8.4 | Human Confirmation | **PASS** (1.0) | Interactive confirms: `promptYesNo` in `src/infra/tailscale.ts` (+ tests). |
| 8.5 | Security Path Marking | **FAIL** (0.0) | No `CODEOWNERS`. |
| 8.6 | Tool Protocol Trust | **PARTIAL** (0.5) | Loopback-first gateway, token for non-loopback bind; tool surface still broad by design. |

## Improvement Roadmap

### Quick Wins (implement in 1 day)
1. Add `CODEOWNERS` file marking security-sensitive paths with stricter review (8.5).
2. Wire `vitest run --coverage` into CI to enforce the already-configured 70% threshold (4.3).
3. Add `.github/workflows/stale.yml` for automated issue/PR cleanup (6.2).
4. Create standalone `ARCHITECTURE.md` consolidating existing architecture notes (1.3).

### Strategic Investments (1-4 weeks)
1. Add E2E test lane in CI — even a single smoke test would be a significant improvement (4.5).
2. Implement dependency-direction lint rules (e.g., `eslint-plugin-boundaries` or custom Oxlint rules) (2.5).
3. Create `llms.txt` or machine-readable reference index for agent consumption (5.3).
4. Add rollback playbook documentation (8.3).
5. Implement independent adversarial verification pipeline for critical changes (4.7).

## Recommended Templates
- `templates/universal/agents-md-scaffold.md` — maintain the already-good AGENTS.md format
- `templates/ci/github-actions/standard-pipeline.yml` — reference for adding E2E job
- `templates/ci/github-actions/doc-freshness.yml` — for doc staleness checks
- `templates/universal/tech-debt-tracker.json` — for structured tech debt tracking
