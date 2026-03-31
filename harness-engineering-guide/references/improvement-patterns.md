# Improvement Patterns

Proven patterns for fixing common harness engineering gaps. Organized by effort level, with each pattern showing the problem, solution, effort, and impact.

---

## Quick Wins (1 day or less)

*Stage annotations: [B]=Bootstrap, [G]=Growth, [M]=Mature. Items marked [B] should be prioritized first for early-stage projects.*

### QW-1: Create a Minimal AGENTS.md
**Fixes**: 1.1, 1.4 | **Effort**: 30 minutes | **Impact**: High | **Stage**: [B][G][M]

Write a 50-100 line AGENTS.md as table of contents:
- Project description (2-3 sentences)
- Tech stack summary
- Key directory layout
- Pointers to deeper docs
- Critical constraints
- How to run tests, lint, and build

Do not dump everything into this file. See `agents-md-guide.md` for detailed guidance.

### QW-2: Enable Strict Linting in CI
**Fixes**: 2.2, 2.3 | **Effort**: 1-2 hours | **Impact**: High | **Stage**: [B][G][M]

Add linter to CI as blocking check:
- JavaScript/TypeScript: ESLint + Prettier
- Python: ruff (combines linting and formatting)
- Go: golangci-lint
- Rust: clippy in CI

Making lint a required status check for merges is the single most impactful change.

### QW-3: Add Coverage Measurement
**Fixes**: 4.3 | **Effort**: 1-2 hours | **Impact**: Medium | **Stage**: [G][M]

Add coverage reporting to CI. Don't enforce a threshold yet — just make it visible. After one week, set a threshold slightly below the average.

### QW-4: Enable Strict Type Checking
**Fixes**: 2.4 | **Effort**: 1 hour to 1 day | **Impact**: High | **Stage**: [B][G][M]

TypeScript: `"strict": true`. Python: `mypy --strict`. Fix resulting errors. Agents benefit enormously from type checking because it catches structural mistakes instantly.

### QW-5: Document Architecture Boundaries
**Fixes**: 1.3, 2.5 | **Effort**: 2-4 hours | **Impact**: High | **Stage**: [G][M]

Write ARCHITECTURE.md with:
- Module/domain boundaries
- Dependency direction rules
- Key abstractions
- Major directory contents

Even without mechanical enforcement, documented boundaries give agents a reference.

---

## Strategic Investments (1-4 weeks)

### SI-1: Build a Structured Documentation System
**Fixes**: 1.2, 1.4, 1.5, 5.1 | **Effort**: 1-2 weeks | **Impact**: Transformative | **Stage**: [G][M]

Create `docs/` following OpenAI's structure:
```
docs/
├── design-docs/
│   ├── index.md
│   └── [feature].md
├── product-specs/
├── references/
│   └── [library]-llms.txt
├── exec-plans/
│   ├── active/
│   └── completed/
├── ARCHITECTURE.md
├── QUALITY_SCORE.md
└── SECURITY.md
```

Externalize knowledge from Slack, Notion, Google Docs. Add an index at each level.

### SI-2: Implement Custom Architectural Linters
**Fixes**: 2.5, 2.6, 2.7 | **Effort**: 1-2 weeks | **Impact**: High | **Stage**: [G][M]

Write custom rules enforcing dependency direction. Error messages should teach: "You imported UserService from UI. Use UserProvider from providers/ instead."

Tools: ESLint custom rules, `dependency-cruiser` (JS/TS), `import-linter` (Python), `depguard` (Go).

### SI-3: Add E2E Testing with Browser Automation
**Fixes**: 3.4, 4.5 | **Effort**: 1-2 weeks | **Impact**: High | **Stage**: [G][M]

Set up Playwright or Cypress for critical user journeys. Configure so agents can use browser automation during development (screenshots, DOM inspection). This is the "hardest sensor" — verifies real user experience.

### SI-4: Implement Doc-Gardening Automation
**Fixes**: 5.2, 6.2 | **Effort**: 3-5 days | **Impact**: Medium-high | **Stage**: [G][M]

Two approaches:
1. **CI freshness check**: Scan docs for metadata, flag stale content
2. **Doc-gardening agent**: Scheduled task scanning docs vs codebase, opening fix PRs

### SI-5: Build Tech Debt Tracking
**Fixes**: 6.1-6.4 | **Effort**: 1 week | **Impact**: Medium | **Stage**: [M]

Create a quality scoring system per module:
- Test coverage, doc freshness, lint violations, dependency violations
- Track over time in `QUALITY_SCORE.md` or `tech-debt-tracker.json`
- Add AI slop detection rules (duplicated utilities, dead code, over-abstraction)

### SI-6: Implement Long-Running Task Infrastructure
**Fixes**: 7.1-7.5 | **Effort**: 1-2 weeks | **Impact**: High | **Stage**: [G][M]

Build multi-session scaffolding:
1. Execution plan templates
2. `progress.txt` convention
3. `init.sh` for environment boot + health checks
4. "Clean state" expectation in AGENTS.md
5. Feature list template with machine-readable status

### SI-7: Implement Agent-Queryable Observability
**Fixes**: 3.1-3.3 | **Effort**: 1-2 weeks | **Impact**: High | **Stage**: [M]

Set up:
- Structured JSON logging with correlation IDs
- OpenTelemetry tracing
- Per-worktree ephemeral stacks
- CLI tools for agents to query logs and metrics

Agents that can see their own logs diagnose their own problems.

### SI-8: Implement Cache-Friendly Repository Design
**Fixes**: 5.5 | **Effort**: 1-2 days | **Impact**: Medium-high | **Stage**: [G][M]

Restructure for cache stability:
- Trim AGENTS.md to <150 lines (move verbose content to docs/)
- Create artifact directories (`reports/`, `artifacts/`) for large agent outputs
- Convert prose progress tracking to structured JSON files
- Audit MCP server count; remove rarely-used always-loaded servers
- Organize docs for search/read access rather than bulk loading

### SI-9: Implement Durable Execution Infrastructure
**Fixes**: 7.6 | **Effort**: 1 week | **Impact**: High | **Stage**: [M]

Build multi-session resilience:
1. Define `progress.json` schema and convention in AGENTS.md
2. Create `exec-plans/` directory with execution plan template
3. Add `init.sh` that reads progress state before starting new work
4. Document "safe stopping points" and session-end cleanup expectations
5. Add rollback procedures for partially-completed multi-step changes

### SI-10: Implement Tool Protocol Hygiene
**Fixes**: 8.6 | **Effort**: 1-3 days | **Impact**: Medium | **Stage**: [M]

Harden tool access:
- Audit all MCP server configurations for permission scope
- Remove or defer-load rarely-used MCP servers
- Add approval gates for destructive tool operations (delete, deploy, migrate)
- Treat MCP tool output as untrusted — validate before acting on results
- Establish tool invocation audit trail (log tool name, args, timestamps)

### SI-11: Implement Adversarial Verification
**Fixes**: 4.7 | **Effort**: 1-2 weeks | **Impact**: High | **Stage**: [G][M]

Build a three-party verification chain (implementer → verifier → auditor):

1. **Verifier agent definition**: read-only permissions (block file-write/edit tools programmatically), temp-dir exception for test scripts, structured output format (Command run → Output observed → Result)
2. **Anti-rationalization prompts**: embed the six common verification-skipping excuses in the verifier's system prompt so it recognizes its own failure modes
3. **Structural nudges**: inject verification reminders into task-tracking tool returns when all tasks close without a verification step
4. **Spot-check protocol**: auditor re-runs 2-3 commands from verifier's report to validate consistency
5. **Type-specialized strategies**: configure verification probes per change type (frontend → browser automation, API → curl + edge cases, CLI → boundary inputs)

Read `references/adversarial-verification.md` for the full pattern catalog.

### SI-12: Progressive Harness Component Rollout
**Fixes**: N/A (meta-pattern) | **Effort**: 1-3 days per component | **Impact**: Medium | **Stage**: [G][M]

Deploy new harness components (verification agents, custom lint rules, new CI gates) incrementally rather than all-at-once:

1. **Feature flag gating**: wrap the component behind a build-time or runtime flag so it can be disabled without code changes
2. **Internal dogfooding**: enable for the team that built it first
3. **Percentage rollout**: use remote config (LaunchDarkly, GrowthBook, environment variables) to gradually increase activation from 5% → 25% → 100%
4. **Monitoring**: track trigger rate, false positive rate, time cost, and user satisfaction delta between enabled and disabled groups
5. **Default-on**: remove gates once the component is stable

This pattern is especially important for adversarial verification systems, where a high false-positive rate during early rollout can erode developer trust.

---

## Anti-Patterns to Avoid

### AP-1: The Giant AGENTS.md
2000-line instruction manual. Crowds out task context, causes local pattern-matching, rots instantly.
**Instead**: Under 150 lines. Use as TOC pointing to deeper docs.

### AP-2: Documentation Without Enforcement
Beautiful architecture docs nobody follows because no mechanical check.
**Instead**: For every rule, ask "can I lint this?" If yes, write the rule.

### AP-3: Optimizing Prompts Instead of Harness
Days rewriting prompts when the environment is underspecified.
**Instead**: Ask "what capability is missing?" not "how do I phrase this better?"

### AP-4: Manual Garbage Collection
20% of engineering time manually cleaning AI slop every Friday.
**Instead**: Encode golden principles + automated cleanup agents.

### AP-5: Trusting Agent Self-Evaluation
Letting agents judge their own "done." They reliably rate themselves too highly.
**Instead**: External verification — separate evaluators, mechanical tests, browser-driven E2E.

### AP-6: Dynamic Tool Catalog Mid-Session
Adding or removing MCP tools during a session invalidates the prompt cache and wastes tokens.
**Instead**: Fix the tool catalog at session start. Use deferred loading for rarely-needed tools.

### AP-7: No Crash Recovery for Multi-Step Tasks
Agent crashes at step 15 of 20 and starts over from step 1.
**Instead**: Structured progress files after each meaningful step. `init.sh` reads state on restart.

### AP-8: Tool Output Trusted Blindly
MCP server returns crafted output that manipulates agent behavior.
**Instead**: Treat all tool output as untrusted. Validate results before taking action.
