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
- AGENTS.md exists but is 200+ lines -> PARTIAL (violates progressive disclosure)

---

## Dimension Boundary Disambiguation

When scoring, agents may encounter items that seem to overlap between dimensions. Use these guidelines to assign items to the correct dimension.

### Dim 2 (Mechanical Constraints) vs Dim 6 (Entropy Management)

**The question**: "Is this preventing a specific violation (Dim 2) or cleaning up accumulated drift (Dim 6)?"

- **2.2 Linter Enforcement** asks: does a linter exist and block in CI? This is infrastructure.
- **6.4 AI Slop Detection** asks: are there rules specifically targeting AI-generated patterns (duplicate utilities, dead code, over-abstraction)? This is AI-aware cleanup.

A project can PASS 2.2 (linter exists and blocks) but FAIL 6.4 (no AI-specific rules within the linter). The linter is the tool (Dim 2); the AI-specific rules are the policy (Dim 6).

### Dim 3 (Feedback & Observability) vs Dim 5 (Context Engineering)

**The question**: "Is this about runtime signals (Dim 3) or information architecture (Dim 5)?"

- **Dim 3** measures runtime observability: structured logs, metrics, tracing, screenshots, diagnostic errors. These are signals generated during execution.
- **Dim 5** measures knowledge architecture: documentation structure, freshness mechanisms, machine-readable references, cache-friendly design. These are static information assets.

**Doc freshness (5.2)** belongs in Dim 5 because it is about knowledge management — keeping documentation current. It is not a runtime signal. If a CI check enforces doc freshness, the CI infrastructure contributes to Dim 2, but the freshness policy itself is Dim 5.

### Dim 2 (Mechanical Constraints) vs Dim 8 (Safety Rails)

**The question**: "Is this enforcing code quality (Dim 2) or limiting blast radius (Dim 8)?"

- **Dim 2** gates block non-conforming code from landing (linters, type checkers, tests).
- **Dim 8** gates prevent catastrophic actions (human confirmation for deploys, rollback capability, credential scoping).

If a CI check blocks a bad import, that is Dim 2. If a CI check requires manual approval before a database migration, that is Dim 8.

---

## Maturity Annotations (Optional)

The PASS/PARTIAL/FAIL scoring (1.0/0.5/0.0) captures whether a practice exists and functions. It deliberately does not capture sophistication level — a basic CI pipeline and a 12-job cross-platform CI pipeline both score PASS (1.0).

For reports where qualitative depth matters, annotate PASS items with a maturity level:

| Annotation | Meaning | Example (item 2.1 CI Pipeline) |
|------------|---------|-------------------------------|
| **[basic]** | Meets minimum PASS criteria | CI runs lint + test on PRs, blocks on failure |
| **[advanced]** | Exceeds basic requirements with meaningful additions | CI has 5+ jobs, caching, parallel execution, coverage enforcement |
| **[exemplary]** | Industry-leading implementation | CI has cross-platform matrix, change detection, sharding, <5 min total, security scanning |

### Rules

- Annotations are **optional** — omit them for straightforward audits
- Annotations do **not** change the numeric score (PASS is always 1.0)
- Annotations appear in the "Evidence" column of the detailed findings table
- Use annotations primarily on Dim 2 and Dim 4 items where sophistication varies most
- Do not annotate PARTIAL or FAIL items — they already communicate "needs improvement"

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
| 4 | Testing & Verification | 7 | 4.5/7 | 64% | 9.6 | Sensor + Actuator |
| 5 | Context Engineering | 5 | 2/5 | 40% | 4.0 | Goal State |
| 6 | Entropy Management | 4 | 1/4 | 25% | 2.5 | Feedback Loop |
| 7 | Long-Running Tasks | 6 | 2/6 | 33% | 3.3 | Feedback Loop |
| 8 | Safety Rails | 6 | 3/6 | 50% | 2.5 | Actuator (protective) |
| **Total** | | **45** | **22.5/45** | | **51.2** |

**Grade: D (51.2/100)**
```

Use PARTIAL scores where applicable — count as 0.5 in the "Passed" column.

---

## Profile-Based Weight Adjustments

When a project type profile is selected (from `data/profiles.json`), dimension weights are adjusted to reflect what matters most for that type. The `weight_overrides` field in the profile replaces the default weights for specified dimensions. Weights must still sum to 1.0.

For example, the `library` profile shifts weight from Dim 3 (Observability, reduced to 5%) to Dim 2 (Mechanical, increased to 25%) and Dim 4 (Testing, increased to 25%), because libraries need strong testing and type safety but don't need service-level observability.

Profiles may also specify:
- **`skip_items`**: Items that don't apply (e.g., 3.4 UI Visibility for CLI tools). Skipped items are excluded from the dimension item count.
- **`substitute_items`**: Alternative criteria when the standard item doesn't fit (e.g., "Can the agent see CLI output?" instead of "Browser automation configured").
- **`critical_items`**: Items that receive extra emphasis in the report even if the dimension weight is standard.

All profile `weights` are explicit (all 8 dimensions specified, summing to 1.0). No normalization is needed.

---

## Lifecycle Stage Adjustments

When a lifecycle stage is selected (from `data/stages.json`), only the active items for that stage are scored:

| Stage | Active Items | Focus |
|-------|-------------|-------|
| **Bootstrap** (<2k LOC) | 9 items | Foundations: agent file, CI, lint, types, tests, env recovery, security baseline |
| **Growth** (2k-50k LOC) | 29 items | All foundations + architecture, testing depth, early feedback loops |
| **Mature** (50k+ LOC) | 45 items | Full audit with all dimensions |

Inactive items are excluded from the dimension score calculation. Only active items contribute to the score:

```
dimension_score = (sum of active item points / number of active items in dimension) * 100
```

If a dimension has zero active items for the selected stage (e.g., Dim 3 in Bootstrap), it receives a score of N/A and its weight is redistributed proportionally among active dimensions.

---

## Combining Profile and Stage

When both a project type profile and a lifecycle stage are selected:

1. **Start with the profile's `weights`** — these are the base dimension weights (all 8 explicit, sum = 1.0).
2. **Apply the stage's active item filter** — only items in the stage's `active_items` array are scored. If a dimension has zero active items, its weight becomes 0.
3. **Redistribute zeroed weights** — any weight freed by zeroed dimensions is distributed proportionally among the remaining active dimensions so the total stays at 1.0.
4. **If the stage also defines `weight_overrides`** — stage weight overrides take precedence over the profile weights for the specified dimensions. After applying, normalize the result back to 1.0.

In short: **Profile sets the base weights. Stage filters the scope and may override specific weights. Final weights are always normalized to 1.0.**

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
