# Harness Engineering Audit: Cherry Studio v1.8.4

**Date**: 2026-04-01
**Profile**: client-app (desktop) | **Stage**: mature
**Ecosystem**: TypeScript/Node.js (Electron)
**Language**: English (en)

## Overall Grade: C+ (61.5/100)

## Executive Summary

Cherry Studio v1.8.4 is a well-engineered Electron desktop app with strong mechanical constraints (comprehensive CI, multi-linter enforcement, TypeScript type checking) and excellent observability (Winston structured logging, OpenTelemetry tracing, Playwright UI automation). However, testing enforcement has critical gaps — coverage thresholds are absent, E2E tests are not CI-gated, and adversarial verification does not exist. Entropy management and long-running task support remain immature, with no quality tracking, no durable execution, and no init script for environment recovery.

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | client-app (desktop) — dim4 weight increased to 0.20, dim3 reduced to 0.10 |
| Stage | mature — 44 of 45 items active (3.2 skipped per client-app profile) |
| Language | English (en) |
| Skipped Items | 3.2 (Metrics & Tracing) — substituted: OTel present, evaluated under other items |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs | 5 | 3.0/5 | 60.0% | 15% | 9.00 | Goal State |
| 2 | Mechanical Constraints | 7 | 5.0/7 | 71.4% | 20% | 14.29 | Actuator |
| 3 | Feedback & Observability | 4 | 3.0/4 | 75.0% | 10% | 7.50 | Sensor |
| 4 | Testing & Verification | 7 | 3.5/7 | 50.0% | 20% | 10.00 | Sensor+Actuator |
| 5 | Context Engineering | 5 | 3.5/5 | 70.0% | 10% | 7.00 | Goal State |
| 6 | Entropy Management | 4 | 2.0/4 | 50.0% | 10% | 5.00 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 3.0/6 | 50.0% | 10% | 5.00 | Feedback Loop |
| 8 | Safety Rails | 6 | 4.5/6 | 75.0% | 5% | 3.75 | Actuator (Protective) |
| **Total** | | **44** | **27.5/44** | | **61.54** | |

**Grade: C+ (61.5/100)**

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (60.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 1.1 | Agent Instruction File | **PARTIAL** (0.5) | `AGENTS.md` is a 1-line pointer to `CLAUDE.md` (320 lines). Comprehensive content covering architecture, commands, conventions, security. Exceeds client-app threshold (~100); within extended PARTIAL range given 5 workspace packages. |
| 1.2 | Structured Knowledge | **PASS** (1.0) | `docs/` with bilingual structure: `docs/en/` (guides + references) and `docs/zh/` (parallel). 31 md files across 3+ subdirs. `docs/README.md` serves as index. |
| 1.3 | Architecture Docs | **PARTIAL** (0.5) | No standalone `ARCHITECTURE.md`. Architecture thoroughly documented in `CLAUDE.md` § "Project Architecture" with process boundaries, service tables, path aliases, Redux slices, IPC model. Scattered across agent instruction file rather than a dedicated architecture document. |
| 1.4 | Progressive Disclosure | **PARTIAL** (0.5) | `AGENTS.md` → `CLAUDE.md` pointer pattern is good. `CLAUDE.md` structured with clear headers and deep links. `.agents/skills/` provides deeper topic docs. But `CLAUDE.md` at 320 lines is heavy as an entry point. |
| 1.5 | Versioned Knowledge | **PARTIAL** (0.5) | No ADR folder or formal design docs directory. Changesets track versioned releases. `CLAUDE.md` documents v2 blocked areas and contribution restrictions. `docs/en/guides/branching-strategy.md` documents git flow. Not formal ADRs but some versioned decision context. |

### 2. Mechanical Constraints (71.4%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 2.1 | CI Pipeline Blocks | **PASS** [exemplary] (1.0) | 17 workflow files. `ci.yml`: `basic-checks` (lint, format, typecheck, i18n, OpenAPI, skills), `general-test` + `render-test` (split by process), path-filter change detection (`dorny/paths-filter@v3`), Feishu failure notification. `permissions: contents: read`. |
| 2.2 | Linter Enforcement | **PASS** [exemplary] (1.0) | `pnpm test:lint` in CI runs `oxlint --deny-warnings` + ESLint. `console.*` restricted as **error** in CI (`process.env.CI ? 'error' : 'warn'`). React hooks, import sorting, unused imports enforced. Custom i18n template literal rule. |
| 2.3 | Formatter Enforcement | **PASS** (1.0) | `pnpm format:check` in CI basic-checks. Biome handles formatting (2-space indent, single quotes, line width 120). `.editorconfig` for editor consistency. |
| 2.4 | Type Safety | **PASS** (1.0) | `pnpm typecheck` in CI runs concurrent `tsgo` (node + web). Extends `@electron-toolkit/tsconfig` presets. `CLAUDE.md` states "Strict mode enabled". Note: `tsconfig.json` has typo key `"tsDecorders"`. |
| 2.5 | Dependency Direction | **PARTIAL** (0.5) | Separate `tsconfig.node.json` / `tsconfig.web.json` enforce process boundary via type system. Path aliases (`@main`, `@renderer`, `@shared`) define clear module boundaries. Electron's `contextBridge` enforces IPC boundary. But no custom lint rules preventing cross-process imports. |
| 2.6 | Remediation Errors | **PARTIAL** (0.5) | `console.*` restriction includes bilingual fix message pointing to logging docs. i18n template literal rule has explanatory message. Not all lint rules include fix recipes; `no-explicit-any: off` leaves a gap. |
| 2.7 | Structural Conventions | **PASS** (1.0) | `simple-import-sort` enforced (error). `unused-imports/no-unused-imports: error`. `i18n:hardcoded:strict` in CI. `openapi:check` validates API spec. `skills:check` validates agent skills. File naming conventions documented in `CLAUDE.md`. |

### 3. Feedback Loops & Observability (75.0%)

*Item 3.2 (Metrics & Tracing) skipped per client-app profile. Note: OpenTelemetry IS present via `packages/mcp-trace/`, `NodeTraceService`, and `tracedInvoke()` in preload for IPC tracing.*

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 3.1 | Structured Logging | **PASS** [exemplary] (1.0) | Winston + `winston-daily-rotate-file` in `src/main/services/LoggerService.ts`. Renderer has IPC-bridged `LoggerService`. `loggerService.withContext("moduleName")` pattern. `console.*` usage blocked as error in CI. Logging guide at `docs/en/guides/logging.md`. |
| 3.3 | Agent-Queryable Obs | **PARTIAL** (0.5) | `pnpm debug` with `chrome://inspect` on port 9222. OTel trace viewer window (`traceWindow.html`). `CLAUDE.md` documents `gh pr checks` and `gh run view --log-failed` for CI inspection. No CLI-based log query tool. |
| 3.4 | UI Visibility | **PASS** (1.0) | `playwright.config.ts` with Electron E2E configuration. Page-object fixtures in `tests/e2e/`. Trace, screenshot, and video collection on failure. (Critical item for client-app profile.) |
| 3.5 | Diagnostic Error Ctx | **PARTIAL** (0.5) | Custom error hierarchy: `AiCoreError` (code, context, cause, `toJSON()`), `ProviderError`, `HubProviderError`, `AgentModelValidationError`, `CopilotServiceError`. 20 custom error files detected. But mixed patterns across the codebase; not all errors include suggested fixes. |

### 4. Testing & Verification (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 4.1 | Test Suite | **PASS** [exemplary] (1.0) | 5-project Vitest setup: main (node), renderer (jsdom), aiCore, shared, scripts. 106 test files across 20 test directories. Playwright E2E scaffold with page objects and fixtures. Colocated `__tests__/` directories. |
| 4.2 | Tests CI Blocking | **PASS** [exemplary] (1.0) | CI `general-test` runs `test:main`, `test:aicore`, `test:shared`, `test:scripts`. `render-test` runs `test:renderer`. Both with path-filter change detection. Non-zero exit blocks merge. |
| 4.3 | Coverage Thresholds | **PARTIAL** (0.5) | `vitest.config.ts` configures v8 coverage with reporters (`text`, `json`, `html`, `lcov`, `text-summary`) and detailed exclude patterns. `pnpm test:coverage` exists. But **no `thresholds` property** configured and CI does not run coverage. Infrastructure present; enforcement absent. |
| 4.4 | Formalized Done | **FAIL** (0.0) | `CLAUDE.md` states "Features without tests are not considered complete". Changeset requirement for PRs. PR description check workflow. But no machine-readable feature registry with pass/fail tracking. |
| 4.5 | E2E Verification | **PARTIAL** (0.5) | Playwright configured: `tests/e2e/specs/`, page objects, global setup/teardown, trace/screenshot/video on failure. `pnpm test:e2e` works locally. **Not in CI merge path** — `ci.yml` does not run E2E. (Critical item for client-app profile.) |
| 4.6 | Flake Management | **PARTIAL** (0.5) | Playwright: `retries: process.env.CI ? 2 : 0`, `forbidOnly: !!process.env.CI`, `workers: 1` for Electron stability. Vitest thread pool with configurable `singleThread`. No dedicated flake quarantine manifest. |
| 4.7 | Adversarial Verification | **FAIL** (0.0) | `claude-code-review.yml` runs Anthropic Claude on PR diffs — automated code review but not structured adversarial verification with evidence format. No independent verifier that attempts to break implementations. |

### 5. Context Engineering (70.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 5.1 | Externalized Knowledge | **PASS** (1.0) | Architecture, IPC channels, contribution restrictions, v2 blocked areas, conventions all documented in-repo. Bilingual docs. `.agents/skills/` with PR creation, issue creation skills. |
| 5.2 | Doc Freshness | **PARTIAL** (0.5) | CI runs `i18n:check`, `openapi:check`, `skills:check` for specific doc types. Doc drift present: `CLAUDE.md` states "Electron 38" but `package.json` has Electron 40.8.0; "Node ≥22" vs `engines: ≥24.11.1`. No general markdownlint or doc freshness check. |
| 5.3 | Machine-Readable Refs | **PARTIAL** (0.5) | No `llms.txt` file. `CLAUDE.md` and structured `docs/` serve as agent references. `packages/shared/IpcChannel.ts` enum is machine-readable channel registry. Not in standard llms.txt format. |
| 5.4 | Tech Composability | **PASS** (1.0) | Mainstream stack: Electron, React 19, TypeScript, Redux Toolkit, Vitest, Playwright, Winston, Ant Design, TailwindCSS. Vercel AI SDK v5. Well-known, stable technologies. |
| 5.5 | Cache-Friendly Design | **PARTIAL** (0.5) | `CLAUDE.md` at 320 lines — exceeds default PASS threshold (~100-150). `.agents/skills/` provides deeper context. `AGENTS.md` as 1-line pointer is cache-friendly. Effective agent entry point is still the full 320-line `CLAUDE.md`. |

### 6. Entropy Management & Garbage Collection (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 6.1 | Golden Principles | **PASS** (1.0) | `CLAUDE.md` § "Guiding Principles (MUST FOLLOW)" with 9 explicit principles. Conventions for TypeScript, code style, file naming, i18n, testing all documented. 7 principle references detected by scanner. |
| 6.2 | Recurring Cleanup | **PARTIAL** (0.5) | `.github/dependabot.yml` for GitHub Actions (monthly, grouped). `.git-blame-ignore-revs` for formatting commits. No npm ecosystem in Dependabot. No stale issue/PR bot. |
| 6.3 | Tech Debt Tracking | **FAIL** (0.0) | ~54 files with TODO, ~37 with FIXME, ~20 with HACK/WORKAROUND markers. No `QUALITY_SCORE.md`, no `tech-debt-tracker.json`, no quality dashboard. Debt is marked but not systematically tracked. |
| 6.4 | AI Slop Detection | **PARTIAL** (0.5) | `unused-imports/no-unused-imports: error`. `oxlint --deny-warnings`. But `no-explicit-any: off`. No AI-slop-specific rules targeting duplicate utilities, over-abstraction, or dead code beyond unused imports. |

### 7. Long-Running Task Support (50.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 7.1 | Task Decomposition | **PARTIAL** (0.5) | `.agents/skills/` with PR and issue creation skills. `CLAUDE.md` documents workflows. No formal task decomposition template or execution plan format. |
| 7.2 | Progress Tracking | **PARTIAL** (0.5) | Changeset workflow tracks release progress. PR description check ensures context. Conventional commits provide history. No dedicated PROGRESS.md or structured session handoff file. |
| 7.3 | Handoff Bridges | **PARTIAL** (0.5) | Conventional commit requirement with `--signoff`. Changeset requirement for PRs. `pr-description-check.yml` workflow. No explicit multi-agent handoff rules or progress log format. |
| 7.4 | Environment Recovery | **PARTIAL** (0.5) | `.node-version` file for Node version. `pnpm install` documented. `docs/en/guides/development.md` describes setup. No single `init.sh` with health checks, no Docker/devcontainer. |
| 7.5 | Clean State Discipline | **PASS** (1.0) | `CLAUDE.md`: "Lint, test, and format before completion". `pnpm build:check` required before commits. Conventional commit messages. CI enforces quality gates. |
| 7.6 | Durable Execution | **FAIL** (0.0) | No checkpoint files, no recovery scripts. No agent session persistence mechanism. |

### 8. Safety Rails (75.0%)

| ID | Item | Score | Evidence |
|----|------|-------|----------|
| 8.1 | Least-Privilege Creds | **PASS** (1.0) | CI `permissions: contents: read`. GitHub App tokens for specific workflows. Release secrets properly injected via `secrets.*`. |
| 8.2 | Audit Logging | **PARTIAL** (0.5) | `claude-code-review.yml` for automated PR review. `issue-management.yml` and `github-issue-tracker.yml` for issue tracking. No unified audit log specification. |
| 8.3 | Rollback Capability | **PARTIAL** (0.5) | `electron-updater` (`AppUpdater` service) for auto-updates. `app-upgrade-config.json` protected via CODEOWNERS. No documented rollback playbook or version pinning guide. |
| 8.4 | Human Confirmation | **PASS** (1.0) | `CLAUDE.md`: "Always propose before executing". v2 blocked areas with explicit restrictions. PR workflow requires review. |
| 8.5 | Security Path Marking | **PASS** (1.0) | `.github/CODEOWNERS` covering: `store/`, `databases/`, `ConfigManager.ts`, `IpcChannel.ts`, `ipc.ts`, `app-upgrade-config.json`. Critical Electron IPC paths protected. |
| 8.6 | Tool Protocol Trust | **PARTIAL** (0.5) | Security practices in `CLAUDE.md`: `contextBridge` enforcement, IPC input validation, URL sanitization, IP validation, `express-validator`. MCP SDK in use. No formal threat model document. |

## Anti-Patterns Identified

- **CLAUDE.md exceeds conciseness threshold**: 320 lines mixing architecture map, conventions, command reference, testing guidelines, security notes, and v2 restrictions. Exceeds client-app threshold. Impacts items 1.1, 1.4, 5.5.
- **Coverage infrastructure without enforcement**: `vitest.config.ts` configures v8 coverage with reporters but no thresholds set. CI never runs coverage. Thresholds can drift silently.
- **E2E split from merge path**: Playwright E2E configured with page objects and trace collection, but `ci.yml` does not include `pnpm test:e2e`. High-value desktop flows may regress.
- **Doc drift**: `CLAUDE.md` cites "Electron 38" / "Node ≥22" while `package.json` has `electron: 40.8.0` / `engines.node: ≥24.11.1`. Stale doc references (`docs/technical/` path referenced in code doesn't exist).
- **no-explicit-any disabled**: `@typescript-eslint/no-explicit-any: off` in ESLint allows unchecked `any` types, weakening the strict TypeScript value proposition.

## Improvement Roadmap

### Quick Wins (implement in 1 day)
1. **Add coverage thresholds to `vitest.config.ts`** and wire `pnpm test:coverage` into CI. Set initial threshold at 50% and increment quarterly.
2. **Add `pnpm test:e2e` to CI** as a required check (at least smoke tests). The Playwright config already handles CI detection for retries.
3. **Create `llms.txt`** with curated entry points to CLAUDE.md, docs index, and key source directories.
4. **Enable `no-explicit-any`** at `warn` level first, then escalate to `error` after cleanup.
5. **Fix doc drift**: Update Electron and Node version references in `CLAUDE.md` to match `package.json`.

### Strategic Investments (1-4 weeks)
1. **Refactor `CLAUDE.md`** to ~150 lines by moving architecture details to `ARCHITECTURE.md`, testing guidelines to `docs/en/guides/testing.md`, and conventions to `docs/en/guides/conventions.md`.
2. **Add dependency direction lint rules**: Custom ESLint rule preventing `src/renderer/` from importing `src/main/` or vice versa. Enforce the Electron process boundary mechanically.
3. **Create formal ADR directory** (`docs/adr/`) and document the v2 refactoring decision, aiCore migration strategy, and other architectural decisions.
4. **Implement tech debt tracking**: Add `QUALITY_SCORE.md` or `tech-debt-tracker.json` aggregating TODO/FIXME counts per module.
5. **Add init script with health checks**: `scripts/init-dev.sh` that checks Node version, installs deps, validates environment, and runs a quick smoke test.
6. **Implement adversarial verification**: Extend `claude-code-review.yml` with structured verification format, or add a separate workflow that attempts to break new features.

## Recommended Templates

- `templates/universal/agents-md-scaffold.md` — restructure oversized CLAUDE.md
- `templates/ci/github-actions/standard-pipeline.yml` — add E2E and coverage CI jobs
- `templates/universal/verification-report-format.md` — adversarial verification format
- `templates/universal/tech-debt-tracker.json` — quality tracking per module
- `templates/init/init.sh` — environment bootstrap with health checks
