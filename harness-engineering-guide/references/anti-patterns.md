# Anti-Patterns to Flag

Common anti-patterns found in harness engineering. Flag these during audit (Mode 1) and actively prevent them during implementation (Mode 2) or design (Mode 3).

---

## Harness Controllability Classification

Anti-patterns are classified by whether the harness can **eliminate** or only **reduce** the problem:

- **Preventable** — The harness can eliminate the root cause or its symptoms through mechanical constraints: CI gates, lint rules, permission scoping, structural enforcement. Applies to items #1–6, #8–13, #15, #17–22, #25.
- **Mitigable** — The problem originates from inherent LLM limitations or human/organizational behavior that the harness can detect and reduce but cannot fully eliminate. The harness lowers frequency and blast radius through defense-in-depth (circuit breakers, structured checkpoints, documentation gates, awareness policies), but residual risk remains. Applies to items #7, #14, #16, #23, #24.

| # | Anti-Pattern | Classification | Rationale |
|---|---|---|---|
| #7 | LLM-generated agent config | Mitigable | No mechanical way to distinguish human-written vs LLM-generated content; review policies reduce but cannot eliminate |
| #14 | Knowledge lives in Slack | Mitigable | Harness can require docs to exist (gate), but cannot prevent humans from keeping knowledge in external channels |
| #16 | Optimizing prompts instead of harness | Mitigable | Process/mindset issue; harness guidelines can redirect focus but cannot mechanically prevent prompt-first thinking |
| #23 | Infinite tool call loops | Mitigable | Inherent LLM limitation; circuit breakers reduce but cannot eliminate |
| #24 | Context overflow hallucinations | Mitigable | Inherent LLM limitation; session management reduces but cannot eliminate |

For mitigable anti-patterns, communicate residual risk honestly — do not promise elimination.

---

## Verification Anti-Patterns

1. **AI tests verifying AI code** — Circular verification. Tests should independently verify logic, not mirror the implementation they claim to check.
2. **Agent self-evaluation** — Agents rate themselves too highly. Use external verification with an independent verifier agent.
3. **Verification without execution** — Verifier reads code and writes "PASS" without running commands. A check without a command-run block is a skip, not a pass.
4. **Happy-path-only verification** — Verifier confirms the feature works with normal input but never tries to break it. At minimum, one adversarial probe (boundary value, concurrent request, missing resource) is required.
5. **Test results are evidence** — LLM-written tests may use circular assertions or excessive mocking. Passing tests confirm the happy path; independent adversarial verification confirms correctness.

## Documentation Anti-Patterns

6. **Encyclopedia AGENTS.md** — Files exceeding the dynamic threshold (default 150 lines; monorepo: up to 300). Should be a concise TOC with pointers to deeper docs.
7. **[Mitigable] LLM-generated agent config** — Human-crafted instruction files outperform AI-generated ones because they encode domain-specific constraints. No mechanical detection exists; mitigate with PR review policies requiring human authorship for agent instruction files.
8. **Full test suite in agent context** — Floods context with passing output. Configure CI to surface errors only (succeed silently, fail verbosely).

## Tool & Context Anti-Patterns

9. **Tool hoarding** — Dozens of MCP servers bloat context and break cache stability. Target <10 always-loaded servers.
10. **Dynamic tool catalog mid-session** — Invalidates prompt cache. Fix the tool catalog at session start.
11. **Trusting tool output blindly** — MCP server output is untrusted input. Validate before acting on results.
23. **[Mitigable] Infinite tool call loops** — Agent calls a tool whose output triggers the agent to call the same tool again, creating an unbounded cycle (distinct from retry loops in harness components). Common patterns: search→read→search→read on the same file, or agent-spawn chains where child agents spawn more children. Add explicit loop detection (call count limits per tool per session) and circuit breakers that escalate to human after N repeated calls.

## Constraint Anti-Patterns

12. **Lint but don't block** — CI runs the linter and reports violations but doesn't fail the build. Agents see green checks and assume compliance. A gate that doesn't block is advisory noise, not a constraint.
13. **Coverage theater** — High coverage numbers (80%+) achieved via trivial assertions (`expect(true).toBe(true)`) or excessive mocking that tests the mock, not the code. Coverage without meaningful assertions is a vanity metric.

## Context & Knowledge Anti-Patterns

14. **[Mitigable] Knowledge lives in Slack** — Critical decisions, conventions, and context exist only in chat threads, Notion pages, or email. Agents cannot access external channels. Harness can require in-repo docs to exist (documentation gates), but cannot prevent humans from keeping discussions in external channels. Externalize to in-repo docs or ADRs; use doc freshness checks to detect gaps.
15. **TODO-driven debt management** — Using `TODO` / `FIXME` / `HACK` comments as the sole mechanism for tracking tech debt. Comments are invisible to planning and trend analysis. Use a maintained tracker artifact.
24. **[Mitigable] Context overflow hallucinations** — Agent's context window fills up, causing it to lose sight of earlier files, instructions, or constraints. The agent then "hallucinates" about code it can no longer see — referencing functions that don't exist, misremembering file structures, or silently dropping requirements. Mitigate with streaming audit batches (see SKILL.md § Streaming Audit Protocol), structured checkpoint files, and proactive session restarts at ~80% context capacity rather than pushing to the limit.

## Process Anti-Patterns

16. **[Mitigable] Optimizing prompts instead of harness** — Improve the environment (constraints, feedback, verification), not the phrasing. Ask "what capability is missing?" not "how do I word this better?" This is a process/mindset anti-pattern; harness guidelines can redirect focus but cannot mechanically prevent prompt-first thinking.
17. **Manual garbage collection** — Automate cleanup with scheduled agents or CI jobs. "Friday cleanup sprints" don't scale.
18. **No crash recovery** — Multi-step tasks need structured checkpoint files (`progress.json`) and documented recovery protocols.
19. **No environment health check** — Agents building on broken environments compound errors. Use `init.sh` with health checks.
20. **Stateless multi-session** — Each agent session starts from scratch with no awareness of previous progress. Without structured handoff artifacts (progress logs, execution plans, feature status), agents repeat work or contradict earlier decisions.
25. **Parallel agent file conflicts** — Multiple agents (or subagents) write to the same file concurrently without coordination, causing silent data loss, merge conflicts, or corrupted state. Common in fan-out topologies and parallel subagent workflows (e.g., Cursor Task tool). Mitigate with directory isolation (each agent writes to its own workspace), file-level locking, or sequential merge points. See `references/agent-team-patterns.md` § Fan-out / Fan-in for the full pattern.

## Safety Anti-Patterns

21. **Convenience admin token** — Using a single broad-permission token for all agent operations because scoping is "too much work." A compromised or misbehaving agent with admin access has unlimited blast radius. Scope tokens to the minimum required permissions per operation.
22. **Agent self-modifying harness config** — Agent edits AGENTS.md, .cursorrules, CLAUDE.md, or CI configuration during a task. This lets the agent weaken its own guardrails (removing boundary rules, relaxing lint configs, disabling CI checks). Agent instruction files and CI configs should be read-only for agents; changes require human review via PR.

---

## Quick Diagnostic

When reviewing a codebase, check for these red flags:

| Red Flag | Anti-Pattern # | Quick Fix |
|----------|---------------|-----------|
| AGENTS.md exceeds threshold (>150 / >300 monorepo) | #6 | Trim to TOC, move content to `docs/` |
| No CI or CI doesn't block | Dim 2 gap | Add blocking CI pipeline (checklist 2.1) |
| CI runs linter but exits 0 on violations | #12 | Set linter to fail build on any violation |
| Tests written by same agent that wrote code | #1 | Independent verifier agent |
| High coverage but trivial assertions | #13 | Audit test quality, not just coverage numbers |
| Key decisions only in Slack/Notion | #14 [Mitigable] | Externalize to in-repo docs or ADRs; add doc freshness gates |
| Tech debt tracked only via TODO comments | #15 | Add `tech-debt-tracker.json` or issue labels |
| 15+ MCP servers loaded | #9 | Audit and remove rarely-used servers |
| No `progress.json` or checkpoint files | #18 | Add durable execution support |
| Each session starts without handoff context | #20 | Structured progress logs + feature status |
| Verifier report has no "Command run" blocks | #3 | Require executable evidence |
| Agent tokens have admin/write-all permissions | #21 | Scope to minimum required permissions |
| Agent edits AGENTS.md / .cursorrules / CI config | #22 | Mark harness config files read-only for agents |
| Same tool called 10+ times in a single turn | #23 | Add per-tool call count limits + circuit breaker |
| Agent references code/files it hasn't read recently | #24 | Streaming audit batches; restart at ~80% context |
| Multiple subagents writing to the same file | #25 | Directory isolation per agent; sequential merge |
