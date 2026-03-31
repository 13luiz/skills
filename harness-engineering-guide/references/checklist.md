# Harness Engineering Audit Checklist

The primary scoring instrument. Go through each item, marking PASS / PARTIAL / FAIL with evidence.

**Scoring**: PASS = 1 point, PARTIAL = 0.5 points, FAIL = 0 points. The dimension score is (points earned / total possible points) * 100, then multiplied by the dimension weight for the final contribution.

---

## 1. Architecture Documentation & Knowledge Management (15%)
> **Control Loop Element: GOAL STATE** — Defines what "correct" looks like so the agent has a target to converge toward.

### 1.1 Agent Instruction File Exists
**What to check**: Does the repo have an AGENTS.md, CLAUDE.md, .cursorrules, .cursor/rules/, CODEX.md, or equivalent?

- PASS: File exists and acts as a concise map (under ~150 lines) pointing to deeper docs
- PARTIAL: File exists but is either a massive dump (>500 lines) or extremely minimal (<10 lines)
- FAIL: No agent instruction file

### 1.2 Structured Knowledge Base
**What to check**: Is there a `docs/` directory with organized subdirectories for design docs, product specs, architecture decisions, and references?

- PASS: Structured docs directory with clear organization and an index
- PARTIAL: Docs exist but are flat or have no index/table of contents
- FAIL: No documentation directory, or only a bare README.md

### 1.3 Architecture Documentation
**What to check**: Is there an ARCHITECTURE.md or equivalent describing the system's domains, package layering, dependency directions, and key abstractions?

- PASS: Clear architecture doc with domain boundaries, package layering, and dependency rules
- PARTIAL: Some architectural notes exist but are incomplete, scattered, or outdated
- FAIL: No architecture documentation

### 1.4 Progressive Disclosure
**What to check**: Is knowledge organized so an agent gets a short entry point first, then drills deeper on demand?

- PASS: Agent instruction file is a TOC with explicit pointers. Deeper docs organized by topic.
- PARTIAL: Some layering exists but navigation is unclear or entry point is too verbose
- FAIL: Monolithic instruction file or no structured navigation

### 1.5 Versioned Knowledge Artifacts
**What to check**: Are design decisions, plans, and ADRs tracked in version control (not Google Docs or Notion)?

- PASS: Design docs, ADRs, execution plans all live in the repo
- PARTIAL: Some docs in-repo but key decisions live outside
- FAIL: Most knowledge lives outside the repository

---

## 2. Mechanical Constraints (20%)
> **Control Loop Element: ACTUATOR** — Forces correction by blocking non-conforming changes before they land.

### 2.1 CI Pipeline Exists and Blocks
**What to check**: Is there a CI pipeline that runs on PRs and blocks merges on failure?

- PASS: CI runs on every PR, status checks required for merge
- PARTIAL: CI exists but doesn't block merges, or only runs on main
- FAIL: No CI pipeline

### 2.2 Linter Enforcement
**What to check**: Are linters configured and enforced in CI?

- PASS: Linter runs in CI and blocks on violations. Config committed to repo.
- PARTIAL: Linter configured but not enforced in CI
- FAIL: No linter configuration

### 2.3 Formatter Enforcement
**What to check**: Is code formatting enforced consistently?

- PASS: Formatter runs in CI and blocks on violations
- PARTIAL: Formatter configured but not enforced in CI
- FAIL: No formatter configuration

### 2.4 Type Safety
**What to check**: Is static type checking enabled and enforced?

- PASS: Type checker runs in CI and blocks (TypeScript strict, mypy strict, etc.)
- PARTIAL: Type checking exists but is permissive (any allowed freely, strict mode off)
- FAIL: No type checking

### 2.5 Dependency Direction Rules
**What to check**: Are module dependency rules mechanically enforced?

- PASS: Custom linters or structural tests enforce rules. Violations block CI.
- PARTIAL: Rules documented but not mechanically enforced
- FAIL: No dependency rules

### 2.6 Remediation-Aware Error Messages
**What to check**: Do custom lint/CI checks include fix instructions for agents?

- PASS: Errors include specific remediation steps ("You imported X from Y. Instead, use Z")
- PARTIAL: Some messages helpful but most are generic
- FAIL: Only cryptic default framework messages

### 2.7 Structural Conventions Enforced
**What to check**: Are naming conventions, file size limits, import restrictions mechanically checked?

- PASS: At least 2 conventions enforced via lint or CI
- PARTIAL: Conventions documented but not enforced
- FAIL: No structural conventions

---

## 3. Feedback Loops & Observability (15%)
> **Control Loop Element: SENSOR** — Detects deviation from the goal state through tests, logs, metrics, and visual inspection.

### 3.1 Structured Logging
**What to check**: Does the application use structured logging (JSON logs, levels, correlation IDs)?

- PASS: Structured logging framework with consistent patterns
- PARTIAL: Mixed structured and unstructured logging
- FAIL: Only ad-hoc print statements

### 3.2 Metrics and Tracing
**What to check**: Is there observability infrastructure for metrics and distributed tracing?

- PASS: Metrics and/or tracing configured (OpenTelemetry, Prometheus, etc.)
- PARTIAL: Basic metrics but tracing absent
- FAIL: No metrics or tracing

### 3.3 Agent-Queryable Observability
**What to check**: Can an agent query logs, metrics, or traces programmatically?

- PASS: Agents can access data via CLI tools, APIs, or local query interfaces
- PARTIAL: Data exists but requires manual dashboard access
- FAIL: No programmatic access

### 3.4 UI Visibility for Agents
**What to check**: Can agents see and interact with the application's UI?

- PASS: Browser automation configured (Playwright, CDP) and agents can screenshot/inspect DOM
- PARTIAL: Some UI testing exists but agents can't use it during sessions
- FAIL: No UI visibility tooling

### 3.5 Diagnostic Error Context
**What to check**: Do errors include enough context for agent diagnosis?

- PASS: Stack traces, relevant state, and suggested fixes included
- PARTIAL: Standard error handling but lacks diagnostic context
- FAIL: Errors swallowed or generic

---

## 4. Testing & Verification (15%)
> **Control Loop Element: SENSOR + ACTUATOR** — Tests detect deviation (sensor) and CI gates block bad changes (actuator).

### 4.1 Test Suite Exists
**What to check**: Does the project have a test suite with meaningful coverage?

- PASS: Tests across multiple layers (unit, integration, or e2e)
- PARTIAL: Some tests but very low coverage or single layer only
- FAIL: No test suite

### 4.2 Tests Run in CI and Block
**What to check**: Do tests run on PRs and block merges on failure?

- PASS: Tests are a required check; PRs cannot merge with failures
- PARTIAL: Tests run but don't block
- FAIL: Tests don't run in CI

### 4.3 Coverage Thresholds
**What to check**: Are coverage thresholds enforced?

- PASS: Thresholds configured and enforced in CI (e.g., minimum 70%)
- PARTIAL: Coverage measured but no thresholds
- FAIL: No coverage measurement

### 4.4 Formalized Done Criteria
**What to check**: Is "done" defined mechanically?

- PASS: Feature list in machine-readable format (JSON/YAML) with pass/fail status
- PARTIAL: Done criteria in human-readable form but not mechanically enforced
- FAIL: No formalized criteria; agents decide when done

### 4.5 End-to-End Verification
**What to check**: Are there E2E tests verifying real user experience?

- PASS: E2E suite exists (Playwright, Cypress) and runs in CI
- PARTIAL: Some E2E tests but not comprehensive or not in CI
- FAIL: No end-to-end tests

### 4.6 Test Flake Management
**What to check**: Is there a strategy for flaky tests?

- PASS: Flakes tracked, quarantined, or retried with monitoring
- PARTIAL: Some awareness but no systematic management
- FAIL: Flakes routinely block or are silently ignored

---

## 5. Context Engineering (10%)
> **Control Loop Element: GOAL STATE (communication)** — Ensures the agent sees the right information at the right time to make correct decisions.

### 5.1 Externalized Knowledge
**What to check**: Has important knowledge been moved from Slack/email/meetings into the repo?

- PASS: Key decisions and conventions documented in-repo. No critical knowledge only in chat.
- PARTIAL: Some externalized but significant gaps remain
- FAIL: Most knowledge only in external channels

### 5.2 Documentation Freshness Mechanism
**What to check**: Is there a process to prevent docs from going stale?

- PASS: Automated freshness checks (CI validation, doc-gardening agent, expiry dates)
- PARTIAL: Manual review exists but inconsistent
- FAIL: No freshness mechanism; docs are write-once

### 5.3 Machine-Readable References
**What to check**: Are external docs available in agent-friendly formats?

- PASS: llms.txt files, local reference docs, or curated snapshots for key dependencies
- PARTIAL: Some references but incomplete coverage
- FAIL: Agents must fetch external docs with no local guidance

### 5.4 Technology Composability
**What to check**: Does the stack favor well-documented, composable tools agents can reason about?

- PASS: Stable, widely-known technologies. Minimal custom abstractions. Agent can understand the full stack from repo alone.
- PARTIAL: Mostly standard but some opaque dependencies
- FAIL: Heavy reliance on obscure libraries or undocumented frameworks

### 5.5 Cache-Friendly Context Design
**What to check**: Is the repository structured to support agent cache stability and avoid context overflow?

- PASS: AGENTS.md under 150 lines with stable content; structured state files (JSON/YAML) for tracking; artifact directories for large outputs; documentation organized for search/read rather than bulk loading
- PARTIAL: Some externalization but AGENTS.md is bloated (>300 lines) or no artifact directories
- FAIL: Monolithic instruction files, no structured state, agents must carry all context in prompt

---

## 6. Entropy Management & Garbage Collection (10%)
> **Control Loop Element: FEEDBACK LOOP (continuous)** — Routes quality signals back into the system to prevent drift and decay over time.

### 6.1 Codified Golden Principles
**What to check**: Are core engineering principles written for agent reference?

- PASS: Principles documented and referenced from agent instructions
- PARTIAL: Some principles exist but not connected to agent workflows
- FAIL: No codified principles

### 6.2 Recurring Cleanup Process
**What to check**: Is there systematic cleanup for tech debt?

- PASS: Automated or scheduled cleanup (refactoring agent, quality-improvement PRs)
- PARTIAL: Ad-hoc cleanup happens but not systematic
- FAIL: No cleanup process

### 6.3 Tech Debt Tracking
**What to check**: Is tech debt tracked explicitly?

- PASS: Quality scores, tech-debt-tracker, or similar maintained artifact
- PARTIAL: Some tracking via TODO comments or issue labels
- FAIL: No tech debt tracking

### 6.4 AI Slop Detection
**What to check**: Are there mechanisms to detect AI-generated low-quality patterns?

- PASS: Lint rules or review patterns target common AI slop (duplicated utilities, dead code)
- PARTIAL: General review catches some but nothing AI-specific
- FAIL: No AI slop awareness

---

## 7. Long-Running Task Support (10%)
> **Control Loop Element: FEEDBACK LOOP (cross-session)** — Maintains control loop continuity across session boundaries, crashes, and handoffs.

### 7.1 Task Decomposition Strategy
**What to check**: Is there a documented approach for breaking complex tasks into agent-sized chunks?

- PASS: Documented strategy with templates (execution plans, sprint contracts)
- PARTIAL: Informal decomposition not documented
- FAIL: No decomposition; agents receive full-scope prompts

### 7.2 Progress Tracking Artifacts
**What to check**: Do agents leave structured progress notes?

- PASS: progress.txt, execution plan logs, or equivalent maintained across sessions
- PARTIAL: Git commit messages as only progress record
- FAIL: No progress tracking between sessions

### 7.3 Handoff Bridges
**What to check**: Can a new agent session quickly understand the previous one?

- PASS: Descriptive commits + progress logs + feature status = complete handoff
- PARTIAL: Some handoff info but new sessions need significant orientation
- FAIL: No structured handoff; new sessions start blind

### 7.4 Environment Recovery
**What to check**: Can the dev environment be restored automatically?

- PASS: init.sh / setup script boots environment. Health checks run before new work.
- PARTIAL: Setup instructions exist but require manual steps
- FAIL: No recovery mechanism

### 7.5 Clean State Discipline
**What to check**: Does each session leave the codebase mergeable?

- PASS: Documented expectation; each session commits clean, tested code
- PARTIAL: Implicitly expected but not enforced
- FAIL: Sessions routinely leave broken or half-done code

### 7.6 Durable Execution Support
**What to check**: Can agent tasks survive crashes, interruptions, and session boundaries?

- PASS: Structured checkpoint files (progress.json, execution plans) + recovery script (init.sh) + documented recovery protocol
- PARTIAL: Some progress tracking exists but no formal recovery mechanism
- FAIL: No progress persistence between sessions; interruptions mean starting over

---

## 8. Safety Rails (5%)
> **Control Loop Element: ACTUATOR (protective)** — Limits blast radius when the control loop fails by restricting destructive operations.

### 8.1 Least-Privilege Credentials
**What to check**: Do agent operations use scoped credentials?

- PASS: Tokens scoped to minimum required permissions
- PARTIAL: Some scoping but broader than needed
- FAIL: Full admin credentials or not addressed

### 8.2 Audit Logging
**What to check**: Are agent actions logged for accountability?

- PASS: PRs, deployments, config changes logged with timestamps and attribution
- PARTIAL: Some logging but incomplete
- FAIL: No audit trail

### 8.3 Rollback Capability
**What to check**: Can agent-made changes be quickly rolled back?

- PASS: Documented rollback playbook or automated scripts
- PARTIAL: Rollback possible but ad-hoc
- FAIL: No rollback strategy

### 8.4 Human Confirmation Gates
**What to check**: Are destructive operations gated behind human approval?

- PASS: DB migrations, production deploys, force pushes require confirmation
- PARTIAL: Some gates but incomplete
- FAIL: Agents can perform destructive ops without approval

### 8.5 Security-Critical Path Marking
**What to check**: Are security-sensitive areas explicitly marked?

- PASS: Critical files marked (CODEOWNERS, comments) with stricter review
- PARTIAL: Some awareness but no explicit marking
- FAIL: No distinction between critical and regular code

### 8.6 Tool Protocol Trust Boundaries
**What to check**: Are MCP/tool configurations scoped to minimum privilege with output treated as untrusted?

- PASS: MCP servers scoped to minimum permissions, tool output treated as untrusted, audit trail for invocations
- PARTIAL: Some MCP configuration but broad permissions or no audit trail
- FAIL: No awareness of tool trust boundaries, or unrestricted tool access

---

## Quick Reference: All 43 Items

| # | Dimension | Item | Weight | Control Element |
|---|-----------|------|--------|----------------|
| 1.1 | Arch Docs | Agent instruction file | 15% | Goal State |
| 1.2 | Arch Docs | Structured knowledge base | 15% | Goal State |
| 1.3 | Arch Docs | Architecture documentation | 15% | Goal State |
| 1.4 | Arch Docs | Progressive disclosure | 15% | Goal State |
| 1.5 | Arch Docs | Versioned knowledge artifacts | 15% | Goal State |
| 2.1 | Mechanical | CI pipeline blocks | 20% | Actuator |
| 2.2 | Mechanical | Linter enforcement | 20% | Actuator |
| 2.3 | Mechanical | Formatter enforcement | 20% | Actuator |
| 2.4 | Mechanical | Type safety | 20% | Actuator |
| 2.5 | Mechanical | Dependency direction rules | 20% | Actuator |
| 2.6 | Mechanical | Remediation-aware errors | 20% | Actuator |
| 2.7 | Mechanical | Structural conventions | 20% | Actuator |
| 3.1 | Observability | Structured logging | 15% | Sensor |
| 3.2 | Observability | Metrics and tracing | 15% | Sensor |
| 3.3 | Observability | Agent-queryable observability | 15% | Sensor |
| 3.4 | Observability | UI visibility for agents | 15% | Sensor |
| 3.5 | Observability | Diagnostic error context | 15% | Sensor |
| 4.1 | Testing | Test suite exists | 15% | Sensor + Actuator |
| 4.2 | Testing | Tests in CI and blocking | 15% | Sensor + Actuator |
| 4.3 | Testing | Coverage thresholds | 15% | Sensor + Actuator |
| 4.4 | Testing | Formalized done criteria | 15% | Sensor + Actuator |
| 4.5 | Testing | End-to-end verification | 15% | Sensor + Actuator |
| 4.6 | Testing | Test flake management | 15% | Sensor + Actuator |
| 5.1 | Context | Externalized knowledge | 10% | Goal State |
| 5.2 | Context | Documentation freshness | 10% | Goal State |
| 5.3 | Context | Machine-readable references | 10% | Goal State |
| 5.4 | Context | Technology composability | 10% | Goal State |
| 5.5 | Context | Cache-friendly context design | 10% | Goal State |
| 6.1 | Entropy | Codified golden principles | 10% | Feedback Loop |
| 6.2 | Entropy | Recurring cleanup process | 10% | Feedback Loop |
| 6.3 | Entropy | Tech debt tracking | 10% | Feedback Loop |
| 6.4 | Entropy | AI slop detection | 10% | Feedback Loop |
| 7.1 | Long Tasks | Task decomposition strategy | 10% | Feedback Loop |
| 7.2 | Long Tasks | Progress tracking artifacts | 10% | Feedback Loop |
| 7.3 | Long Tasks | Handoff bridges | 10% | Feedback Loop |
| 7.4 | Long Tasks | Environment recovery | 10% | Feedback Loop |
| 7.5 | Long Tasks | Clean state discipline | 10% | Feedback Loop |
| 7.6 | Long Tasks | Durable execution support | 10% | Feedback Loop |
| 8.1 | Safety | Least-privilege credentials | 5% | Actuator (protective) |
| 8.2 | Safety | Audit logging | 5% | Actuator (protective) |
| 8.3 | Safety | Rollback capability | 5% | Actuator (protective) |
| 8.4 | Safety | Human confirmation gates | 5% | Actuator (protective) |
| 8.5 | Safety | Security-critical path marking | 5% | Actuator (protective) |
| 8.6 | Safety | Tool protocol trust boundaries | 5% | Actuator (protective) |
