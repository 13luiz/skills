# Harness Engineering Audit: OpenClaw

**Date**: 2026-04-01
**Profile**: Monorepo | **Stage**: Mature (50k+ LOC)
**Ecosystem**: Node.js / TypeScript (pnpm workspace)
**Language**: English (en)

## Overall Grade: B (70.6/100)

## Executive Summary

OpenClaw demonstrates a **strong mechanical constraint layer** — CI, linting, formatting, type safety, and dependency boundary enforcement are all exemplary and well-integrated. Testing is multi-layered and comprehensive. However, **feedback loops for long-running agent tasks are underdeveloped** (no progress tracking, no durable execution, no environment recovery script), and **context engineering has gaps** (no `llms.txt`, no machine-readable references). Addressing the long-running task dimension and adding structured agent context artifacts would elevate this from a B to an A-grade harness.

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | Monorepo — weights adjusted (dim2=22%, dim5=12%, dim6=12%) |
| Stage | Mature — 45 of 45 items active |
| Language | English (en) |
| Skipped Items | None (all 45 active for Mature stage) |
| Critical Items (profile) | 2.5 Dependency Direction, 2.7 Structural Conventions, 5.5 Cache-Friendly Design, 6.2 Recurring Cleanup |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs & Knowledge | 5 | 4.5/5 | 90.0% | 13% | 11.70 | Goal State |
| 2 | Mechanical Constraints | 7 | 6.5/7 | 92.9% | 22% | 20.43 | Actuator |
| 3 | Feedback & Observability | 5 | 3.0/5 | 60.0% | 13% | 7.80 | Sensor |
| 4 | Testing & Verification | 7 | 5.0/7 | 71.4% | 13% | 9.29 | Sensor+Actuator |
| 5 | Context Engineering | 5 | 2.5/5 | 50.0% | 12% | 6.00 | Goal State |
| 6 | Entropy Management | 4 | 2.5/4 | 62.5% | 12% | 7.50 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 2.0/6 | 33.3% | 10% | 3.33 | Feedback Loop |
| 8 | Safety Rails | 6 | 5.5/6 | 91.7% | 5% | 4.58 | Actuator (Protective) |
| **Total** | | **45** | **31.5/45** | | **100%** | **70.63** | |

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (90.0%)

| Item | Score | Evidence |
|------|-------|---------|
| **1.1** Agent Instruction File | **PASS** [advanced] | Root `AGENTS.md` (285 lines) within monorepo cap (300). Acts as a comprehensive map: project structure, architecture boundaries, build/test/dev commands, coding style, security paths. `CLAUDE.md` exists as a pointer. Copilot instructions at `.github/instructions/copilot.instructions.md`. |
| **1.2** Structured Knowledge Base | **PASS** [advanced] | `docs/` directory with Mintlify-powered structure: `concepts/`, `install/`, `gateway/`, `plugins/`, `reference/`, `zh-CN/` mirror. `docs/docs.json` serves as index. Generated baselines under `docs/.generated/`. CI enforces doc quality via `check-docs` job. |
| **1.3** Architecture Documentation | **PASS** | `docs/concepts/architecture.md` describes WebSocket gateway architecture, components, client flows. `docs/plugins/architecture.md` covers plugin system. No root `ARCHITECTURE.md` but content is well-placed in docs hierarchy. |
| **1.4** Progressive Disclosure | **PASS** [advanced] | Root `AGENTS.md` is a concise TOC pointing to deeper docs. 10 sub-`AGENTS.md` files in domain-specific directories (`src/plugin-sdk/`, `extensions/`, `src/channels/`, `src/gateway/protocol/`, etc.) with 20-150 lines each. Clear navigation from general to specific. |
| **1.5** Versioned Knowledge Artifacts | **PARTIAL** | Design docs and architecture docs live in-repo (`docs/`). No formal ADR (Architecture Decision Record) directory. Some design rationale captured in code comments and AGENTS.md but not in dedicated decision log format. |

### 2. Mechanical Constraints (92.9%)

| Item | Score | Evidence |
|------|-------|---------|
| **2.1** CI Pipeline Blocks | **PASS** [exemplary] | `.github/workflows/ci.yml` (~1000 lines) runs on all PRs (non-draft). Dynamic matrix via `preflight` job + `ci-write-manifest-outputs.mjs`. Required check names computed programmatically (`planner.mjs`). Merge script (`scripts/pr-lib/merge.sh`) enforces `gh pr checks --required`. Concurrency groups cancel stale runs. |
| **2.2** Linter Enforcement | **PASS** [exemplary] | oxlint with type-aware mode, `.oxlintrc.json` committed (plugins: unicorn, typescript, oxc; categories: correctness, perf, suspicious = error). Runs in `pnpm check` (CI) and pre-commit hook. `check-additional` job runs domain-specific lint scripts. `no-explicit-any: error`. |
| **2.3** Formatter Enforcement | **PASS** [advanced] | oxfmt in CI (`pnpm format` check) and pre-commit. SwiftFormat + SwiftLint for Swift. markdownlint-cli2 for docs. Multi-language formatting coverage. |
| **2.4** Type Safety | **PASS** [exemplary] | `tsconfig.json` with `"strict": true`, target ES2023, NodeNext module resolution. `pnpm tsgo` (TypeScript native preview) in `pnpm check`. CI runs type checking. `noEmitOnError: true`. |
| **2.5** Dependency Direction Rules | **PASS** [exemplary] | Custom boundary enforcement scripts: `check-plugin-extension-import-boundary.mjs`, `task-registry-import-boundary.test.ts`. CI `check-additional` job enforces: `lint:webhook:no-low-level-body-read`, `lint:auth:no-pairing-store-group`, `lint:auth:pairing-account-scope`, `lint:ui:no-raw-window-open`. Violations aggregated and fail the job. |
| **2.6** Remediation-Aware Errors | **PARTIAL** | AGENTS.md defines gate terminology and expected commands. Custom lint scripts have descriptive names. However, error messages from oxlint and boundary checks do not systematically include agent-targeted fix instructions (e.g., "You imported X from Y. Instead, use Z"). |
| **2.7** Structural Conventions | **PASS** [advanced] | `check:no-conflict-markers`, `check:host-env-policy:swift`, jscpd duplicate detection (`--min-lines 12 --min-tokens 80`), knip dead code detection (`deadcode:knip`, `deadcode:ci`), extension naming conventions enforced via lint. 4+ conventions mechanically checked. |

### 3. Feedback Loops & Observability (60.0%)

| Item | Score | Evidence |
|------|-------|---------|
| **3.1** Structured Logging | **PASS** [advanced] | `tslog` library with child loggers per subsystem (canvas, discovery, tailscale, channels, health, cron, reload, hooks, plugins, ws, secrets). `PinoLikeLogger` type for consistent API. File and console transports. |
| **3.2** Metrics and Tracing | **PASS** [advanced] | `extensions/diagnostics-otel/` implements full OpenTelemetry stack: `@opentelemetry/sdk-node`, trace/metric/log exporters (OTLP proto), `ParentBasedSampler`, `TraceIdRatioBasedSampler`. Config surface via `diagnostics.otel.*`. |
| **3.3** Agent-Queryable Observability | **PARTIAL** | Logs are file-based (agents can read them). OTel exports to external collectors. No dedicated CLI command for agents to query logs/metrics/traces directly. Agents must access log files or external dashboards. |
| **3.4** UI Visibility for Agents | **PARTIAL** | Vitest browser testing configured (`@vitest/browser-playwright`, Chromium, headless) for UI tests. Agents can run these tests. However, no dedicated agent screenshot/inspect workflow for ad-hoc UI verification during coding sessions. |
| **3.5** Diagnostic Error Context | **PARTIAL** | Config audit records include rich context (timestamp, source, event, result, configPath, pid, ppid, cwd, argv). Child loggers provide subsystem context. However, errors do not systematically include suggested fixes or diagnostic guidance for agents. |

### 4. Testing & Verification (71.4%)

| Item | Score | Evidence |
|------|-------|---------|
| **4.1** Test Suite | **PASS** [exemplary] | 8+ Vitest configurations: default, unit, e2e, contracts, channels, extensions, gateway, live. UI browser tests via Vitest + Playwright. Integration tests (19+ files). Swift tests (XCTest). Android JUnit tests. Python pytest for skills. |
| **4.2** Tests in CI and Block | **PASS** [exemplary] | Tests run in multiple CI jobs (`checks`, `checks-fast`, `check-additional`, `skills-python`, `checks-windows`, `macos-swift`, `android`). Required check names managed via `planner.mjs`. Merge gated on `gh pr checks --required`. |
| **4.3** Coverage Thresholds | **PASS** [advanced] | `vitest.config.ts`: lines 70%, functions 70%, statements 70%, branches 55%. V8 provider with lcov reporter. `pnpm test:coverage` command. Note: AGENTS.md states 70% branches but config has 55%. |
| **4.4** Formalized Done Criteria | **PARTIAL** | `requiredCheckNames` in `planner.mjs` is machine-readable CI gate list. PR template defines structured scope (problem, why it matters, what changed, what did NOT change). However, no feature-level acceptance criteria file (DONE.json/YAML). |
| **4.5** E2E Verification | **PASS** [advanced] | `vitest.e2e.config.ts` + `*.e2e.test.ts` files. Shell/Docker E2E scripts under `scripts/e2e/`. UI browser tests with Playwright. Sandbox Dockerfiles for isolated E2E. CI runs E2E on multiple platforms. |
| **4.6** Test Flake Management | **PARTIAL** | Swift build/test retries (3 attempts with backoff). Windows CI worker=1 tuning. `OPENCLAW_TEST_ISOLATE=1` for channels. Gateway test helpers document avoiding flaky patterns. However, no formal quarantine system, no flaky test dashboard, no retry framework for JS tests. |
| **4.7** Adversarial Verification | **FAIL** | `security-fast` job runs detect-private-key, zizmor, pnpm-audit-prod. These are security scans, not adversarial verification (no independent verifier with permission isolation, no structured evidence reports, no adversarial probes targeting boundary values/concurrency/idempotency). |

### 5. Context Engineering (50.0%)

| Item | Score | Evidence |
|------|-------|---------|
| **5.1** Externalized Knowledge | **PASS** | Key decisions documented in-repo: AGENTS.md (architecture boundaries, coding style), docs/ (architecture, gateway, plugins, security), PR template (structured scope), copilot instructions. No critical knowledge limited to chat/Slack. |
| **5.2** Documentation Freshness | **PARTIAL** | CI `check-docs` job validates formatting, links, i18n glossary. `stale.yml` manages stale issues/PRs. However, no doc expiry dates, no automated doc-gardening agent, no freshness TTL mechanism for documentation pages. |
| **5.3** Machine-Readable References | **FAIL** | No `llms.txt` file. No curated dependency reference snapshots. Copilot instructions exist but are minimal (20 lines). Agents must fetch external docs with no local guidance beyond inline code comments. |
| **5.4** Technology Composability | **PASS** | Node.js, TypeScript, Express, Hono, Vitest, Playwright, Zod, tslog — all well-documented, widely-known technologies. Some custom abstractions (plugin SDK, gateway protocol) but well-documented in-repo. |
| **5.5** Cache-Friendly Context Design | **PARTIAL** | Root AGENTS.md at 285 lines (under 300 monorepo cap). Sub-AGENTS.md files enable targeted loading. However, no structured state files (JSON/YAML) for agent tracking, no designated artifact directories for agent outputs, no cache-stability documentation. |

### 6. Entropy Management & Garbage Collection (62.5%)

| Item | Score | Evidence |
|------|-------|---------|
| **6.1** Codified Golden Principles | **PASS** | AGENTS.md codifies: architecture boundaries (plugin SDK exports only via barrel), coding style (oxlint rules, no explicit any), gate discipline (local/landing/CI), security rules (CODEOWNERS paths restricted). Referenced from agent instruction entry points. |
| **6.2** Recurring Cleanup | **PASS** [advanced] | jscpd for duplicate detection (`dup:check`), knip for dead code (`deadcode:knip`, `deadcode:ci`). dependabot for dependency updates (npm, GitHub Actions, Swift, Gradle, Docker). `stale.yml` bot for issue/PR hygiene. Systematic multi-tool cleanup. |
| **6.3** Tech Debt Tracking | **FAIL** | No quality scores, tech-debt-tracker, or similar maintained artifact. No evidence of TODO tracking beyond individual code comments. No tech debt dashboard or periodic quality assessment. |
| **6.4** AI Slop Detection | **PARTIAL** | jscpd catches duplicate utilities. knip catches dead code. These address common AI-generated patterns but are general-purpose tools, not specifically targeting AI slop patterns (over-abstraction, hallucinated imports, redundant wrappers). |

### 7. Long-Running Task Support (33.3%)

| Item | Score | Evidence |
|------|-------|---------|
| **7.1** Task Decomposition Strategy | **PARTIAL** | AGENTS.md defines three gate levels (local dev, landing, CI). PR template structures scope. But no execution plan templates, no sprint contract format, no documented strategy for breaking complex tasks into agent-sized chunks. |
| **7.2** Progress Tracking Artifacts | **FAIL** | No `progress.txt`, execution plan logs, or structured progress files found. Git commit messages serve as the only progress record between sessions. |
| **7.3** Handoff Bridges | **PARTIAL** | PR template includes summary, scope boundary, evidence sections for human handoffs. AGENTS.md provides orientation. However, no structured progress logs, no feature status tracking, no session-to-session handoff protocol. |
| **7.4** Environment Recovery | **PARTIAL** | No root `init.sh` or setup script. Docker setup scripts exist under `scripts/docker/`. README has install instructions. `pnpm install && pnpm build` recovers the build. But no health-check-on-start, no automated environment validation. |
| **7.5** Clean State Discipline | **PASS** | AGENTS.md explicitly defines landing gate: "broader bar before pushing main — `pnpm check`, `pnpm test`, and `pnpm build`". Pre-commit hook runs `pnpm check`. CI enforces clean state before merge. Documented expectation of clean, tested code. |
| **7.6** Durable Execution | **FAIL** | No structured checkpoint files (progress.json, execution plans). No recovery script. No documented recovery protocol for interrupted agent sessions. |

### 8. Safety Rails (91.7%)

| Item | Score | Evidence |
|------|-------|---------|
| **8.1** Least-Privilege Credentials | **PASS** [advanced] | CI `permissions: contents: read` as default. Dependabot uses scoped NPM token (`secrets.NPM_NPMJS_TOKEN`). Release workflows use GitHub Environments with scoped permissions. CODEOWNERS restricts security path changes. |
| **8.2** Audit Logging | **PASS** | `config-audit.jsonl` with structured records: timestamp, source, event, result, configPath, pid, ppid, cwd, argv. Append-only with `0o600` permissions. Command logger hook (`src/hooks/bundled/command-logger/`). |
| **8.3** Rollback Capability | **PASS** | Documented in `docs/install/updating.md`: pin npm version, pin git commit, `plugins.deny` for emergency plugin rollback. Not a single automated rollback script, but clear documented procedures. |
| **8.4** Human Confirmation Gates | **PASS** [advanced] | GitHub Environments (`npm-release`, `docker-release`) with approval gates on release workflows. Manual `workflow_dispatch` triggers for all release workflows. `approve_manual_backfill` job with explicit gating comment. |
| **8.5** Security-Critical Path Marking | **PASS** [advanced] | `.github/CODEOWNERS` (54 lines): secops review for `src/security/`, `src/secrets/`, workflows, `SECURITY.md`, `dependabot.yml`, `codeql/`. AGENTS.md warns: "Do not edit files covered by security-focused CODEOWNERS rules unless a listed owner explicitly asked." |
| **8.6** Tool Protocol Trust | **PARTIAL** | MCP integration exists in the product (`.mcp.json` bundles, secrets tests with `mcpServers`). AGENTS.md mentions restricted surfaces. However, no dedicated MCP scoping policy file for agent tool access, no explicit trust boundary documentation for agent-facing tools. |

## Improvement Roadmap

### Quick Wins (implement in 1 day)

1. **Add `llms.txt`** (fixes 5.3) — Create a root `llms.txt` with project description, key entry points, and links to documentation. Add curated reference snippets for key dependencies.
2. **Add `init.sh`** (fixes 7.4) — Create a root setup/recovery script that runs `pnpm install`, `pnpm build`, health checks, and validates the environment. Run automatically at session start.
3. **Add remediation hints to custom lint** (fixes 2.6) — Enhance `check-plugin-extension-import-boundary.mjs` and other custom lint scripts to include specific fix instructions in error messages (e.g., "Import `X` from `src/plugin-sdk/index.ts` instead of `src/plugins/internal/X`").
4. **Align coverage threshold** (documentation debt) — AGENTS.md states 70% branches but config has 55%. Reconcile to a single source of truth.

### Strategic Investments (1-4 weeks)

1. **Implement durable execution support** (fixes 7.2, 7.6) — Add execution plan templates, `progress.json` checkpoint files, and a recovery protocol. Document session handoff workflow in AGENTS.md.
2. **Add adversarial verification step** (fixes 4.7) — Create a CI job or agent workflow with read-only permissions that independently verifies implementations via structured evidence reports (command + output + verdict). Include adversarial probes for boundary values and concurrency.
3. **Implement tech debt tracking** (fixes 6.3) — Maintain a quality score artifact (e.g., `quality-report.json`) generated by CI. Track trends over time. Surface in docs.
4. **Add agent-queryable observability** (improves 3.3) — Create CLI commands for querying recent logs, metrics, and traces. Allow agents to inspect runtime state programmatically without external dashboards.
5. **Strengthen documentation freshness** (improves 5.2) — Add frontmatter `expires` dates to docs. Create a CI check that flags stale docs (e.g., >90 days since last update with no explicit renewal).

## Recommended Templates

Based on gaps found, the following templates from the harness engineering toolkit would be most valuable:

- **`templates/init/`** — Environment recovery script template (for 7.4)
- **`templates/universal/`** — Progress tracking and execution plan templates (for 7.2, 7.6)
- **`templates/linting/`** — Remediation-aware lint rule patterns (for 2.6)
