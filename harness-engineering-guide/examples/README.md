# Example Audit Reports

This directory holds example harness engineering audit reports from well-known open-source repositories. These serve as reference benchmarks for calibrating scores and understanding what different grades look like in practice.

## Expected Structure

```
examples/
├── README.md                              ← You are here
├── <date>_<repo-name>_audit.md            ← Single-repo audit report
└── <date>_<repo-name>_monorepo/           ← Monorepo audit
    ├── aggregate.md                       ← Overall monorepo score
    ├── <package-a>.md                     ← Per-package report
    └── <package-b>.md                     ← Per-package report
```

## Naming Convention

- **Date**: `YYYY-MM-DD` format
- **Repo name**: lowercase, hyphens for spaces
- **Format**: Markdown (`.md`) for human-readable, JSON (`.json`) for machine-readable

Examples:
- `2026-04-01_next.js_audit.md`
- `2026-04-01_langchain_monorepo/aggregate.md`
- `2026-04-01_rust-analyzer_audit.md`

## What Makes a Good Example

A good example report should:

1. **Represent a real open-source repository** — not a synthetic test case
2. **Include the full audit report** — all dimensions scored with evidence
3. **Show the profile and stage used** — so readers understand the weight adjustments
4. **Include the improvement roadmap** — actionable recommendations
5. **Cover different project types** — aim for diversity across profiles

## Existing Examples

| Report | Profile | Stage | Language |
|--------|---------|-------|----------|
| `2026-04-01_openclaw_audit.md` | — | — | English |
| `2026-04-01_openclaw_audit.zh.md` | — | — | Chinese |

## Planned Examples

The following well-known repositories are candidates for additional example audits:

- [ ] A large TypeScript monorepo (e.g., Next.js, Turborepo)
- [ ] A Python backend service (e.g., FastAPI, Django)
- [ ] A Rust CLI tool (e.g., ripgrep, bat)
- [ ] A Go microservice (e.g., from Kubernetes ecosystem)
- [ ] A frontend SPA (e.g., React-based)
- [ ] A data/ML pipeline project
- [ ] An early-stage startup project (bootstrap stage)
