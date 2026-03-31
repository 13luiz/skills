# Harness Engineering Guide

A guide to auditing, designing, and implementing environment constraints and feedback loops for AI coding agents.

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
Evaluate the repo's harness maturity across 8 dimensions with 43 check items. Outputs an A–F graded report with an improvement roadmap.

### Mode 2: Implement
Set up specific harness components on demand: AGENTS.md, CI pipelines, lint rules, testing strategies, and more.

### Mode 3: Design
Design a complete harness strategy scaled to team size, across three maturity levels (Solo / Small Team / Production).

## Directory Structure

```
harness-engineering-guide/
├── README.md                  ← You are here (English)
├── README.cn.md               ← Chinese version
├── SKILL.md                   ← Agent entry point, orchestrates three modes
├── scripts/
│   ├── harness-audit.sh       ← Bash audit script (outputs JSON)
│   └── harness-audit.ps1      ← PowerShell audit script (Windows)
├── templates/
│   ├── agents-md-scaffold.md  ← AGENTS.md scaffold
│   ├── doc-freshness-ci.yml   ← Documentation freshness CI check
│   ├── eslint-boundary-rule.js← Architecture boundary ESLint rule
│   ├── tech-debt-tracker.json ← Tech debt tracker
│   ├── doc-gardening-prompt.md← Doc-gardening agent prompt
│   ├── feature-checklist.json ← Feature verification checklist
│   ├── init.sh                ← Environment recovery script
│   └── execution-plan.md      ← Execution plan template
├── evals/
│   └── evals.json             ← 12 evaluation scenarios
└── references/
    ├── checklist.md           ← 8-dimension, 43-item audit checklist
    ├── scoring-rubric.md      ← Scoring methodology & grade thresholds
    ├── control-theory.md      ← Control theory foundation
    ├── improvement-patterns.md← Improvement patterns (Quick Wins + Strategic)
    ├── automation-templates.md← Template index (points to templates/)
    ├── agents-md-guide.md     ← AGENTS.md authoring guide
    ├── ci-cd-patterns.md      ← CI/CD pipeline patterns
    ├── linting-strategy.md    ← Linting & type checking strategy
    ├── testing-patterns.md    ← Testing strategy
    ├── review-practices.md    ← Code review practices
    ├── long-running-agents.md ← Multi-session agent task patterns
    ├── cache-stability.md     ← Cache stability & context management
    ├── durable-execution.md   ← Durable execution & crash recovery
    └── protocol-hygiene.md    ← Protocol hygiene (MCP/ACP/A2A)
```

## Key References

- **OpenAI**: Shipped 1 million lines with zero human-written code in 5 months — the key was harness investment, not model upgrades
- **LangChain**: By changing only the harness (not the model), Terminal Bench 2.0 score jumped from 52.8% to 66.5% (Top 30 → Top 5)
- **Anthropic**: Generator-Evaluator separation is the most effective harness pattern for long-running agents

## Use Cases

- Assess whether a repo is ready for AI coding agents
- Design an agent-friendly engineering system for a new project
- Diagnose declining quality of AI-generated code
- Establish AGENTS.md / CI / testing / review workflows for a team
- Understand why improving the harness beats upgrading the model
