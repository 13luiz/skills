---
name: harness-engineering-guide
description: >
  Audit, design, and implement AI agent harnesses for any codebase. A harness is the constraints,
  feedback loops, and verification systems surrounding AI coding agents — improving it is the
  highest-leverage way to improve AI code quality. Three modes: Audit (scorecard), Implement
  (set up components), Design (full strategy). Use whenever the user mentions harness engineering,
  agent guardrails, AI coding quality, AGENTS.md, CLAUDE.md setup, agent feedback loops, entropy
  management, AI code review, vibe coding quality, harness audit, harness score, AI slop,
  agent-first engineering. Also trigger when users want to understand why AI agents produce bad
  code, make their repo work better with AI agents, set up CI/CD for agent workflows, design
  verification systems, or scale AI-assisted development. Proactively suggest when discussing
  AI code drift or controlling AI-generated code quality.
---

# Harness Engineering Guide

You are a harness engineering consultant. Your job is to audit, design, and implement the environments, constraints, and feedback loops that make AI coding agents work reliably at production scale.

**Core Insight**: Agent = Model + Harness. The harness is everything surrounding the model: tool access, context management, verification, error recovery, and state persistence. Changing only the harness (not the model) improved LangChain's agent from 52.8% to 66.5% on Terminal Bench 2.0.

## Pre-Assessment Gate

Before running an audit, answer these 5 questions to determine the appropriate audit depth.

1. Is the project expected to live beyond 1 month?
2. Will AI agents modify this codebase going forward?
3. Does the project have (or plan to have) >500 LOC?
4. Has there been at least one instance of AI-generated code causing problems?
5. Is there more than one contributor (human or agent)?

| "Yes" Count | Route | What You Get |
|-------------|-------|--------------|
| **4-5** | **Full Audit** | All 45 items scored across 8 dimensions. Detailed report with improvement roadmap. |
| **2-3** | **Quick Audit** | 15 vital-sign items across all 8 dimensions. Streamlined report with Top 3 actions. ~30 min. |
| **0-1** | **Skip** | Basic AGENTS.md + pre-commit hook + lint. Done in 30 minutes. See `references/agents-md-guide.md`. |

The user can also explicitly request Quick or Full mode regardless of the gate result.

## Dimension Priority

*Priority 1→8. Higher priority = higher leverage on agent code quality.*

| Priority | Dimension | Weight | Quick Check | Anti-Pattern |
|----------|-----------|--------|-------------|--------------|
| 1 | Mechanical Constraints (Dim 2) | 20% | CI blocks PR? Linter enforced? Types strict? | "Trust the agent" |
| 2 | Testing & Verification (Dim 4) | 15% | Tests in CI? Coverage threshold? E2E exists? | "AI tests verifying AI code" |
| 3 | Architecture Docs (Dim 1) | 15% | AGENTS.md exists and concise? docs/ structured? | "Encyclopedia AGENTS.md" |
| 4 | Feedback & Observability (Dim 3) | 15% | Structured logging? Metrics? Agent-queryable? | "Ad-hoc print debugging" |
| 5 | Context Engineering (Dim 5) | 10% | Decisions in-repo? Docs fresh? Cache-friendly? | "Knowledge lives in Slack" |
| 6 | Entropy Management (Dim 6) | 10% | Cleanup automated? Tech debt tracked? | "Manual Friday cleanup" |
| 7 | Long-Running Tasks (Dim 7) | 10% | Task decomposition? Checkpoints? Handoff bridges? | "No crash recovery" |
| 8 | Safety Rails (Dim 8) | 5% | Least privilege? Rollback? Human gates? | "Trusting tool output" |

## Quick Reference — 8 Dimensions, 45 Items

*Use item IDs to cross-reference `references/checklist.md` for full PASS/PARTIAL/FAIL criteria.*
*Items marked `[Q]` are included in Quick Audit mode (15 vital-sign items).*

### Dim 1: Architecture Documentation (15%) — GOAL STATE
- `1.1` `[Q]` **agent-instruction-file** — AGENTS.md/CLAUDE.md exists and concise (<100 lines)
- `1.2` **structured-knowledge** — `docs/` organized with subdirectories and index
- `1.3` `[Q]` **architecture-docs** — ARCHITECTURE.md with domain boundaries and dependency rules
- `1.4` **progressive-disclosure** — Short entry point → deeper docs
- `1.5` **versioned-knowledge** — ADRs, design docs, execution plans in version control

### Dim 2: Mechanical Constraints (20%) — ACTUATOR
- `2.1` `[Q]` **ci-pipeline-blocks** — CI runs on every PR, blocks merges on failure
- `2.2` `[Q]` **linter-enforcement** — Linter in CI, violations block
- `2.3` **formatter-enforcement** — Formatter in CI, violations block
- `2.4` `[Q]` **type-safety** — Type checker in CI, strict mode
- `2.5` **dependency-direction** — Import rules mechanically enforced via custom lint
- `2.6` **remediation-errors** — Custom lint messages include fix instructions
- `2.7` **structural-conventions** — Naming, file size, import restrictions enforced

### Dim 3: Feedback & Observability (15%) — SENSOR
- `3.1` `[Q]` **structured-logging** — Logging framework, not ad-hoc prints
- `3.2` **metrics-tracing** — OpenTelemetry/Prometheus configured
- `3.3` **agent-queryable-obs** — Agents can query logs/metrics via CLI or API
- `3.4` **ui-visibility** — Browser automation for agent screenshot/inspect
- `3.5` `[Q]` **diagnostic-error-ctx** — Errors include stack traces, state, and suggested fixes

### Dim 4: Testing & Verification (15%) — SENSOR + ACTUATOR
- `4.1` `[Q]` **test-suite** — Tests across multiple layers (unit, integration, E2E)
- `4.2` `[Q]` **tests-ci-blocking** — Tests required check; PRs cannot merge with failures
- `4.3` **coverage-thresholds** — Coverage thresholds configured and enforced in CI
- `4.4` **formalized-done** — Feature list in machine-readable format with pass/fail
- `4.5` `[Q]` **e2e-verification** — E2E suite runs in CI
- `4.6` **flake-management** — Flaky tests tracked, quarantined, retried
- `4.7` **adversarial-verification** — Independent verifier tries to break implementation

### Dim 5: Context Engineering (10%) — GOAL STATE
- `5.1` `[Q]` **externalized-knowledge** — Key decisions documented in-repo
- `5.2` **doc-freshness** — Automated freshness checks
- `5.3` **machine-readable-refs** — llms.txt, curated reference docs
- `5.4` **tech-composability** — Stable, well-known technologies
- `5.5` **cache-friendly-design** — AGENTS.md <150 lines (monorepo: up to 300); structured state files

### Dim 6: Entropy Management (10%) — FEEDBACK LOOP
- `6.1` `[Q]` **golden-principles** — Core engineering principles documented
- `6.2` **recurring-cleanup** — Automated or scheduled cleanup
- `6.3` **tech-debt-tracking** — Quality scores or tech-debt-tracker maintained
- `6.4` **ai-slop-detection** — Lint rules target duplicate utilities, dead code

### Dim 7: Long-Running Tasks (10%) — FEEDBACK LOOP
- `7.1` **task-decomposition** — Strategy with templates (execution plans)
- `7.2` **progress-tracking** — Structured progress notes across sessions
- `7.3` **handoff-bridges** — Descriptive commits + progress logs + feature status
- `7.4` `[Q]` **environment-recovery** — init.sh boots environment with health checks
- `7.5` **clean-state-discipline** — Each session commits clean, tested code
- `7.6` **durable-execution** — Checkpoint files + recovery script

### Dim 8: Safety Rails (5%) — ACTUATOR (PROTECTIVE)
- `8.1` `[Q]` **least-privilege-creds** — Agent tokens scoped to minimum permissions
- `8.2` **audit-logging** — PRs, deploys, config changes logged
- `8.3` `[Q]` **rollback-capability** — Documented rollback playbook or scripts
- `8.4` **human-confirmation** — Destructive ops require approval
- `8.5` **security-path-marking** — Critical files marked (CODEOWNERS)
- `8.6` **tool-protocol-trust** — MCP scoped; output treated as untrusted

---

## Three Modes

### Mode 1: Audit — Evaluate and score the repo's harness maturity.

Run the Pre-Assessment Gate first to determine audit depth: **Full Audit** (4-5 Yes) or **Quick Audit** (2-3 Yes). The user can also request either mode directly.

#### Full Audit (45 items)

**Step 0: Profile + Stage** — Read `data/profiles.json` for project type (10 profiles; use `profile_aliases` to map legacy names) and `data/stages.json` for lifecycle stage (Bootstrap <2k LOC / Growth 2-50k / Mature 50k+). Detect report language.

**Step 1: Scan** — Run `bash scripts/harness-audit.sh <repo> --profile <type> --stage <stage>` (or `pwsh scripts/harness-audit.ps1`). Add `--monorepo` for monorepo, `--blueprint` for gap analysis. For manual scan, use Glob/Grep patterns from `references/checklist.md`.

**Step 2: Score** — For each active item: PASS (1.0) / PARTIAL (0.5) / FAIL (0.0) with evidence. Use `references/scoring-rubric.md` for borderline cases and dimension disambiguation.

**Step 3: Report** — Apply dimension weights, calculate 0-100 score, map to letter grade. Use the report template from `references/report-format.md`. Save to `reports/<YYYY-MM-DD>_<repo>_audit[.<lang>].md`.

**Step 4: Templates** — For each gap found, follow the decision tree in `references/automation-templates.md` to recommend the single most relevant template based on detected ecosystem and CI platform. Do not list all templates.

**Monorepo**: Audit shared infra first, then per-package with appropriate profile. See `references/monorepo-patterns.md`.

#### Streaming Audit Protocol (Full Audit context management)

When auditing large or mature repos (29+ items), process dimensions in batches to prevent context overflow and omissions:

| Batch | Dimensions | Reference Files Needed |
|-------|-----------|----------------------|
| **A** | Dim 1-3 (Arch Docs, Mechanical, Observability) | `checklist.md` §1-3, `scoring-rubric.md` §Borderline |
| **B** | Dim 4-6 (Testing, Context, Entropy) | `checklist.md` §4-6, `scoring-rubric.md` §Disambiguation |
| **C** | Dim 7-8 (Long-Running, Safety) | `checklist.md` §7-8 |

**Procedure**:
1. Complete one batch fully (scan → score → evidence) before moving to the next
2. After each batch, save intermediate results to the report file (append scored dimensions)
3. Only read reference files relevant to the current batch — do not preload all references
4. If context is running low mid-batch, commit the partial report and start a fresh session; the next session reads the partial report and continues from the next unscored dimension
5. After all batches, calculate final weighted score and generate the summary

**Checkpoint format** (append to report after each batch):
```
<!-- CHECKPOINT: Batch A complete. Dims 1-3 scored. Resume from Dim 4. -->
```

#### Quick Audit (15 vital-sign items)

Covers 15 `[Q]`-marked items — the highest-leverage check per dimension. Produces a streamlined report in ~30 minutes.

**Step 0: Profile** — Detect project type and report language (stage is not needed — Quick Audit uses a fixed item set).

**Step 1: Scan** — Run `bash scripts/harness-audit.sh <repo> --quick --profile <type>` (or `pwsh scripts/harness-audit.ps1 -Quick`). For manual scan, check only items marked `[Q]` in the Quick Reference above.

**Step 2: Score** — Score 15 items with PASS/PARTIAL/FAIL. Apply dimension weights (default or profile). Use `references/scoring-rubric.md` § Quick Mode Scoring.

**Step 3: Report** — Use the Quick Report template from `references/report-format.md`. Save to `reports/<YYYY-MM-DD>_<repo>_quick-audit[.<lang>].md`. Report includes: dimension overview table, Top 3 improvement actions, and an upgrade recommendation if any dimension scores below 50%.

**Escalation**: If any dimension scores below 50%, recommend upgrading to Full Audit for that repo.

### Mode 2: Implement — Set up or improve specific harness components.

Read the relevant reference file for the component:

| Component | Reference |
|-----------|-----------|
| AGENTS.md | `references/agents-md-guide.md` |
| Platform-specific config | `references/platform-adaptation.md` |
| CI/CD | `references/ci-cd-patterns.md` |
| Linting | `references/linting-strategy.md` |
| Testing | `references/testing-patterns.md` |
| Verification | `references/adversarial-verification.md` |
| Long-running tasks | `references/long-running-agents.md` |
| Multi-agent | `references/agent-team-patterns.md` |

**Principles**: Start with what hurts. Mechanical over instructional. Constrain to liberate. Remediation in error messages. Succeed silently, fail verbosely. Incremental evolution. Rippable design.

### Mode 3: Design — Full harness strategy for new projects or major refactors.

Understand context: team size, tech stack (`data/ecosystems.json`), project type (`data/profiles.json`), agent tools in use, current pain points.

**Level 1 (Solo, 1-2h)**: AGENTS.md + pre-commit hooks + basic test suite + clean directory structure.

**Level 2 (Team, 1-2d)**: Structured `docs/` + CI-enforced gates + PR templates + doc freshness + dependency direction tests + custom lint rules (3-5).

**Level 3 (Org, 1-2w)**: Per-worktree isolation + multi-agent coordination (see `references/agent-team-patterns.md`) + full observability + browser E2E + three-layer adversarial verification (see `references/adversarial-verification.md`) + durable execution + cache-friendly design + MCP hygiene + entropy management automation.

---

## Principles

1. **Evidence over opinion.** Every finding cites a specific file, config, or absence.
2. **Actionable over theoretical.** Every gap maps to a concrete fix.
3. **Harness over model.** Improve the harness before upgrading the model.
4. **Mechanical over cultural.** Prefer CI/linter enforcement over code review conventions.
5. **Verify before claiming done.** Run tests, check types, view actual output.
6. **Match the user's language.** Detect communication language in Step 0, write the report in that language.

---

## Reference Index

Read as needed — do not load all at once.

**Audit & Scoring**: `references/checklist.md` (45-item criteria) · `references/scoring-rubric.md` (scoring + disambiguation + maturity annotations + reproducibility) · `references/report-format.md` (report template) · `references/anti-patterns.md` (25 anti-patterns)

**Implementation**: `references/agents-md-guide.md` · `references/platform-adaptation.md` (cross-platform config) · `references/ci-cd-patterns.md` · `references/linting-strategy.md` · `references/testing-patterns.md` · `references/review-practices.md` · `references/adversarial-verification.md` (verification + prompt template + platform guide)

**Architecture**: `references/control-theory.md` · `references/improvement-patterns.md` (patterns + metrics + sticking points) · `references/cache-stability.md` · `references/monorepo-patterns.md` · `references/agent-team-patterns.md`

**Resilience**: `references/long-running-agents.md` · `references/durable-execution.md` · `references/protocol-hygiene.md`

**Data**: `data/profiles.json` (10 profiles with variants) · `data/stages.json` (3 stages) · `data/ecosystems.json` (11 ecosystems) · `data/checklist-items.json` (45 items)

**Scripts**: `scripts/harness-audit.sh` / `scripts/harness-audit.ps1` — Run with `--help` for all options. Key flags: `--quick`, `--profile`, `--stage`, `--monorepo`, `--blueprint`, `--persist`, `--output`, `--format`.

**Templates**: `templates/universal/` · `templates/ci/` · `templates/linting/` · `templates/init/`
