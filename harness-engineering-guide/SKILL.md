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

## When to Apply

### Must Use

- Auditing a repo's AI coding readiness or harness maturity
- Setting up AGENTS.md / CLAUDE.md for a project
- Designing a harness strategy for a new project or major refactor
- AI agents consistently produce low-quality, drifting, or non-conforming code
- Setting up CI/CD gates specifically for agent-generated PRs

### Recommended

- Scaling AI tool adoption across a growing team
- Transitioning from solo developer to team collaboration with agents
- CI pipeline does not block agent-generated PRs on failure
- Reviewing why AI code rework rate is high
- Planning observability or testing improvements for agent workflows

### Skip

- Pure manual coding with no AI agent involvement
- Model selection or prompt optimization (not environment-related)
- Business logic debugging unrelated to agent behavior
- Infrastructure or DevOps work with no AI agent dimension

**Decision criteria**: If the issue is about **code quality from AI agents** rather than the model itself, this Skill should be used.

## Core Insight

**Agent = Model + Harness.** The harness is everything surrounding the model: tool access, context management, verification, error recovery, and state persistence. Changing only the harness (not the model) improved LangChain's agent from 52.8% to 66.5% on Terminal Bench 2.0. OpenAI shipped 1 million lines with zero human-written code in five months by investing in harness.

## Control Theory Foundation

Every effective harness implements four elements from cybernetics:

| Element | Role in Harness | Audit Dimensions |
|---------|----------------|-----------------|
| **Goal State** | Architecture docs, quality standards, done criteria | Dim 1 + Dim 5 |
| **Sensor** | Tests, linters, logs, metrics, screenshots | Dim 3 + Dim 4 |
| **Actuator** | CI gates, auto-formatters, revert scripts | Dim 2 + Dim 4 |
| **Feedback Loop** | CI fail->fix->pass, review->lint rule, quality trends | Dim 3 + Dim 6 + Dim 7 |

A system missing any element is **open-loop** — it cannot self-correct. Read `references/control-theory.md` for the full theoretical grounding.

## Dimension Priority

*Follow priority 1→8 to decide which dimension to assess or fix first. Higher priority = higher leverage on agent code quality.*

| Priority | Dimension | Weight | Impact | Quick Check | Anti-Pattern |
|----------|-----------|--------|--------|-------------|--------------|
| 1 | Mechanical Constraints (Dim 2) | 20% | CRITICAL | CI blocks PR? Linter enforced? Types strict? | "Trust the agent to follow rules" |
| 2 | Testing & Verification (Dim 4) | 15% | CRITICAL | Tests in CI? Coverage threshold? E2E exists? | "AI tests verifying AI code" |
| 3 | Architecture Docs (Dim 1) | 15% | HIGH | AGENTS.md exists and <100 lines? docs/ structured? | "Encyclopedia AGENTS.md" |
| 4 | Feedback & Observability (Dim 3) | 15% | HIGH | Structured logging? Metrics? Agent-queryable? | "Ad-hoc print debugging" |
| 5 | Context Engineering (Dim 5) | 10% | HIGH | Decisions in-repo? Docs fresh? Cache-friendly? | "Knowledge lives in Slack" |
| 6 | Entropy Management (Dim 6) | 10% | MEDIUM | Cleanup automated? Tech debt tracked? Slop detected? | "Manual Friday cleanup" |
| 7 | Long-Running Tasks (Dim 7) | 10% | MEDIUM | Task decomposition? Checkpoints? Handoff bridges? | "No crash recovery" |
| 8 | Safety Rails (Dim 8) | 5% | MEDIUM | Least privilege? Rollback? Human gates on destructive ops? | "Trusting tool output blindly" |

## Quick Reference — 8 Dimensions, 44 Items

*Always-on context for rapid assessment. Use item IDs to cross-reference `references/checklist.md` for full PASS/PARTIAL/FAIL criteria. See `references/adversarial-verification.md` for the complete adversarial verification pattern (item 4.7).*

### Dim 1: Architecture Documentation & Knowledge Management (15%) — GOAL STATE
- `1.1` **agent-instruction-file** — AGENTS.md/CLAUDE.md exists and concise (<100 lines)
- `1.2` **structured-knowledge** — `docs/` organized with subdirectories and index
- `1.3` **architecture-docs** — ARCHITECTURE.md with domain boundaries and dependency rules
- `1.4` **progressive-disclosure** — Knowledge layered: short entry point -> deeper docs
- `1.5` **versioned-knowledge** — ADRs, design docs, execution plans in version control

### Dim 2: Mechanical Constraints (20%) — ACTUATOR
- `2.1` **ci-pipeline-blocks** — CI runs on every PR, blocks merges on failure
- `2.2` **linter-enforcement** — Linter in CI, violations block
- `2.3` **formatter-enforcement** — Formatter in CI, violations block
- `2.4` **type-safety** — Type checker in CI, strict mode (tsc strict / mypy strict / clippy)
- `2.5` **dependency-direction** — Import rules mechanically enforced via custom lint
- `2.6` **remediation-errors** — Custom lint messages include fix instructions for agents
- `2.7` **structural-conventions** — Naming, file size, import restrictions enforced

### Dim 3: Feedback Loops & Observability (15%) — SENSOR
- `3.1` **structured-logging** — Logging framework (winston/pino/loguru/slog/tracing) not ad-hoc prints
- `3.2` **metrics-tracing** — OpenTelemetry/Prometheus/metrics configured
- `3.3` **agent-queryable-obs** — Agents can query logs/metrics via CLI or API
- `3.4` **ui-visibility** — Browser automation (Playwright/Cypress) for agent screenshot/inspect
- `3.5` **diagnostic-error-ctx** — Errors include stack traces, state, and suggested fixes

### Dim 4: Testing & Verification (15%) — SENSOR + ACTUATOR
- `4.1` **test-suite** — Tests across multiple layers (unit, integration, E2E)
- `4.2` **tests-ci-blocking** — Tests required check; PRs cannot merge with failures
- `4.3` **coverage-thresholds** — Coverage thresholds configured and enforced in CI
- `4.4` **formalized-done** — Feature list in machine-readable format (JSON/YAML) with pass/fail
- `4.5` **e2e-verification** — E2E suite (Playwright/Cypress) runs in CI
- `4.6` **flake-management** — Flaky tests tracked, quarantined, retried with monitoring
- `4.7` **adversarial-verification** — Independent verifier tries to break implementation (read-only, structured evidence)

### Dim 5: Context Engineering (10%) — GOAL STATE
- `5.1` **externalized-knowledge** — Key decisions documented in-repo, not in Slack/chat
- `5.2` **doc-freshness** — Automated freshness checks (CI, doc-gardening agent)
- `5.3` **machine-readable-refs** — llms.txt, curated reference docs for key dependencies
- `5.4` **tech-composability** — Stable, well-known technologies; minimal opaque abstractions
- `5.5` **cache-friendly-design** — AGENTS.md <100 lines; structured state files; artifact dirs

### Dim 6: Entropy Management & Garbage Collection (10%) — FEEDBACK LOOP
- `6.1` **golden-principles** — Core engineering principles documented and referenced
- `6.2` **recurring-cleanup** — Automated or scheduled cleanup (refactoring agent, quality PRs)
- `6.3` **tech-debt-tracking** — Quality scores or tech-debt-tracker maintained
- `6.4` **ai-slop-detection** — Lint rules target duplicate utilities, dead code, AI patterns

### Dim 7: Long-Running Task Support (10%) — FEEDBACK LOOP
- `7.1` **task-decomposition** — Documented strategy with templates (execution plans)
- `7.2` **progress-tracking** — Structured progress notes maintained across sessions
- `7.3` **handoff-bridges** — Descriptive commits + progress logs + feature status
- `7.4` **environment-recovery** — init.sh/setup script boots environment with health checks
- `7.5` **clean-state-discipline** — Each session commits clean, tested code
- `7.6` **durable-execution** — Checkpoint files + recovery script + documented protocol

### Dim 8: Safety Rails (5%) — ACTUATOR (PROTECTIVE)
- `8.1` **least-privilege-creds** — Agent tokens scoped to minimum permissions
- `8.2` **audit-logging** — PRs, deploys, config changes logged with timestamps
- `8.3` **rollback-capability** — Documented rollback playbook or automated scripts
- `8.4` **human-confirmation** — Destructive ops (DB migrations, deploys) require approval
- `8.5` **security-path-marking** — Critical files marked (CODEOWNERS) with stricter review
- `8.6` **tool-protocol-trust** — MCP scoped to minimum permissions; output treated as untrusted

---

## Three Modes

Ask the user which mode they want, or infer from context.

### Mode 1: Audit
Evaluate the repo's harness maturity and produce a graded scorecard.

### Mode 2: Implement
Set up or improve specific harness components.

### Mode 3: Design
Design a complete harness strategy for a new project or major refactor.

---

## Mode 1: Audit

### Step 0: Determine Profile and Stage

Before scanning, determine two parameters that control the audit scope:

**Project Type Profile** — Read `data/profiles.json`. Detect or ask the user for the project type. This adjusts dimension weights and skips irrelevant items.

Available profiles: `frontend-spa`, `frontend-ssr`, `backend-api`, `backend-microservice`, `fullstack`, `library`, `cli-tool`, `desktop-app`, `mobile-app`, `system-infra`, `game`, `data-ml`, `devops-iac`, `script-automation`, `browser-extension`, `smart-contract`, `monorepo`

**Lifecycle Stage** — Read `data/stages.json`. Detect or ask the user for the project stage. This selects the active checklist item subset.

| Stage | LOC | Active Items | Focus |
|-------|-----|-------------|-------|
| **Bootstrap** | <2k | 9 items | Foundations: agent file, CI, lint, types, tests, env recovery |
| **Growth** | 2k-50k | 29 items | Constraints + testing + early feedback loops |
| **Mature** | 50k+ | 44 items (all) | Full audit with all dimensions |

**Report Language** — Detect the language the user is communicating in. The full audit report (Step 3) and all prose must be written in that language. Record the ISO 639-1 code (`en`, `zh`, `ja`, `ko`, `es`, `fr`, etc.) as an audit parameter — it also determines the report filename suffix (see Step 3).

### Step 1: Explore the Repository

**Option A (preferred):** Run the audit script for a quick preliminary scan:
- Bash: `bash scripts/harness-audit.sh <repo_root> [--profile <type>] [--stage <stage>]`
- PowerShell: `pwsh scripts/harness-audit.ps1 -RepoRoot <repo_root> [-Profile <type>] [-Stage <stage>]`

The script outputs JSON with file-level and content-level analysis. Use this to guide deeper investigation.

Add `--monorepo` for monorepo per-package scanning.
Add `--output <dir>` to save results to a file with timestamp.
Add `--format markdown` for a human-readable Markdown scan report.
Add `--blueprint` for a full gap analysis with recommendations, templates, and ecosystem CI commands.

**Option B (manual):** Launch parallel searches using Glob and Grep (see batch patterns in `references/checklist.md`).

### Step 2: Score Each Dimension

Read `references/checklist.md` — the primary scoring instrument with 44 items across 8 weighted dimensions.

For the selected stage, only score the active items from `data/stages.json`. Apply weight overrides from the selected profile in `data/profiles.json`.

For every active item: mark PASS (1.0) / PARTIAL (0.5) / FAIL (0.0) with evidence. Use `references/scoring-rubric.md` for borderline cases.

### Step 3: Calculate and Report

Apply dimension weights (default or profile-overridden) to get a final 0-100 score. Map to letter grade (A: 85-100, B: 70-84, C: 55-69, D: 40-54, F: 0-39).

Generate the report:

```markdown
# Harness Engineering Audit: [Project Name]

**Date**: [YYYY-MM-DD]
**Profile**: [project type] | **Stage**: [lifecycle stage]
**Ecosystem**: [detected]

## Overall Grade: [Letter] ([Score]/100)

## Executive Summary
[2-3 sentences on overall harness posture]

## Audit Parameters
| Parameter | Value |
|-----------|-------|
| Profile | [type] — [weight adjustments applied] |
| Stage | [stage] — [X of 44 items active] |
| Skipped Items | [list with reasons] |

## Dimension Scores
| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|

## Detailed Findings
### 1. Architecture Documentation & Knowledge Management
[Findings with evidence]
...

## Improvement Roadmap
### Quick Wins (implement in 1 day)
1. [Specific actionable item]
...
### Strategic Investments (1-4 weeks)
1. [Specific actionable item]
...

## Recommended Templates
[Offer specific templates from templates/ based on gaps found]
```

Read `references/improvement-patterns.md` for proven patterns when writing the roadmap.

**Save the report** — After generating the report, write it to a file inside this skill's `reports/` directory:

```
reports/<YYYY-MM-DD>_<repo-name>_audit[.<lang>].md
```

- English reports omit the language suffix: `2026-04-01_acme_audit.md`
- Non-English reports include the ISO 639-1 suffix: `2026-04-01_acme_audit.zh.md`
- Use the language code determined in Step 0

Also add the `Language` row to the Audit Parameters table in the report:

```markdown
| Language | [language name] ([code]) |
```

### Step 4: Provide Templates

Based on gaps found, offer ready-to-use artifacts from subdirectories under `templates/`:

| Gap | Template |
|-----|----------|
| No agent instruction file | `templates/universal/agents-md-scaffold.md` |
| No doc freshness mechanism | `templates/ci/github-actions/doc-freshness.yml` |
| No dependency enforcement (JS/TS) | `templates/linting/eslint-boundary-rule.js` |
| No dependency enforcement (Python) | `templates/linting/import-linter.cfg` |
| No dependency enforcement (Go) | `templates/linting/depguard.yml` |
| No dependency enforcement (Rust) | `templates/linting/clippy-workspace.toml` |
| No CI pipeline (GitHub) | `templates/ci/github-actions/standard-pipeline.yml` |
| No CI pipeline (GitLab) | `templates/ci/gitlab-ci.yml` |
| No CI pipeline (Azure) | `templates/ci/azure-pipelines.yml` |
| No tech debt tracking | `templates/universal/tech-debt-tracker.json` |
| No recurring cleanup | `templates/universal/doc-gardening-prompt.md` |
| No formalized done criteria | `templates/universal/feature-checklist.json` |
| No environment recovery | `templates/init/init.sh` or `templates/init/init.ps1` |
| No task decomposition | `templates/universal/execution-plan.md` |
| No verification report format | `templates/universal/verification-report-format.md` |

Use `data/ecosystems.json` to select the right ecosystem-specific templates and fill CI command placeholders.

### Monorepo Audit Flow

When the project is a monorepo (detected via `data/profiles.json` "monorepo" profile or `--monorepo` flag):

1. **Detect monorepo markers** — `pnpm-workspace.yaml`, `lerna.json`, `nx.json`, `turbo.json`, `Cargo.toml [workspace]`, `go.work`, `package.json` workspaces
2. **Audit shared infrastructure** — Root CI, root configs, root docs as "infrastructure layer"
3. **Per-package audit** — For each package, run audit with the package-appropriate profile (a frontend package uses `frontend-spa`, a library uses `library`, etc.)
4. **Cross-package checks** — Boundary enforcement between packages, shared test infra, doc coherence
5. **Output** — Per-package reports + aggregate report

Read `references/monorepo-patterns.md` for detailed monorepo audit guidance.

---

## Mode 2: Implement

When the user wants to implement specific components, read the relevant reference:

| Component | Reference File |
|-----------|---------------|
| AGENTS.md / CLAUDE.md | `references/agents-md-guide.md` |
| CI/CD pipeline | `references/ci-cd-patterns.md` |
| Linting & type checking | `references/linting-strategy.md` |
| Testing & verification | `references/testing-patterns.md` |
| Code review process | `references/review-practices.md` |
| Long-running agent tasks | `references/long-running-agents.md` |
| Cache stability & context | `references/cache-stability.md` |
| Durable execution | `references/durable-execution.md` |
| Protocol hygiene (MCP/A2A) | `references/protocol-hygiene.md` |
| Adversarial verification | `references/adversarial-verification.md` |
| Monorepo patterns | `references/monorepo-patterns.md` |
| Automation templates | `references/automation-templates.md` + `templates/` |

### Implementation Principles

1. **Start with what hurts.** Fix the failures you're actually experiencing.
2. **Mechanical over instructional.** A linter rule beats a doc paragraph. Agents cannot negotiate with deterministic checks.
3. **Constrain to liberate.** Strict boundaries make agents more productive, not less.
4. **Remediation in error messages.** Lint errors should teach: "You imported X from Y. The dependency direction is..."
5. **Succeed silently, fail verbosely.** Suppress passing output. Surface errors only.
6. **Incremental evolution.** Build 3-5 high-value lint rules, not 50.
7. **Rippable design.** As models improve, strip unnecessary scaffolding.

---

## Mode 3: Design

For new projects or major refactors, understand the team context first:

1. **Team size and AI adoption level**
2. **Tech stack** — Read `data/ecosystems.json` for ecosystem-specific guidance
3. **Project type** — Read `data/profiles.json` for type-specific weight adjustments
4. **Agent tools in use** (Claude Code, Codex, Cursor, Copilot, etc.)
5. **Current pain points** with AI-generated code

Then design across maturity levels:

### Level 1: Solo Developer (1-2 hours)
- AGENTS.md with commands, boundaries, and structure pointers
- Pre-commit hooks (format, lint, typecheck)
- Basic test suite with coverage threshold
- Clean directory structure

### Level 2: Small Team (1-2 days)
- Structured `docs/` directory as single source of truth
- CI-enforced constraints (all gates must pass before merge)
- PR templates with AI review checklist
- Documentation freshness checks
- Dependency direction tests
- Custom lint rules with remediation messages (3-5 rules)

### Level 3: Production Organization (1-2 weeks)
- Per-worktree isolation for concurrent agent work
- Full observability stack queryable by agents
- Browser automation for E2E verification
- **Three-layer adversarial verification**: pre-implementation advisory, post-implementation adversarial verifier (read-only, structured evidence), plan-level completion verification. See `references/adversarial-verification.md`.
- Anti-rationalization prompts in verifier system prompts (preemptively name the 6 common verification-skipping excuses)
- Structural nudges: inject verification reminders in task-tracking tool returns at the loop-exit moment
- Permission-isolated verifiers: programmatic write-tool removal + temp-dir exception for test scripts
- Session handoff protocols with structured progress files
- Durable execution support: checkpoint files, crash recovery
- Cache-friendly repository design
- MCP/tool protocol hygiene
- Doc-gardening agent on recurring schedule
- Background cleanup agents for entropy management
- Quality scoring system per module/domain

---

## Anti-Patterns to Flag

1. **AI tests verifying AI code** — Circular verification. Tests should independently verify logic.
2. **Encyclopedia AGENTS.md** — Files over 100 lines. Should be a TOC with pointers.
3. **LLM-generated agent config** — Human-crafted instruction files outperform AI-generated ones.
4. **Full test suite in agent context** — Floods context with passing output. Surface errors only.
5. **Tool hoarding** — Dozens of MCP servers bloat context and break cache stability.
6. **No environment health check** — Agents building on broken environments compound errors.
7. **Prose-based completion tracking** — Use structured JSON, not markdown.
8. **Optimizing prompts instead of harness** — Improve the environment, not the phrasing.
9. **Manual garbage collection** — Automate cleanup, don't do it manually on Fridays.
10. **Agent self-evaluation** — Agents rate themselves too highly. Use external verification.
11. **Dynamic tool catalog mid-session** — Invalidates prompt cache. Fix catalog at session start.
12. **No crash recovery** — Multi-step tasks need structured checkpoint files.
13. **Trusting tool output blindly** — MCP server output is untrusted input.
14. **Verification without execution** — Verifier reads code and writes "PASS" without running commands. A check without a command-run block is a skip, not a pass.
15. **Happy-path-only verification** — Verifier confirms the feature works with normal input but never tries to break it. At minimum, one adversarial probe (boundary value, concurrent request, missing resource) is required.

---

## Common Sticking Points

| Problem | Diagnosis | Fix |
|---------|-----------|-----|
| Agent ignores coding standards | Dim 2: linter not blocking in CI | Add linter as required CI check; use `2.6` remediation messages |
| Agent generates duplicate utilities | Dim 6: no slop detection | Add `6.4` ai-slop-detection lint rules for dead code and duplicates |
| Long tasks crash mid-way, no recovery | Dim 7: no durable execution | Implement `7.6` checkpoint files + recovery script |
| PRs frequently reverted after merge | Dim 4: insufficient test coverage | Raise `4.3` coverage thresholds; add `4.5` E2E verification |
| AGENTS.md too long, agent ignores it | Dim 1: no progressive disclosure | Trim to <100 lines (`1.1`); use `1.4` layered knowledge with pointers |
| Agent writes code that type-checks but is wrong | Dim 4: no adversarial verification | Add `4.7` independent verifier that tries to break the implementation |
| Agent breaks other modules when fixing one | Dim 2: no dependency direction enforcement | Add `2.5` import boundary rules via custom lint |
| Quality degrades over time | Dim 6: no recurring cleanup | Set up `6.2` automated cleanup agent + `6.3` tech debt tracking |
| Agent can't resume work across sessions | Dim 7: no handoff protocol | Implement `7.3` descriptive commits + progress logs |
| MCP tools leak data or have excess access | Dim 8: no protocol hygiene | Apply `8.6` least-privilege scoping; treat output as untrusted |

---

## Golden Principles

1. **Prefer shared utilities over local implementations**
2. **Never guess data structures** — Read the source of truth. Validate at boundaries.
3. **Repository is the single source of truth**
4. **Small PRs, always** — One feature, one fix, one concern per PR.
5. **Verify before claiming done** — Run tests, check types, view actual output.
6. **Clean up after yourself** — Every session ends with codebase in better or equal state.
7. **Test results are context, not evidence** — LLM-written tests may use circular assertions or excessive mocking. Passing tests confirm the happy path; independent adversarial verification confirms correctness.

---

## Key Metrics

- **PRs merged/engineer/day**: Throughput (target: 2-4)
- **Change failure rate**: Harness effectiveness (target: <10%)
- **AI code rework rate**: Generation quality (target: <20%)
- **Test coverage on AI code**: Verification coverage (target: >80%)
- **Mean time to correct (MTTC)**: Feedback loop speed (target: <30 min)
- **Documentation freshness**: Knowledge currency (target: <30 days stale)
- **Prompt cache hit rate**: Context efficiency (target: >60%)
- **Session resume success rate**: Durable execution (target: >90%)
- **MCP tool count**: Tool hygiene (target: <10 always-loaded)

---

## Key Principles

1. **Evidence over opinion.** Every finding cites a specific file, config, or absence.
2. **Actionable over theoretical.** Every gap maps to a concrete fix.
3. **Progressive improvement.** Quick wins first, then strategic investments.
4. **Harness over model.** Improve the harness before upgrading the model.
5. **Mechanical over cultural.** Prefer CI/linter enforcement over code review conventions.
6. **Match the user's language.** Detect the user's communication language in Step 0, write the entire audit report in that language, and use the corresponding language suffix in the saved filename (see Step 3).

---

## Reference Files

Read these as needed — do not load all at once:

| File | Purpose | When to Read |
|------|---------|-------------|
| `references/checklist.md` | 44-item audit checklist with PASS/PARTIAL/FAIL criteria | Always during Audit mode |
| `references/scoring-rubric.md` | Scoring methodology, borderline guidance, project-type adaptations | When scoring is ambiguous |
| `references/control-theory.md` | Control theory framework | When explaining "why this matters" |
| `references/improvement-patterns.md` | Quick wins and strategic investments | When writing improvement roadmaps |
| `references/automation-templates.md` | Template index | When generating deliverables |
| `references/agents-md-guide.md` | AGENTS.md authoring guide | When implementing agent instruction files |
| `references/ci-cd-patterns.md` | CI/CD pipeline patterns by ecosystem | When implementing CI pipelines |
| `references/linting-strategy.md` | Type checking and linting setup | When implementing linting |
| `references/testing-patterns.md` | Testing strategies | When implementing testing |
| `references/review-practices.md` | Code review for AI code | When implementing review processes |
| `references/long-running-agents.md` | Multi-session agent patterns | When implementing long-running workflows |
| `references/cache-stability.md` | Cache stability and context | When diagnosing context overflow |
| `references/durable-execution.md` | Crash recovery | When implementing resilience |
| `references/protocol-hygiene.md` | MCP/ACP/A2A trust boundaries | When auditing tool safety |
| `references/adversarial-verification.md` | Three-layer verification, anti-rationalization, structural nudges, permission isolation | When implementing or auditing verification systems |
| `references/monorepo-patterns.md` | Monorepo audit and patterns | When auditing or designing for monorepos |

## Data Files

Structured knowledge — read to configure audit parameters:

| File | Purpose | When to Read |
|------|---------|-------------|
| `data/profiles.json` | 17 project type profiles with weight overrides | Audit Step 0 |
| `data/stages.json` | 3 lifecycle stages with active item subsets | Audit Step 0 |
| `data/ecosystems.json` | 12 ecosystem detection rules and tool mappings | Audit Step 1, Mode 2, Mode 3 |
| `data/checklist-items.json` | 44 items in machine-readable format | Programmatic audit processing |

## Executable Assets

| Asset | Purpose | When to Use |
|-------|---------|-------------|
| `scripts/harness-audit.sh` | Bash audit scanner (JSON/Markdown/Blueprint) | Audit Step 1 on macOS/Linux |
| `scripts/harness-audit.ps1` | PowerShell audit scanner (JSON/Markdown/Blueprint) | Audit Step 1 on Windows |
| `templates/universal/` | 6 language-agnostic templates | Audit Step 4 |
| `templates/ci/` | CI pipeline templates (GitHub Actions, GitLab, Azure) | Audit Step 4 |
| `templates/linting/` | Boundary rules (ESLint, import-linter, depguard, clippy) | Audit Step 4 |
| `templates/init/` | Environment recovery scripts (Bash, PowerShell) | Audit Step 4 |

### Blueprint Mode

Generate an actionable blueprint with gap analysis, template recommendations, and ecosystem-specific CI commands:

```bash
# Bash
bash scripts/harness-audit.sh /path/to/repo --profile backend-api --stage growth --blueprint

# PowerShell
pwsh scripts/harness-audit.ps1 -RepoRoot /path/to/repo -Profile backend-api -Stage growth -Blueprint

# Save to file
bash scripts/harness-audit.sh /path/to/repo --blueprint --output reports/
```

The blueprint includes: scan results table, gap-by-gap recommendations with priority and effort, quick wins list, recommended template paths, and ecosystem CI commands.

### Persist Mode (Master + Overrides)

Save the blueprint to `harness-system/MASTER.md` in the target repo for cross-session reuse:

```bash
# Bash
bash scripts/harness-audit.sh /path/to/repo --profile backend-api --stage growth --persist

# PowerShell
pwsh scripts/harness-audit.ps1 -RepoRoot /path/to/repo -Profile backend-api -Stage growth -Persist
```

This creates:

```
harness-system/
├── MASTER.md           # Global harness strategy (profile, stage, gaps, recommendations)
└── modules/            # Module-specific overrides (created manually as needed)
    ├── ci.md           # CI/CD decisions that differ from MASTER
    ├── testing.md      # Testing strategy overrides
    └── safety.md       # Safety rails overrides
```

**Cross-session retrieval**: When starting a new session on a topic (e.g., "improve CI"), read `harness-system/MASTER.md` first, then check if `harness-system/modules/ci.md` exists. Module-level rules override MASTER.

### Output Formats

| Format | Flag | Use Case |
|--------|------|----------|
| JSON (default) | `--format json` | Machine-readable, agent post-processing |
| Markdown | `--format markdown` | Human-readable scan report |
| Blueprint | `--blueprint` | Full gap analysis with recommendations |
