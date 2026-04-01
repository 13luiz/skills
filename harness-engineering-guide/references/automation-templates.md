# Automation Templates — Gap-Driven Recommendations

Ready-to-use templates for common harness engineering artifacts. Instead of browsing all templates, use the decision tree below to find the **single correct template** for each audit gap.

---

## Decision Tree: Audit Gap → Template

For each gap found in the audit report, follow the matching path to get one specific template file.

### Gap 1.1 — No Agent Instruction File

→ `templates/universal/agents-md-scaffold.md`

### Gap 2.1 — No CI Pipeline

Detect CI platform from repo:
- `.github/workflows/` exists or GitHub repo → `templates/ci/github-actions/standard-pipeline.yml`
- `.gitlab-ci.yml` exists or GitLab repo → `templates/ci/gitlab-ci.yml`
- `azure-pipelines.yml` exists or Azure DevOps → `templates/ci/azure-pipelines.yml`
- Unknown → default to `templates/ci/github-actions/standard-pipeline.yml`

Fill CI command placeholders using `data/ecosystems.json` for the detected ecosystem.

### Gap 2.5 — No Dependency Direction Enforcement

Detect ecosystem from repo (use `data/ecosystems.json` detect fields):
- `package.json` → `templates/linting/eslint-boundary-rule.js`
- `pyproject.toml` / `requirements.txt` → `templates/linting/import-linter.cfg`
- `go.mod` → `templates/linting/depguard.yml`
- `Cargo.toml` → `templates/linting/clippy-workspace.toml`
- Other ecosystems → implement custom lint rule (no template available; document the rule in AGENTS.md)

### Gap 4.4 — No Formalized Done Criteria

→ `templates/universal/feature-checklist.json`

### Gap 5.2 — No Documentation Freshness Mechanism

→ `templates/ci/github-actions/doc-freshness.yml` (GitHub Actions only; adapt for other CI platforms)

### Gap 6.2 — No Recurring Cleanup

→ `templates/universal/doc-gardening-prompt.md`

### Gap 6.3 — No Tech Debt Tracking

→ `templates/universal/tech-debt-tracker.json`

### Gap 7.1 — No Task Decomposition Strategy

→ `templates/universal/execution-plan.md`

### Gap 7.4 — No Environment Recovery

Detect OS from context:
- Unix/macOS/Linux or WSL → `templates/init/init.sh`
- Windows (PowerShell) → `templates/init/init.ps1`

---

## Directory Structure

```
templates/
├── universal/                    # Language-agnostic (5 files)
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
│   ├── eslint-boundary-rule.js   # JS/TS (Node ecosystem)
│   ├── import-linter.cfg         # Python ecosystem
│   ├── depguard.yml              # Go ecosystem
│   └── clippy-workspace.toml     # Rust ecosystem
└── init/                         # Environment recovery scripts
    ├── init.sh                   # Bash (auto-detects ecosystem)
    └── init.ps1                  # PowerShell equivalent
```

## How to Use

1. Identify the gap from the audit report (item ID like 2.1, 2.5, 7.4)
2. Follow the decision tree above — it resolves to **one** template file
3. Read that template file
4. Replace placeholders (marked with `[brackets]` or `[ECOSYSTEM: ...]` comments) with project-specific values from `data/ecosystems.json`
5. Copy into the target project and commit

Do **not** install all templates. Only apply what the audit identified as a gap.
