# Automation Templates — Index

Ready-to-use templates for common harness engineering artifacts. Each template lives in `templates/` as a standalone file you can copy directly into a project.

---

## Available Templates

| # | Template | File | Use When |
|---|----------|------|----------|
| 1 | **AGENTS.md Scaffold** | `templates/agents-md-scaffold.md` | Creating agent instruction files for any project |
| 2 | **Documentation Freshness CI** | `templates/doc-freshness-ci.yml` | Adding automated doc staleness detection to GitHub Actions |
| 3 | **Architecture Boundary Lint Rule** | `templates/eslint-boundary-rule.js` | Enforcing dependency direction in JavaScript/TypeScript |
| 4 | **Tech Debt Tracker** | `templates/tech-debt-tracker.json` | Tracking per-module quality scores and trends |
| 5 | **Doc-Gardening Agent Prompt** | `templates/doc-gardening-prompt.md` | Scheduling automated documentation maintenance |
| 6 | **Feature Verification Checklist** | `templates/feature-checklist.json` | Tracking feature completion with machine-readable status |
| 7 | **Environment Recovery Script** | `templates/init.sh` | Bootstrapping dev environment with health checks |
| 8 | **Execution Plan** | `templates/execution-plan.md` | Structuring multi-phase agent tasks with handoff notes |

## How to Use

1. Read the template file for the artifact you need
2. Copy it into the target project
3. Replace placeholders (marked with `[brackets]`) with project-specific values
4. Commit and integrate into your workflow

## Mapping to Audit Gaps

When the audit identifies gaps, offer the corresponding template:

| Gap Found | Recommended Template |
|-----------|---------------------|
| No agent instruction file (1.1) | Template 1: AGENTS.md Scaffold |
| No doc freshness mechanism (5.2) | Template 2: Doc Freshness CI |
| No dependency direction enforcement (2.5) | Template 3: ESLint Boundary Rule |
| No tech debt tracking (6.3) | Template 4: Tech Debt Tracker |
| No recurring cleanup (6.2) | Template 5: Doc-Gardening Prompt |
| No formalized done criteria (4.4) | Template 6: Feature Checklist |
| No environment recovery (7.4) | Template 7: init.sh |
| No task decomposition (7.1) | Template 8: Execution Plan |
