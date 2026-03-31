# Harness Engineering Audit: OpenClaw

**Date**: 2026-04-01
**Profile**: monorepo | **Stage**: mature (50k+ LOC, production product, 20+ maintainers)
**Ecosystem**: TypeScript (ESM) + pnpm workspaces + Swift (macOS/iOS) + Kotlin (Android)
**Repository**: https://github.com/openclaw/openclaw

## Overall Grade: A (85.8/100)

## Executive Summary

OpenClaw is one of the most harness-mature open-source repositories audited to date. It excels in mechanical constraints (Dim 2), architecture documentation (Dim 1), and feedback loops (Dim 3), featuring 14+ custom boundary lint rules, multi-platform CI covering Linux/macOS/Windows, 70% coverage thresholds, and a meticulously designed progressive knowledge disclosure system. The primary improvement opportunities are: **AGENTS.md is too long** (286 lines vs. recommended <100), **lack of formal adversarial verification**, and **checkpoint/recovery mechanisms for long-running tasks**.

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | monorepo — weight adjustments: dim2↑22%, dim5↑12%, dim6↑12% |
| Stage | mature — all 44 items active |
| Skipped Items | None |
| Critical Items (monorepo) | 2.5 Dependency direction, 2.7 Structural conventions, 5.5 Cache-friendly, 6.2 Cleanup process |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs & Knowledge Mgmt | 5 | 4.5 | 90.0% | 13% | 11.70 | Goal State |
| 2 | Mechanical Constraints | 7 | 6.5 | 92.9% | 22% | 20.43 | Actuator |
| 3 | Feedback Loops & Observability | 5 | 4.5 | 90.0% | 13% | 11.70 | Sensor |
| 4 | Testing & Verification | 7 | 5.5 | 78.6% | 13% | 10.21 | Sensor + Actuator |
| 5 | Context Engineering | 5 | 4.0 | 80.0% | 12% | 9.60 | Goal State |
| 6 | Entropy Management & Garbage Collection | 4 | 3.5 | 87.5% | 12% | 10.50 | Feedback Loop |
| 7 | Long-Running Task Support | 6 | 4.5 | 75.0% | 10% | 7.50 | Feedback Loop |
| 8 | Safety Rails | 6 | 5.0 | 83.3% | 5% | 4.17 | Actuator (protective) |
| | **Total** | **45** | **38** | | **100%** | **85.81** | |

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (90%)

| Item | Rating | Evidence |
|------|--------|----------|
| 1.1 Agent instruction file | **PARTIAL** | `AGENTS.md` (286 lines) + `CLAUDE.md` symlink. Extremely comprehensive but 2.8× over the <100 line recommendation. 5 sub-directory AGENTS.md files for progressive disclosure. |
| 1.2 Structured knowledge base | **PASS** | `docs/` with 25+ subdirectories (channels, cli, concepts, gateway, plugins, providers, security, etc.), i18n support (zh-CN, ja-JP), hosted on Mintlify. |
| 1.3 Architecture documentation | **PASS** | AGENTS.md contains 6 major architecture boundary definitions: Plugin, Channel, Provider/Model, Gateway Protocol, Bundled Plugin Contract, Extension Test. |
| 1.4 Progressive disclosure | **PASS** | Root AGENTS.md → `src/plugin-sdk/AGENTS.md`, `src/channels/AGENTS.md`, `src/plugins/AGENTS.md`, `src/gateway/protocol/AGENTS.md`, `src/gateway/server-methods/AGENTS.md`. Explicit "Progressive disclosure lives in local boundary guides" section. |
| 1.5 Versioned knowledge artifacts | **PASS** | VISION.md, CONTRIBUTING.md, SECURITY.md, CHANGELOG.md, `.agents/skills/` with 8+ specialized workflow skills in version control. |

### 2. Mechanical Constraints (92.9%)

| Item | Rating | Evidence |
|------|--------|----------|
| 2.1 CI pipeline blocks | **PASS** | `.github/workflows/ci.yml` with 12+ jobs (preflight, security-fast, checks, check, check-additional, build-smoke, etc.), covering Linux/macOS/Windows, triggered on PRs and blocking merge. |
| 2.2 Linter enforcement | **PASS** | Oxlint (type-aware, `no-explicit-any: error`), 15+ custom lint scripts, SwiftLint, ktlint, Ruff (Python), Shellcheck, Actionlint, zizmor (Actions security audit). |
| 2.3 Formatter enforcement | **PASS** | oxfmt in CI blocking + pre-commit hook, SwiftFormat, markdownlint. |
| 2.4 Type safety | **PASS** | `tsconfig.json strict: true`, `no-explicit-any: error`, `pnpm tsgo` + `pnpm build:strict-smoke` blocking in CI, Swift type safety, Kotlin type safety. |
| 2.5 Dependency direction rules | **PASS** | 14+ custom boundary lints in CI (plugin-extension-boundary, no-src-outside-plugin-sdk, no-plugin-sdk-internal, no-relative-outside-package, no-extension-src-imports, web-search-provider-boundaries, etc.). |
| 2.6 Remediation-aware errors | **PARTIAL** | Custom lint scripts exist but not all verified to include fix instructions. AGENTS.md provides comprehensive remediation guidance for common violations. |
| 2.7 Structural conventions | **PASS** | LOC check (`check:loc --max 500`), jscpd duplicate detection, knip dead code detection, naming conventions documented, `canon:check` canonical enforcement. |

### 3. Feedback Loops & Observability (90%)

| Item | Rating | Evidence |
|------|--------|----------|
| 3.1 Structured logging | **PASS** | tslog framework, dedicated `src/logging/` module, `osc-progress` for CLI progress indicators. |
| 3.2 Metrics and tracing | **PASS** | `extensions/diagnostics-otel` OpenTelemetry extension, metrics integration. |
| 3.3 Agent-queryable observability | **PASS** | `openclaw status --json`, `openclaw channels status --probe`, `scripts/clawlog.sh` for macOS unified log queries. |
| 3.4 UI visibility | **PARTIAL** | playwright-core as dependency, used in E2E tests, but not as a real-time agent screenshot/inspect tool during sessions. |
| 3.5 Diagnostic error context | **PASS** | `Result<T,E>` style outcomes, closed error-code unions, zod boundary validation, detailed error diagnostics. |

### 4. Testing & Verification (78.6%)

| Item | Rating | Evidence |
|------|--------|----------|
| 4.1 Test suite | **PASS** | Multi-layer tests: unit (Vitest), E2E, live, Docker, gateway, channels, contracts, extensions, Android (JUnit), Swift (XCTest). |
| 4.2 Tests in CI blocking | **PASS** | Tests run on 3 platforms in CI and block merges. |
| 4.3 Coverage thresholds | **PASS** | V8 coverage: lines 70%, functions 70%, branches 55%, statements 70%. |
| 4.4 Formalized done criteria | **PARTIAL** | "Gate" definitions are comprehensive (local dev gate, landing gate, CI gate, hard gate), but not in a JSON/YAML machine-readable format. |
| 4.5 End-to-end verification | **PASS** | vitest.e2e.config.ts, 10+ Docker E2E test suites, install-smoke, Parallels cross-platform testing. |
| 4.6 Flake management | **PARTIAL** | Performance budgets (`test:perf:budget`), memory hotspot tracking, CI retries (Swift 3 attempts), but no formal quarantine/monitoring system. |
| 4.7 Adversarial verification | **PARTIAL** | Codex review recommended in CONTRIBUTING.md, `.agents/skills/` contains specialized skills, but no permission isolation or structured evidence reports. |

### 5. Context Engineering (80%)

| Item | Rating | Evidence |
|------|--------|----------|
| 5.1 Externalized knowledge | **PASS** | All key decisions in-repo: AGENTS.md, CONTRIBUTING.md, VISION.md, comprehensive docs/ hierarchy. |
| 5.2 Documentation freshness | **PASS** | CI validation: `docs:check-links`, `docs:check-i18n-glossary`, `config:docs:check`, `plugin-sdk:api:check` drift detection. |
| 5.3 Machine-readable references | **PARTIAL** | Rich internal references but no `llms.txt` or curated dependency documentation snapshots. |
| 5.4 Technology composability | **PASS** | Standard stack: TypeScript/Node/Vitest/pnpm/Swift/Kotlin, well-documented. |
| 5.5 Cache-friendly design | **PARTIAL** | Excellent progressive disclosure, but root AGENTS.md at 286 lines exceeds cache-friendly threshold. `.artifacts/`, `docs/.generated/` structured output directories exist. |

### 6. Entropy Management & Garbage Collection (87.5%)

| Item | Rating | Evidence |
|------|--------|----------|
| 6.1 Codified golden principles | **PASS** | AGENTS.md contains detailed coding principles: strict typing, avoid any, zod at boundaries, discriminated unions, file size guidelines. |
| 6.2 Recurring cleanup | **PASS** | `deadcode:knip`, `deadcode:ts-prune`, `deadcode:ts-unused`, `dup:check` (jscpd), `stale.yml` workflow. |
| 6.3 Tech debt tracking | **PARTIAL** | Tools exist (knip, jscpd, deadcode reports) but no formal tech-debt-tracker.json artifact. |
| 6.4 AI slop detection | **PASS** | jscpd duplicate detection, knip dead code, strict no-explicit-any, CONTRIBUTING.md requires AI PR transparency and Codex review. |

### 7. Long-Running Task Support (75%)

| Item | Rating | Evidence |
|------|--------|----------|
| 7.1 Task decomposition | **PARTIAL** | `.agents/skills/` contains workflow decomposition (release, GHSA, PR maintenance, etc.), but no generic execution plan template. |
| 7.2 Progress tracking | **PARTIAL** | Git commits + skill references, no structured progress.json. |
| 7.3 Handoff bridges | **PASS** | Multi-agent safety rules, `scripts/committer` for scoped commits, session logs at `~/.openclaw/agents/`. |
| 7.4 Environment recovery | **PASS** | `pnpm install`, Docker (Dockerfile + docker-compose.yml), `prepare` hook, AGENTS.md recovery guidance. |
| 7.5 Clean state discipline | **PASS** | AGENTS.md explicitly forbids landing with failing checks, pre-commit enforcement, multi-agent safety rules. |
| 7.6 Durable execution | **PARTIAL** | Agent skills provide workflow structure, but no formal checkpoint files or crash recovery protocol. |

### 8. Safety Rails (83.3%)

| Item | Rating | Evidence |
|------|--------|----------|
| 8.1 Least-privilege credentials | **PASS** | CI: `permissions: contents: read`, `persist-credentials: false`, scoped tokens. |
| 8.2 Audit logging | **PASS** | GitHub PR/deploy logs, `audit:seams` script, detect-secrets baseline, zizmor workflow security audit. |
| 8.3 Rollback capability | **PARTIAL** | Git rollback feasible, Docker versioned, but no documented rollback playbook. |
| 8.4 Human confirmation gates | **PASS** | Releases require explicit operator consent, npm publish requires permission, version changes require approval. |
| 8.5 Security-critical path marking | **PASS** | Comprehensive CODEOWNERS: `@openclaw/secops` covering 30+ security-sensitive paths (secrets, auth, security docs, etc.). |
| 8.6 Tool protocol trust boundaries | **PARTIAL** | AGENTS.md mentions cautious tool output handling, but no formal MCP least-privilege scoping policy. |

## Improvement Roadmap

### Quick Wins (implement in 1 day)

1. **Slim down AGENTS.md** (1.1 → PASS, 5.5 → PASS)
   - Reduce root AGENTS.md from 286 lines to <100 lines as an index/TOC
   - Extract "Coding Style & Naming Conventions", "Testing Guidelines", "Commit & PR Guidelines" into `docs/dev/` or sub-directory AGENTS.md files
   - Keep top-level structure pointers and command quick-reference; deep content via pointers

2. **Add tech-debt-tracker.json** (6.3 → PASS)
   - Create a structured tech debt tracking file recording known debt items, priority, and owners

3. **Add rollback playbook** (8.3 → PASS)
   - Create rollback documentation in `docs/reference/` covering npm publish rollback, Docker rollback, database migration rollback scenarios

4. **Create llms.txt** (5.3 → PASS)
   - Create `llms.txt` or `docs/llms.txt` listing key dependency documentation references for agents

### Strategic Investments (1-4 weeks)

1. **Adversarial verification system** (4.7 → PASS, estimated +2.6 points)
   - Implement three-layer verification: pre-implementation advisory, post-implementation adversarial verifier (read-only, structured evidence), plan-level completion verification
   - Verifier uses permission isolation (programmatic write-tool removal)
   - Anti-rationalization prompts embedded in verifier system prompts

2. **Formal flake management** (4.6 → PASS)
   - Implement flaky test quarantine/tagging mechanism
   - Track flake frequency and fix status
   - Integrate retry + monitoring in CI

3. **Execution plan templates + checkpoint mechanism** (7.1, 7.2, 7.6 → PASS, estimated +2.5 points)
   - Create `docs/dev/execution-plan-template.md`
   - Implement structured checkpoint files (`progress.json`) for long tasks
   - Document crash recovery protocol

4. **Remediation-aware error messages** (2.6 → PASS)
   - Audit 14+ custom boundary lint scripts to ensure each violation outputs fix steps
   - Format: "Error: You imported X from Y. Use Z instead because..."

### Expected Impact

After quick wins: **~88 points** (A)
After all investments: **~94 points** (A+)

## Notable Highlights

This repository has several practices **worthy of industry benchmark status**:

1. **14+ custom boundary lint rules** — Mechanically enforcing architecture boundaries rather than relying on documentation conventions
2. **Multi-platform CI coverage** — Linux + macOS + Windows with sharding and intelligent change detection
3. **Multi-agent safety rules** — AGENTS.md explicitly documents multi-agent parallel work safety protocols (no stash creation, no branch switching, scoped commits)
4. **Config/SDK drift detection** — `config:docs:check` and `plugin-sdk:api:check` ensure documentation stays in sync with code
5. **Progressive AGENTS.md hierarchy** — Root file + 5 sub-directory AGENTS.md files implementing layered knowledge architecture

## Anti-Patterns Observed

1. **AGENTS.md exceeds 100 lines** — At 286 lines, the root instruction file risks cache eviction and context overflow. The progressive disclosure structure mitigates this but the root should be trimmed.
2. **No machine-readable done criteria** — Gate definitions are well-documented in prose but not in a JSON/YAML format that agents can programmatically verify.
3. **Verification without adversarial probing** — Codex review exists but lacks structured evidence format and adversarial boundary-value testing.

---

*Audit performed using the Harness Engineering Guide skill v1.0. Profile: monorepo (weight overrides applied). Stage: mature (44/44 items active). All 8 dimensions scored with file-level evidence.*
