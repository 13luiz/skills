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
- AGENTS.md exists but exceeds 2× the dynamic PASS threshold (e.g. >300 for default, >500+ for large monorepo) -> PARTIAL (violates progressive disclosure)

---

## Dimension Boundary Disambiguation

When scoring, agents may encounter items that seem to overlap between dimensions. Use these guidelines to assign items to the correct dimension.

### Dim 2 (Mechanical Constraints) vs Dim 6 (Entropy Management)

**The question**: "Is this preventing a specific violation (Dim 2) or cleaning up accumulated drift (Dim 6)?"

- **2.2 Linter Enforcement** asks: does a linter exist and block in CI? This is infrastructure.
- **6.4 AI Slop Detection** asks: are there rules specifically targeting AI-generated patterns (duplicate utilities, dead code, over-abstraction)? This is AI-aware cleanup.

A project can PASS 2.2 (linter exists and blocks) but FAIL 6.4 (no AI-specific rules within the linter). The linter is the tool (Dim 2); the AI-specific rules are the policy (Dim 6).

### 2.2 Linter Enforcement: scope must cover core code

**The question**: "Does the linter cover the code an agent would actually modify?"

- **PASS**: Linter configured for the project's core source code and enforced in CI.
- **PARTIAL**: Linter configured for core code but not enforced in CI (runs locally only).
- **FAIL**: Linter not configured for core code. A linter that only covers a non-core sub-project (e.g., a VS Code extension SDK in a separate directory with its own lockfile) does not count — agents working on the main codebase receive no linting feedback.

In monorepos, evaluate whether the linter covers the workspace packages that constitute the primary product. A linter in `sdks/vscode/` that does not apply to `packages/*` is equivalent to no linter for scoring purposes.

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

### 8.3 Rollback Capability: "ad-hoc" vs "no strategy"

**The question**: "Can agent-made changes be reversed, and how?"

- **PASS**: Documented rollback playbook or automated rollback scripts exist. Operators know what to run.
- **PARTIAL**: Rollback is technically possible through ad-hoc means (e.g., git revert, re-deploying a previous release tag, reverting a database migration) but there is no documented procedure. The capability exists implicitly.
- **FAIL**: No rollback mechanism — neither documented nor implied. A bad change requires manual forensics to undo.

Git tag-based releases where a previous tag can be re-deployed count as ad-hoc rollback (PARTIAL). The distinction is between "we could figure it out" (PARTIAL) and "we have no path back" (FAIL).

### 1.2 Structured Knowledge Base: documentation location matters

**The question**: "Can an agent discover the project's documentation from the repository root?"

- **PASS**: A root-level `docs/` directory (or equivalent like `doc/`) exists with subdirectories and an index. Alternatively, the root README directly links to documentation entry points with clear navigation.
- **PARTIAL**: Documentation exists but at non-standard paths (e.g., `packages/docs/`, `packages/web/src/content/docs/`). An agent browsing the repo root would not discover it without prior knowledge. Also applies when docs exist at root but lack an index or meaningful structure.
- **FAIL**: No documentation directory or files beyond README.

For monorepos with documentation packages (e.g., Mintlify, Docusaurus, Starlight sites), the documentation site content is user-facing — not the same as a developer knowledge base. Score based on whether an agent can find development documentation from the root, not whether user docs exist somewhere in the tree.

### 1.4 Progressive Disclosure: navigation chain must be explicit

**The question**: "Can an agent follow a clear path from the entry file to domain-specific guidance?"

- **PASS**: The root agent instruction file (AGENTS.md / CLAUDE.md / CODEX.md) contains an explicit TOC or link list where each pointer resolves to an existing file. In monorepos, this means the root file references each sub-package agent file by path.
- **PARTIAL**: Sub-package agent files exist and provide domain layering, but the root file does not link to them — an agent must independently discover them via directory traversal.
- **FAIL**: No layering exists; all guidance is in a single file or no agent files exist.

The key test: if an agent reads only the root agent file, can it find all relevant sub-files without guessing? If not, score PARTIAL even when the sub-files are individually well-written.

### 2.1/4.2 CI Pipeline Blocks / Tests Block: verifying merge-blocking behavior

**The question**: "Does CI effectively gate merges, even when branch protection cannot be verified from within the repository?"

- **PASS**: CI workflow runs on PRs (`on: pull_request`) and its job names or workflow structure clearly indicate gate-keeping intent (e.g., `ci.yml`, `test.yml` with required status pattern). The inability to verify branch protection settings from within the repo does NOT downgrade the score.
- **PARTIAL**: CI exists but explicitly does not block (`continue-on-error: true`), only runs on push to main, or is an optional/informational check.
- **FAIL**: No CI pipeline or no test execution in CI.

Branch protection is a platform setting external to the repository. When CI workflows are designed as PR gates, score PASS unless there is positive evidence that they do not block merges.

### 2.7 Structural Conventions: "documented" vs "enforced"

**The question**: "Are naming, file structure, and workflow conventions mechanically enforced, not just written down?"

- **PASS**: At least 2 mechanical enforcement mechanisms exist. Examples: CI checks for conventional commits (`pr-standards.yml`), config-level guards (`bunfig.toml` test root restriction), pre-commit hooks (Husky/lefthook), automated compliance workflows (`compliance-close.yml`).
- **PARTIAL**: Conventions are documented in AGENTS.md or CONTRIBUTING.md but rely on human/agent compliance. Fewer than 2 mechanical enforcement mechanisms.
- **FAIL**: No documented conventions or enforcement.

The distinction is between "we told agents the rules" (PARTIAL) and "we made the rules impossible to break" (PASS). PR template requirements enforced by CI count as mechanical.

**Examples of structural conventions vs generic tooling**:

| Counts as structural convention | Does NOT count |
|--------------------------------|----------------|
| File naming rules (eslint-plugin-filenames) | Generic code style (prettier) |
| Import restrictions (no-restricted-imports) | Generic lint defaults (clippy defaults) |
| PR title format (conventional-commits CI) | Basic formatting (rustfmt) |
| Test path restriction (bunfig.toml test root) | Type checking (tsc strict) |
| Auto-compliance workflows (close non-conforming PRs) | Standard compiler warnings |

### 3.1 Structured Logging: framework capability vs output format

**The question**: "Does the application use a structured logging approach, regardless of output format?"

- **PASS**: Uses a structured logging framework (tracing, log4j, winston, slog, zerolog, etc.) with at least 2 of: log levels, context fields/spans, correlation IDs. JSON output format is NOT required — the framework itself provides structured data that can be queried and analyzed.
- **PARTIAL**: Mixed structured and unstructured logging, or framework present but used inconsistently (most logs are bare strings).
- **FAIL**: Only ad-hoc print statements with no logging framework.

### 6.4 AI Slop Detection: manual commands vs automated rules

**The question**: "Does the project automatically detect AI-generated code patterns?"

- **PASS**: Automated rules in the linter or CI that target AI-specific patterns: dead code detection, duplicate utility flagging, over-abstraction warnings. These run without human intervention on every PR.
- **PARTIAL**: AI slop awareness exists — dedicated commands (e.g., `rmslop`), PR template warnings against AI-generated text, or documented conventions. These require manual invocation or human vigilance.
- **FAIL**: No AI-specific detection — neither automated nor manual.

A dedicated slop-removal command that must be manually invoked is PARTIAL, not PASS. The item asks about detection automation, not awareness.

### 8.2 Audit Logging: platform-native vs dedicated

**The question**: "Can agent actions be traced and queried after the fact?"

- **PASS**: Dedicated audit logging beyond platform defaults — structured audit log files, queryable action history, or explicit workflow audit trails with timestamps and actor attribution.
- **PARTIAL**: Platform-native audit trails only (GitHub PR history, Actions run logs, git history). These provide implicit traceability but are not designed for systematic querying or compliance review.
- **FAIL**: No audit trail — actions are not recorded or traceable.

GitHub's built-in PR and Actions history counts as PARTIAL because it provides traceability but not a purpose-built audit system. The distinction matters for compliance-sensitive projects.

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

## Quick Mode Scoring

Quick Audit uses 15 vital-sign items (marked `quick_mode: true` in `data/checklist-items.json`) across all 8 dimensions.

### Item Selection

| Dim | Items | Rationale |
|-----|-------|-----------|
| 1 | 1.1, 1.3 | Agent entry point + architecture boundary awareness |
| 2 | 2.1, 2.2, 2.4 | The three highest-ROI mechanical constraints |
| 3 | 3.1, 3.5 | Runtime signal quality (logging + error diagnostics) |
| 4 | 4.1, 4.2, 4.5 | Test existence + CI enforcement + E2E coverage |
| 5 | 5.1 | Knowledge externalization baseline |
| 6 | 6.1 | Principle documentation (entropy anchor) |
| 7 | 7.4 | Environment recovery (session bootstrap) |
| 8 | 8.1, 8.3 | Credential scoping + rollback capability |

### Scoring Rules

- Use the same per-item PASS (1.0) / PARTIAL (0.5) / FAIL (0.0) scale.
- Dimension scores are calculated the same way: `(sum of quick item points / number of quick items in dimension) * 100`.
- Dimension weights use default weights (or profile weights if a profile is selected). Dimensions with 1 item get their full default weight. Normalize so weights sum to 1.0.
- Final score and grade thresholds are identical to Full Audit.

### Escalation Rule

If **any dimension scores below 50%**, the Quick Report must include an upgrade recommendation:

> *"Dimension [N] scored below 50%. A Full Audit is recommended to identify specific gaps and generate a detailed improvement roadmap."*

### Limitations

Quick Audit provides a directional health check, not a comprehensive assessment. It intentionally omits:
- Advanced practices (adversarial verification, durable execution, flake management)
- Depth checks (coverage thresholds, formatter enforcement, dependency direction)
- Organizational maturity indicators (audit logging, security path marking, protocol trust)

When in doubt, upgrade to Full Audit.

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

---

## Reproducibility & Item Classification

Not all checklist items are equally objective. Items are classified as **mechanical** (deterministic, automatable) or **judgment** (requires qualitative assessment). This classification sets expectations for inter-auditor consistency.

### Classification Table

| Type | Items | Expected Variance | Description |
|------|-------|-------------------|-------------|
| **Mechanical** | 1.1, 2.1, 2.2, 2.3, 2.4, 2.5, 2.7, 3.2, 4.1, 4.2, 4.3, 4.5, 5.2, 5.5, 6.3, 7.2, 7.4, 7.6, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6 | Low (< 0.5 point) | Verifiable by file existence, line count, config presence, or command output. Two auditors should reach the same score. |
| **Judgment** | 1.2, 1.3, 1.4, 1.5, 2.6, 3.1, 3.3, 3.4, 3.5, 4.4, 4.6, 4.7, 5.1, 5.3, 5.4, 6.1, 6.2, 6.4, 7.1, 7.3, 7.5 | Moderate (up to 1.0 point) | Requires qualitative assessment of content quality, effectiveness, or completeness. |

### Minimum Evidence Rules for Judgment Items

To reduce scoring variance on judgment items, apply these anchoring rules:

| Item | Judgment Question | Minimum Evidence for PASS |
|------|------------------|--------------------------|
| 1.2 | "Is docs/ well-organized?" | Has subdirectories + an index file linking to contents |
| 1.3 | "Is architecture doc useful?" | Names at least 3 modules/domains with explicit dependency direction |
| 1.4 | "Is navigation clear?" | Entry file has TOC where each pointer resolves to an existing file |
| 2.6 | "Are error messages helpful?" | At least 2 custom lint rules include a "Fix:" or "Instead, use:" message |
| 3.5 | "Is error context sufficient?" | Errors include at least 2 of: stack trace, relevant state, suggested fix |
| 4.7 | "Is adversarial verification present?" | Verifier is permission-isolated + report has command-run blocks |
| 5.1 | "Is knowledge externalized?" | No critical decisions found only in external channels during audit |
| 5.4 | "Is the stack agent-friendly?" | No dependencies lacking public documentation or type definitions |
| 6.1 | "Are principles effective?" | Principles referenced from agent instruction file (linked, not duplicated) |

When a judgment item meets the minimum evidence threshold, score PASS. When evidence is absent, score FAIL. Score PARTIAL only when evidence partially meets the threshold. This reduces the gray area where auditor subjectivity dominates.

---

## Conservatism Calibration

When scoring mechanical items (classified in the Classification Table above), apply these calibration rules to prevent over-conservative scoring:

1. **File evidence is authoritative**: If a config file, workflow file, or script exists in the repository and its content matches the PASS criteria, score PASS. Do not downgrade because an external platform setting (e.g., GitHub branch protection, registry permissions) cannot be verified from within the repository.

2. **Designed-as-gate counts**: CI workflows triggered by `pull_request` events with names implying gate behavior (e.g., `ci`, `test`, `check`, `lint`) should be scored as blocking unless positive counter-evidence exists (e.g., `continue-on-error: true`).

3. **Cron automation counts**: Scheduled workflows (`schedule` / cron triggers) that perform cleanup operations (closing stale PRs/issues, compliance enforcement) satisfy recurring automation criteria. Manual discovery of these workflows is expected during the scan phase.

4. **Partial evidence is not absence**: When a checklist item's description includes an intermediate state (PARTIAL criteria), do not score FAIL simply because the evidence is imperfect. Score FAIL only when the practice is genuinely absent or non-functional.
