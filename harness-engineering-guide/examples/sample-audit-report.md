# Harness Engineering Audit: acme-taskboard

**Date**: 2026-03-15
**Profile**: fullstack | **Stage**: growth
**Ecosystem**: node (TypeScript)

## Overall Grade: C (61/100)

## Executive Summary

The project has solid foundations — TypeScript strict mode, ESLint in CI, and a reasonable test suite — but lacks architectural enforcement, observability, and long-running task support. The AGENTS.md is well-structured but the feedback loop from CI to agent improvement is open: failures block PRs but don't teach agents how to fix issues.

## Audit Parameters

| Parameter | Value |
|-----------|-------|
| Profile | fullstack — default weights applied |
| Stage | growth — 29 of 44 items active |
| Skipped Items | 1.5, 2.6, 3.2, 3.3, 3.4, 4.4, 4.6, 5.3, 5.4, 6.2, 6.3, 7.3, 7.6, 8.2, 8.5 |

## Dimension Scores

| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Arch Docs & Knowledge | 4 | 3.0/4 | 75% | 0.15 | 11.3 | Goal State |
| 2 | Mechanical Constraints | 5 | 3.5/5 | 70% | 0.20 | 14.0 | Actuator |
| 3 | Feedback & Observability | 2 | 1.0/2 | 50% | 0.15 | 7.5 | Sensor |
| 4 | Testing & Verification | 4 | 2.5/4 | 63% | 0.15 | 9.4 | Sensor + Actuator |
| 5 | Context Engineering | 3 | 1.5/3 | 50% | 0.10 | 5.0 | Goal State |
| 6 | Entropy Management | 2 | 1.0/2 | 50% | 0.10 | 5.0 | Feedback Loop |
| 7 | Long-Running Tasks | 4 | 1.5/4 | 38% | 0.10 | 3.8 | Feedback Loop |
| 8 | Safety Rails | 3 | 2.0/3 | 67% | 0.05 | 3.3 | Actuator (protective) |
| **Total** | | **27** | **16.0/27** | | | **59.3** | |

**Grade: C (59/100)**

## Detailed Findings

### 1. Architecture Documentation & Knowledge Management (75%)

| Item | Finding | Score |
|------|---------|-------|
| 1.1 Agent Instruction File | `AGENTS.md` exists, 72 lines, commands first, links to `docs/`. | PASS |
| 1.2 Structured Knowledge Base | `docs/` exists with 3 subdirectories and an index. | PASS |
| 1.3 Architecture Documentation | `docs/ARCHITECTURE.md` exists but lacks dependency direction rules. Lists modules but doesn't specify allowed import paths. | PARTIAL |
| 1.4 Progressive Disclosure | AGENTS.md is a good TOC. Deeper docs are organized by topic. | PASS |

### 2. Mechanical Constraints (70%)

| Item | Finding | Score |
|------|---------|-------|
| 2.1 CI Pipeline | GitHub Actions runs on every PR. Required status checks enabled. | PASS |
| 2.2 Linter Enforcement | ESLint in CI, blocks on violations. 12 rules enabled. | PASS |
| 2.3 Formatter Enforcement | Prettier configured but not in CI pipeline — only runs locally via pre-commit hook. | PARTIAL |
| 2.4 Type Safety | `tsconfig.json` with `strict: true`. tsc runs in CI. | PASS |
| 2.5 Dependency Direction | Documented in ARCHITECTURE.md but no mechanical enforcement (no custom ESLint rule). | FAIL |
| 2.7 Structural Conventions | File naming convention documented. No lint enforcement. | PARTIAL |

### 3. Feedback Loops & Observability (50%)

| Item | Finding | Score |
|------|---------|-------|
| 3.1 Structured Logging | Uses `pino` on the server, `console.log` on the client. Mixed. | PARTIAL |
| 3.5 Diagnostic Error Context | Custom error classes with context in API layer. Generic catches in some service files. | PASS |

### 4. Testing & Verification (63%)

| Item | Finding | Score |
|------|---------|-------|
| 4.1 Test Suite | 142 tests across unit and integration. No E2E. | PARTIAL |
| 4.2 Tests in CI | Tests run in CI and block PRs. | PASS |
| 4.3 Coverage Thresholds | Coverage measured (68%) but no threshold configured. | PARTIAL |
| 4.5 E2E Verification | No E2E tests. No Playwright or Cypress config found. | FAIL |
| 4.7 Adversarial Verification | No independent verification agent or process. Implementer self-assesses. | FAIL |

### 5. Context Engineering (50%)

| Item | Finding | Score |
|------|---------|-------|
| 5.1 Externalized Knowledge | Most decisions in-repo. Some API design discussions only in Slack. | PARTIAL |
| 5.2 Doc Freshness | No automated freshness checks. `docs/api-patterns.md` last updated 3 months ago. | FAIL |
| 5.5 Cache-Friendly Design | AGENTS.md is 72 lines. No artifact directories. Progress tracked in prose commit messages. | PASS |

### 6. Entropy Management (50%)

| Item | Finding | Score |
|------|---------|-------|
| 6.1 Golden Principles | 5 principles in AGENTS.md under "Boundaries" section. | PASS |
| 6.4 AI Slop Detection | No specific lint rules for AI patterns. `no-unused-vars` enabled but no duplicate detection. | FAIL |

### 7. Long-Running Task Support (38%)

| Item | Finding | Score |
|------|---------|-------|
| 7.1 Task Decomposition | No documented strategy. Agents receive full-scope prompts. | FAIL |
| 7.2 Progress Tracking | Only git commit messages. No structured progress files. | PARTIAL |
| 7.4 Environment Recovery | `docker-compose.yml` boots the stack. No health checks after start. | PARTIAL |
| 7.5 Clean State Discipline | Not documented. Some sessions leave uncommitted changes. | FAIL |

### 8. Safety Rails (67%)

| Item | Finding | Score |
|------|---------|-------|
| 8.1 Least-Privilege | CI token is repo-scoped. Agent has no deploy access. | PASS |
| 8.3 Rollback Capability | Git revert possible but no documented playbook. | PARTIAL |
| 8.4 Human Confirmation | Deploy requires manual approval in CI. DB migrations not gated. | PASS |

## Improvement Roadmap

### Quick Wins (implement in 1 day)

1. **Add Prettier to CI** — Already configured, just add `npx prettier --check .` to the pipeline. Fixes item 2.3. (30 min)
2. **Set coverage threshold** — Add `--coverage.thresholds.lines=65` to vitest config. Fixes item 4.3. (15 min)
3. **Add `reports/` directory** — Create artifact directory for agent outputs. Improves 5.5. (5 min)
4. **Document clean state discipline** — Add section to AGENTS.md. Fixes item 7.5. (30 min)

### Strategic Investments (1-4 weeks)

1. **Implement ESLint boundary rule** — Use `templates/linting/eslint-boundary-rule.js` as starting point. Enforce the dependency directions from ARCHITECTURE.md. Fixes items 2.5, 2.7. (1 week)
2. **Add Playwright E2E suite** — Start with critical user journeys (login, create task, complete task). Fixes items 4.5 and enables agent UI verification. (1-2 weeks)
3. **Set up doc-gardening CI** — Use `templates/ci/github-actions/doc-freshness.yml`. Fixes item 5.2. (2 hours)
4. **Build execution plan infrastructure** — Create `exec-plans/` directory, adopt `templates/universal/execution-plan.md`. Fixes items 7.1, 7.2. (1 week)

## Recommended Templates

| Gap | Template |
|-----|----------|
| No dependency enforcement | `templates/linting/eslint-boundary-rule.js` |
| No doc freshness | `templates/ci/github-actions/doc-freshness.yml` |
| No task decomposition | `templates/universal/execution-plan.md` |
| No formalized done criteria | `templates/universal/feature-checklist.json` |
| No environment health checks | `templates/init/init.sh` |
