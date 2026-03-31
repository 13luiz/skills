# Harness Engineering Guide

A comprehensive skill for auditing, designing, and implementing environment constraints and feedback loops for AI coding agents. Supports **17 project types**, **11 language ecosystems**, and **3 lifecycle stages**.

## What is Harness Engineering?

**Agent = Model + Harness.** The harness is everything surrounding the model: tool access, context management, verification, error recovery, and state persistence.

From a control theory perspective, every effective harness implements four elements:

| Element | In the Harness | Example |
|---------|---------------|---------|
| **Goal State** | Architecture docs, quality standards, done criteria | ARCHITECTURE.md, lint rules |
| **Sensor** | Tests, linters, logs, metrics, screenshots | CI checks, Playwright |
| **Actuator** | Auto-fix, CI gates, rollbacks, refactoring PRs | pre-commit hooks, blocked PRs |
| **Feedback Loop** | CI fail→fix→pass, review→lint rule | quality score trends |

Missing any one element makes the system **open-loop** — unable to self-correct.

## Quick Start

Say any of the following to an AI agent to trigger this skill:

- "Review my repo for AI coding readiness"
- "Audit this repo's harness maturity"
- "Set up AGENTS.md for my project"
- "Design a harness strategy for my new project"
- "Why does my AI agent keep writing bad code?"

## Three Modes

### Mode 1: Audit
Evaluate the repo's harness maturity across 8 dimensions with 43 check items. Configurable by **project type profile** and **lifecycle stage**. Outputs an A–F graded report with an improvement roadmap. Supports monorepo per-package auditing.

### Mode 2: Implement
Set up specific harness components on demand: AGENTS.md, CI pipelines, lint rules, testing strategies, and more. Templates available for multiple CI platforms and language ecosystems.

### Mode 3: Design
Design a complete harness strategy scaled to team size, across three maturity levels (Solo / Small Team / Production).

## Features

### Project Type Profiles (17 types)
Adjusts audit dimension weights and skips irrelevant items based on project type:

| Profile | Focus |
|---------|-------|
| `frontend-spa` / `frontend-ssr` | UI visibility, E2E testing, component architecture |
| `backend-api` / `backend-microservice` | Observability, safety, distributed tracing |
| `fullstack` | Default weights, dependency direction |
| `library` / `cli-tool` | Testing, mechanical constraints, reduced observability |
| `desktop-app` / `mobile-app` | UI automation, multi-process architecture |
| `system-infra` | Safety, rollback, type safety |
| `game` | Architecture docs, cache-friendly design, asset pipeline |
| `data-ml` | Long-running tasks, durable execution, progress tracking |
| `devops-iac` | Safety rails, human confirmation, rollback |
| `script-automation` | Lint, test, safety basics |
| `browser-extension` / `smart-contract` | Security, E2E testing |
| `monorepo` | Cross-package boundaries, entropy management |

### Lifecycle Stages (3 stages)
Reduces audit scope for projects at different maturity levels:

| Stage | Active Items | Focus |
|-------|-------------|-------|
| **Bootstrap** (<2k LOC) | 9 items | Foundations only |
| **Growth** (2k-50k LOC) | 27 items | Constraints + testing + early feedback |
| **Mature** (50k+ LOC) | 43 items | Full audit |

### Multi-Ecosystem Support (11 ecosystems)
Detection rules, tool recommendations, and CI commands for:
Node.js/TypeScript, Python, Go, Rust, Ruby, Java, C#/.NET, Swift, Kotlin, Dart/Flutter

### Enhanced Audit Scripts
Content-level analysis beyond file existence:
- Structured logging framework detection
- Metrics/tracing configuration detection
- AGENTS.md quality analysis (line count, doc links, command refs)
- Tech debt density scanning (TODO/FIXME/HACK)
- Monorepo auto-detection and package discovery

### Multi-Platform Templates
- **CI**: GitHub Actions, GitLab CI, Azure DevOps
- **Linting boundaries**: ESLint (JS/TS), import-linter (Python), depguard (Go), clippy (Rust)
- **Environment recovery**: Bash and PowerShell

## Directory Structure

```
harness-engineering-guide/
├── SKILL.md                           ← Agent entry point (thin orchestrator + Quick Reference)
├── README.md                          ← You are here (English)
├── README.cn.md                       ← Chinese version
├── data/
│   ├── profiles.json                  ← 17 project type profiles with weight overrides
│   ├── stages.json                    ← 3 lifecycle stages with active item subsets
│   ├── ecosystems.json                ← 11 ecosystem detection rules and tool mappings
│   └── checklist-items.json           ← 43 items in machine-readable format
├── scripts/
│   ├── harness-audit.sh               ← Enhanced Bash audit (content analysis + profiles/stages)
│   ├── harness-audit.ps1              ← Enhanced PowerShell audit
│   └── utils/
│       └── content-analyzers.sh       ← Content-level analysis functions (Dim 3/5/6)
├── templates/
│   ├── universal/                     ← Language-agnostic templates (5 files)
│   ├── ci/                            ← CI templates: GitHub Actions, GitLab, Azure
│   ├── linting/                       ← Boundary rules: ESLint, import-linter, depguard, clippy
│   └── init/                          ← Environment recovery: Bash, PowerShell
├── reports/                           ← Audit report output directory
├── examples/                          ← Example audit reports (placeholder)
├── references/                        ← Deep-dive reference docs (15 files)
│   ├── checklist.md                   ← 8-dimension, 43-item audit checklist
│   ├── scoring-rubric.md              ← Scoring methodology & profile/stage adjustments
│   ├── control-theory.md              ← Control theory foundation
│   ├── improvement-patterns.md        ← Quick wins & strategic investments (with stage tags)
│   ├── automation-templates.md        ← Template index
│   ├── agents-md-guide.md             ← AGENTS.md authoring guide
│   ├── ci-cd-patterns.md              ← CI/CD pipeline patterns
│   ├── linting-strategy.md            ← Linting & type checking strategy
│   ├── testing-patterns.md            ← Testing strategy
│   ├── review-practices.md            ← Code review practices
│   ├── long-running-agents.md         ← Multi-session agent patterns
│   ├── cache-stability.md             ← Cache stability & context management
│   ├── durable-execution.md           ← Durable execution & crash recovery
│   ├── protocol-hygiene.md            ← Protocol hygiene (MCP/ACP/A2A)
│   └── monorepo-patterns.md           ← Monorepo audit and design patterns
└── evals/
    └── evals.json                     ← 19 evaluation scenarios
```

## Audit Script Usage

```bash
# Basic audit (backward compatible)
bash scripts/harness-audit.sh /path/to/repo

# With project type profile
bash scripts/harness-audit.sh /path/to/repo --profile backend-api

# With lifecycle stage
bash scripts/harness-audit.sh /path/to/repo --stage bootstrap

# Monorepo mode
bash scripts/harness-audit.sh /path/to/repo --monorepo

# Combined with output
bash scripts/harness-audit.sh /path/to/repo --profile backend-api --stage growth --output reports/

# PowerShell equivalent
pwsh scripts/harness-audit.ps1 -RepoRoot /path/to/repo -Profile backend-api -Stage growth
```

## Key References

- **OpenAI**: Shipped 1 million lines with zero human-written code in 5 months — harness investment, not model upgrades
- **LangChain**: Changing only the harness jumped Terminal Bench 2.0 from 52.8% to 66.5% (Top 30 → Top 5)
- **Anthropic**: Generator-Evaluator separation is the most effective pattern for long-running agents
