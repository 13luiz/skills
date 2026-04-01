# OpenClaw Harness Maturity: Time-Series Analysis

**Date**: 2026-04-01
**Evaluation Period**: December 2025 – March 2026
**Profile**: monorepo | **Stage**: mature
**Versions Analyzed**: v2.0.0-beta5, v2026.1.30, v2026.2.26, v2026.3.31

## Overall Trajectory

| Version | Date | Packages | AGENTS.md Lines | Score | Grade | Δ from Previous |
|---------|------|----------|-----------------|-------|-------|-----------------|
| v2.0.0-beta5 | Dec 2025 | 2 | 78 | **64.6** | C | — (baseline) |
| v2026.1.30 | Jan 2026 | 33 | 178 | **72.3** | B | +7.7 |
| v2026.2.26 | Feb 2026 | 36 | 256 | **72.8** | B | +0.5 |
| v2026.3.31 | Mar 2026 | 94 | 255 | **78.0** | B | +5.2 |

**Net change**: +13.4 points over 4 months (C → B)
**Trend**: Generally upward with one plateau (Jan→Feb +0.5). The largest leap occurred at the beta5→Jan transition (+7.7), coinciding with the monorepo expansion from 2 to 33 packages and the introduction of pre-commit hooks, secret detection, and OTel integration.

## Dimension Evolution

| Dimension | Dec 2025 | Jan 2026 | Feb 2026 | Mar 2026 | Trend |
|-----------|----------|----------|----------|----------|-------|
| 1. Architecture Docs | 70.0% | 80.0% | 90.0% | 90.0% | ↗ Steady climb; stabilized at 90% |
| 2. Mechanical Constraints | 71.4% | 71.4% | 85.7% | 85.7% | ↗ Jump at Feb (boundary scripts); formatter regression in Mar |
| 3. Feedback & Observability | 70.0% | 90.0% | 80.0% | 100.0% | ↗ Strong growth; perfect in Mar |
| 4. Testing & Verification | 64.3% | 71.4% | 78.6% | 71.4% | ↔ Volatile; Feb peak (adversarial tests), Mar dip (coverage/flake gaps) |
| 5. Context Engineering | 60.0% | 70.0% | 70.0% | 80.0% | ↗ Steady improvement; cache design matured |
| 6. Entropy Management | 50.0% | 50.0% | 37.5% | 50.0% | ↔ **Stagnant** — persistent weakest dimension |
| 7. Long-Running Tasks | 66.7% | 75.0% | 58.3% | 50.0% | ↘ **Regression** — doctor command helps but decomposition/handoff weakened |
| 8. Safety Rails | 50.0% | 66.7% | 58.3% | 91.7% | ↗ Major leap in Mar (CODEOWNERS, rollback docs, tool trust docs) |

## Key Observations

### 1. Monorepo Growth vs. Harness Maturity
The repository grew from 2 to 94 packages over the evaluation period. Despite this 47× scale increase, the harness score improved +13.4 points — demonstrating that the team invested in harness infrastructure alongside feature development.

### 2. AGENTS.md Line-Count Trajectory

| Version | Lines | Threshold | Status |
|---------|-------|-----------|--------|
| v2.0.0-beta5 | 78 | 160 | PASS (49% of threshold) |
| v2026.1.30 | 178 | 300 | PASS (59% of threshold) |
| v2026.2.26 | 256 | 300 | PASS (85% of threshold) |
| v2026.3.31 | 255 | 300 | PASS (85% of threshold) |

Line count stabilized at ~255 in Feb→Mar despite adding 58 new packages, suggesting successful progressive disclosure: detail is being pushed into scoped boundary files (`src/plugin-sdk/AGENTS.md`, `extensions/AGENTS.md`) rather than inflating the root file. No "Encyclopedia AGENTS.md" anti-pattern detected at any point.

### 3. Persistent Gaps Across All Versions

| Gap | Dec | Jan | Feb | Mar | Status |
|-----|-----|-----|-----|-----|--------|
| No `llms.txt` (5.3) | FAIL | FAIL | FAIL | FAIL | **Never addressed** |
| Coverage not CI-gated (4.3) | PARTIAL | PARTIAL | PARTIAL | PARTIAL | Thresholds defined but never enforced |
| No ADR directory (1.5) | PARTIAL | FAIL | PARTIAL | PARTIAL | Oscillates; no formal ADR practice |
| No durable execution (7.6) | FAIL | FAIL | FAIL | FAIL | **Never addressed** |
| No tech-debt register (6.3) | PARTIAL | PARTIAL | PARTIAL | FAIL | Regressing |

### 4. Major Improvements by Version

**Jan 2026 (v2026.1.30) — "The Extension Expansion"**
- Extension architecture (29 packages)
- `.pre-commit-config.yaml` (shellcheck, actionlint, zizmor)
- `detect-secrets` CI job
- E2E test infrastructure (`vitest.e2e.config.ts`, Docker scripts)
- Tool policy/sandbox code (`src/agents/sandbox/tool-policy.ts`)

**Feb 2026 (v2026.2.26) — "The Boundary Release"**
- Custom boundary enforcement scripts
- Adversarial security tests (prompt injection, exec injection)
- PR template with evidence checklist
- `pnpm check:docs` (markdownlint, link audit)
- `.github/workflows/stale.yml`

**Mar 2026 (v2026.3.31) — "The Safety Release"**
- `.github/CODEOWNERS` for security-sensitive paths
- Rollback documentation (`docs/install/updating.md`)
- Full observability (OTel promoted, diagnostic events)
- `jscpd`-based duplication detection (`dup:check`)
- `canon:check` for canonical pattern enforcement
- Nested `AGENTS.md` files for progressive disclosure

### 5. Regression Points

**Feb 2026**: Dim 6 (Entropy) dropped from 50% to 37.5% — `deadcode` CI job disabled (`if: false`), and AI slop detection dropped to FAIL.

**Mar 2026**: Dim 7 (Long-Running Tasks) dropped from 58.3% to 50% — task decomposition, progress tracking, and handoff bridges all scored lower as the monorepo's complexity outpaced the existing long-running task infrastructure. Dim 2 had a formatter regression: `pnpm check` no longer runs `oxfmt --check` despite the CI step name suggesting it does.

## Weighted Contribution Trends

| Dimension | Weight | Dec | Jan | Feb | Mar | Δ Total |
|-----------|--------|-----|-----|-----|-----|---------|
| Arch Docs | 13% | 9.10 | 10.40 | 11.70 | 11.70 | +2.60 |
| Mechanical | 22% | 15.71 | 15.71 | 18.86 | 18.86 | +3.15 |
| Observability | 13% | 9.10 | 11.70 | 10.40 | 13.00 | +3.90 |
| Testing | 13% | 8.36 | 9.28 | 10.22 | 9.28 | +0.93 |
| Context | 12% | 7.20 | 8.40 | 8.40 | 9.60 | +2.40 |
| Entropy | 12% | 6.00 | 6.00 | 4.50 | 6.00 | +0.00 |
| Long Tasks | 10% | 6.67 | 7.50 | 5.83 | 5.00 | −1.67 |
| Safety | 5% | 2.50 | 3.33 | 2.92 | 4.58 | +2.08 |
| **Total** | **100%** | **64.63** | **72.33** | **72.83** | **78.02** | **+13.39** |

**Biggest gainers**: Observability (+3.90), Mechanical Constraints (+3.15), Architecture Docs (+2.60)
**Only loser**: Long-Running Tasks (−1.67) — the only dimension that ended lower than it started

## Recommendations for Next Version

### Priority 1: Fix Regressions
1. **Formatter enforcement** (2.3): Add `pnpm format:check` back to `pnpm check` — easy fix, recovers 3.14 weighted points.
2. **Long-running task infrastructure** (Dim 7): Add handoff template, task decomposition standard, and explore durable execution.

### Priority 2: Close Persistent Gaps
3. **`llms.txt`** (5.3): Four consecutive FAILs. Create a machine-readable doc index.
4. **Coverage in CI** (4.3): Wire `pnpm test:coverage` into CI to enforce existing thresholds.
5. **Tech-debt register** (6.3): Create `TECH_DEBT.md` or adopt `templates/universal/tech-debt-tracker.json`.

### Priority 3: Push Toward A Grade
6. **Full adversarial verification** (4.7): Add permission-isolated verification agent with structured evidence reports.
7. **ADR practice** (1.5): Establish `docs/adr/` directory with at least 3 retrospective ADRs.
8. **AI slop detection** (6.4): Extend `jscpd` + `canon:check` into a dedicated AI-quality gate.

**Projected score if Priority 1-2 addressed**: ~83-85 (borderline A)

## Eval Validation Summary

| Eval | Expected Range | Actual Score | In Range? |
|------|---------------|--------------|-----------|
| 1a (Dec 2025) | 65-78 | 64.6 | Near miss (−0.4) |
| 1b (Jan 2026) | 70-82 | 72.3 | ✓ |
| 1c (Feb 2026) | 72-85 | 72.8 | ✓ |
| 1d (Mar 2026) | 75-88 | 78.0 | ✓ |

3 of 4 evals within expected range. The baseline (1a) scored 0.4 points below the lower bound, attributable to stricter scoring on observability (3.2, 3.3) and long-running task items (7.4) compared to the original benchmark expectations.
