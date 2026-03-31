# Audit Reports Output

This directory is the default output location for generated harness engineering audit reports.

## Usage

```bash
# Save audit output to this directory
bash scripts/harness-audit.sh /path/to/repo --output reports/

# With profile and stage
bash scripts/harness-audit.sh /path/to/repo --profile backend-api --stage growth --output reports/
```

## File Naming

Reports are automatically named with the pattern:

```
<YYYY-MM-DD>_<repo-name>_audit.json
```

For monorepo audits:
```
<YYYY-MM-DD>_<repo-name>_monorepo/
├── aggregate.json
├── <package-a>.json
└── <package-b>.json
```

## Historical Comparison

Timestamp-based naming supports tracking audit scores over time. Compare JSON reports across dates to measure improvement.

## Note

This directory is `.gitkeep`'d and its contents (except this README) should be in `.gitignore` to avoid committing audit results of other repositories.
