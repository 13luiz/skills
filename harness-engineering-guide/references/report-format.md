# Audit Report Format

Standard report template for Mode 1 (Audit) output. The report should be generated in the user's communication language.

---

## Report Template

```markdown
# Harness Engineering Audit: [Project Name]

**Date**: [YYYY-MM-DD]
**Profile**: [project type] | **Stage**: [lifecycle stage]
**Ecosystem**: [detected ecosystem]
**Language**: [report language] ([ISO 639-1 code])

## Overall Grade: [Letter] ([Score]/100)

## Executive Summary
[2-3 sentences on overall harness posture, key strengths, and critical gaps]

## Audit Parameters
| Parameter | Value |
|-----------|-------|
| Profile | [type] — [weight adjustments applied] |
| Stage | [stage] — [X of 45 items active] |
| Language | [language name] ([code]) |
| Skipped Items | [list with reasons] |

## Dimension Scores
| # | Dimension | Items | Passed | Score | Weight | Weighted | Control Element |
|---|-----------|-------|--------|-------|--------|----------|----------------|
| 1 | Architecture Docs | X/5 | ... | ... | 15% | ... | Goal State |
| 2 | Mechanical Constraints | X/7 | ... | ... | 20% | ... | Actuator |
| 3 | Feedback & Observability | X/5 | ... | ... | 15% | ... | Sensor |
| 4 | Testing & Verification | X/7 | ... | ... | 15% | ... | Sensor+Actuator |
| 5 | Context Engineering | X/5 | ... | ... | 10% | ... | Goal State |
| 6 | Entropy Management | X/4 | ... | ... | 10% | ... | Feedback Loop |
| 7 | Long-Running Tasks | X/6 | ... | ... | 10% | ... | Feedback Loop |
| 8 | Safety Rails | X/6 | ... | ... | 5% | ... | Actuator (Protective) |

## Detailed Findings
### 1. Architecture Documentation & Knowledge Management
[Per-item PASS/PARTIAL/FAIL with evidence and maturity annotations where applicable]

### 2. Mechanical Constraints
[...]

### 3. Feedback Loops & Observability
[...]

### 4. Testing & Verification
[...]

### 5. Context Engineering
[...]

### 6. Entropy Management & Garbage Collection
[...]

### 7. Long-Running Task Support
[...]

### 8. Safety Rails
[...]

## Improvement Roadmap
### Quick Wins (implement in 1 day)
1. [Specific actionable item with reference to improvement pattern]
...
### Strategic Investments (1-4 weeks)
1. [Specific actionable item with reference to improvement pattern]
...

## Recommended Templates
[Offer specific templates from templates/ based on gaps found]
```

---

## File Naming Convention

```
reports/<YYYY-MM-DD>_<repo-name>_audit[.<lang>].md
```

- English reports omit the language suffix: `2026-04-01_acme_audit.md`
- Non-English reports include the ISO 639-1 suffix: `2026-04-01_acme_audit.zh.md`
- Use the language code determined in Audit Step 0

---

## Grade Scale

| Grade | Score Range | Meaning |
|-------|------------|---------|
| A | 85-100 | Production-ready harness with comprehensive controls |
| B | 70-84 | Good foundations with specific gaps to address |
| C | 55-69 | Partial harness; critical components missing |
| D | 40-54 | Minimal harness; significant investment needed |
| F | 0-39 | No meaningful harness infrastructure |
