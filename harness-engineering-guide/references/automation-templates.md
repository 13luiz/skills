# Automation Templates — Index

Ready-to-use templates for common harness engineering artifacts. Templates are organized by category under `templates/` with subdirectories for language-agnostic, CI platform-specific, ecosystem-specific linting, and environment recovery.

---

## Directory Structure

```
templates/
├── universal/                    # Language-agnostic templates
│   ├── agents-md-scaffold.md     # AGENTS.md scaffold
│   ├── execution-plan.md         # Multi-phase task plan
│   ├── feature-checklist.json    # Feature verification checklist
│   ├── tech-debt-tracker.json    # Per-module quality scores
│   └── doc-gardening-prompt.md   # Doc maintenance agent prompt
├── ci/                           # CI pipeline templates
│   ├── github-actions/
│   │   ├── standard-pipeline.yml # Full CI pipeline skeleton
│   │   └── doc-freshness.yml     # Doc staleness detection
│   ├── gitlab-ci.yml             # GitLab CI equivalent
│   └── azure-pipelines.yml       # Azure DevOps equivalent
├── linting/                      # Architectural boundary rules
│   ├── eslint-boundary-rule.js   # JS/TS layer enforcement
│   ├── import-linter.cfg         # Python import boundaries
│   ├── depguard.yml              # Go dependency guard
│   └── clippy-workspace.toml     # Rust workspace clippy config
└── init/                         # Environment recovery scripts
    ├── init.sh                   # Bash (auto-detects ecosystem)
    └── init.ps1                  # PowerShell equivalent
```

## Available Templates

| # | Template | File | Use When |
|---|----------|------|----------|
| 1 | **AGENTS.md Scaffold** | `templates/universal/agents-md-scaffold.md` | Creating agent instruction files for any project |
| 2 | **CI Pipeline (GitHub)** | `templates/ci/github-actions/standard-pipeline.yml` | Setting up CI with lint/typecheck/test/build stages |
| 3 | **CI Pipeline (GitLab)** | `templates/ci/gitlab-ci.yml` | GitLab CI equivalent of the standard pipeline |
| 4 | **CI Pipeline (Azure)** | `templates/ci/azure-pipelines.yml` | Azure DevOps equivalent of the standard pipeline |
| 5 | **Doc Freshness CI** | `templates/ci/github-actions/doc-freshness.yml` | Detecting stale documentation in GitHub Actions |
| 6 | **ESLint Boundary Rule** | `templates/linting/eslint-boundary-rule.js` | Enforcing JS/TS dependency direction |
| 7 | **Python Import Linter** | `templates/linting/import-linter.cfg` | Enforcing Python import boundaries |
| 8 | **Go Depguard** | `templates/linting/depguard.yml` | Enforcing Go package dependency direction |
| 9 | **Rust Clippy Config** | `templates/linting/clippy-workspace.toml` | Workspace-level Rust clippy enforcement |
| 10 | **Tech Debt Tracker** | `templates/universal/tech-debt-tracker.json` | Tracking per-module quality scores and trends |
| 11 | **Doc-Gardening Prompt** | `templates/universal/doc-gardening-prompt.md` | Scheduling automated documentation maintenance |
| 12 | **Feature Checklist** | `templates/universal/feature-checklist.json` | Tracking feature completion with machine-readable status |
| 13 | **Environment Recovery (Bash)** | `templates/init/init.sh` | Bootstrapping dev environment with health checks |
| 14 | **Environment Recovery (PS)** | `templates/init/init.ps1` | PowerShell equivalent of init.sh |
| 15 | **Execution Plan** | `templates/universal/execution-plan.md` | Structuring multi-phase agent tasks with handoff notes |

## How to Use

1. Identify the gap from the audit report
2. Read the appropriate template file
3. Select the right ecosystem variant (use `data/ecosystems.json` for CI command placeholders)
4. Copy into the target project
5. Replace placeholders (marked with `[brackets]` or `[ECOSYSTEM: ...]` comments) with project-specific values
6. Commit and integrate into the workflow

## Mapping to Audit Gaps

| Gap Found | Recommended Templates |
|-----------|----------------------|
| No agent instruction file (1.1) | Template 1: AGENTS.md Scaffold |
| No CI pipeline (2.1) | Templates 2-4: CI Pipeline (pick your platform) |
| No doc freshness mechanism (5.2) | Template 5: Doc Freshness CI |
| No dependency enforcement (2.5) | Templates 6-9: Boundary Rule (pick your ecosystem) |
| No tech debt tracking (6.3) | Template 10: Tech Debt Tracker |
| No recurring cleanup (6.2) | Template 11: Doc-Gardening Prompt |
| No formalized done criteria (4.4) | Template 12: Feature Checklist |
| No environment recovery (7.4) | Templates 13-14: init.sh / init.ps1 |
| No task decomposition (7.1) | Template 15: Execution Plan |
