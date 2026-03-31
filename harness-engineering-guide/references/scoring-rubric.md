# Scoring Rubric

Detailed guidance on scoring each checklist item, handling edge cases, and calculating final grades.

---

## Scoring Methodology

### Per-Item Scoring

| Score | Label | Points | Meaning |
|-------|-------|--------|---------|
| PASS | Full credit | 1.0 | Practice in place and working effectively |
| PARTIAL | Half credit | 0.5 | Practice exists but has significant gaps |
| FAIL | No credit | 0.0 | Practice absent or non-functional |

### Dimension Score Calculation

```
dimension_score = (sum of item points / number of items in dimension) * 100
```

### Final Score Calculation

```
final_score = sum(dimension_score * dimension_weight for each dimension)
```

Dimension weights:

| Dimension | Weight |
|-----------|--------|
| 1. Architecture Docs & Knowledge | 0.15 |
| 2. Mechanical Constraints | 0.20 |
| 3. Feedback Loops & Observability | 0.15 |
| 4. Testing & Verification | 0.15 |
| 5. Context Engineering | 0.10 |
| 6. Entropy Management | 0.10 |
| 7. Long-Running Task Support | 0.10 |
| 8. Safety Rails | 0.05 |

### Grade Thresholds

| Grade | Score | Description |
|-------|-------|-------------|
| A | 85-100 | Strong harness. Agent code has robust mechanical safeguards. Control loops closed at multiple levels. |
| B | 70-84 | Good foundation. Most critical practices in place but some feedback loops open or enforcement inconsistent. |
| C | 55-69 | Basic practices present. CI and tests exist but constraints not agent-aware, docs insufficient, no entropy management. |
| D | 40-54 | Significant gaps. Some building blocks exist but system lacks constraint and feedback infrastructure agents need. |
| F | 0-39 | No meaningful harness. Agents operating in this repo are essentially unaudited. |

---

## Borderline Guidance

### PARTIAL vs FAIL

The key question: **does the practice provide any meaningful constraint on agent behavior?**

- Linter configured but only runs locally, never in CI -> PARTIAL (constrains developers who remember, not automated pipelines)
- Linter not configured at all -> FAIL
- Documentation severely outdated (>6 months in active project) -> PARTIAL tending toward FAIL
- Tests with 0% pass rate -> FAIL (broken tests are worse than none — they create noise)

### PASS vs PARTIAL

The key question: **would this practice catch an agent going off the rails?**

- CI runs linter but almost no rules enabled -> PARTIAL (infrastructure there, teeth missing)
- CI runs linter with comprehensive rules and blocks PRs -> PASS
- AGENTS.md exists but is 2000 lines -> PARTIAL (violates progressive disclosure)

---

## Project-Type Adaptations

### Libraries / CLI tools
- Dimension 3 items 3.2-3.4 may not apply for non-service code. Substitute: "Can the agent see tool output and error messages clearly?"
- Dimension 8 applies to CI/GitHub token scoping instead of production credentials

### Backend services
- All dimensions apply fully. Observability and safety especially critical.

### Frontend apps
- UI visibility (3.4) and E2E testing (4.5) are high priority
- Dependency direction rules apply to component architecture

### Early-stage / small projects (<1000 LOC)
- Score dimensions 6 (Entropy) and 7 (Long-Running Tasks) more leniently
- Focus the report on foundations (dimensions 1-4)

### Monorepos
- Evaluate per-package where possible
- Note cross-package boundary enforcement

### Personal projects
- Reduce weight of dimension 8 mentally
- Note gaps as "be aware" rather than critical findings

---

## Reporting Format

```markdown
## Dimension Scores

| # | Dimension | Items | Passed | Score | Weighted | Control Element |
|---|-----------|-------|--------|-------|----------|----------------|
| 1 | Arch Docs & Knowledge | 5 | 3/5 | 60% | 9.0 | Goal State |
| 2 | Mechanical Constraints | 7 | 5/7 | 71% | 14.3 | Actuator |
| 3 | Feedback & Observability | 5 | 2/5 | 40% | 6.0 | Sensor |
| 4 | Testing & Verification | 6 | 4/6 | 67% | 10.0 | Sensor + Actuator |
| 5 | Context Engineering | 5 | 2/5 | 40% | 4.0 | Goal State |
| 6 | Entropy Management | 4 | 1/4 | 25% | 2.5 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 2/6 | 33% | 3.3 | Feedback Loop |
| 8 | Safety Rails | 6 | 3/6 | 50% | 2.5 | Actuator (protective) |
| **Total** | | **43** | **22/43** | | **51.6** |

**Grade: D (51.6/100)**
```

Use PARTIAL scores where applicable — count as 0.5 in the "Passed" column.

---

## Score Interpretation

**A (85-100): "Ship confidently with agents"**
- Agents work autonomously with high reliability
- Mistakes caught mechanically before landing
- System self-corrects through feedback loops

**B (70-84): "Agents work but need oversight"**
- Core safeguards in place
- Some open feedback loops; human review still needed for certain changes
- Generally reliable but edge cases may slip

**C (55-69): "Agents can help but watch closely"**
- Basic CI and testing exists
- Quality varies significantly
- Manual review essential for every change

**D (40-54): "Use agents for isolated tasks only"**
- Constraints too weak for autonomous operation
- Useful for boilerplate or well-defined micro-tasks
- Complex tasks need significant cleanup

**F (0-39): "Fix the harness before using agents"**
- Using agents will likely cause more harm than good
- Start with quick wins from the improvement roadmap
