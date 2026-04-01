# Anti-Patterns to Flag

Common anti-patterns found in harness engineering. Flag these during audit (Mode 1) and actively prevent them during implementation (Mode 2) or design (Mode 3).

---

## Verification Anti-Patterns

1. **AI tests verifying AI code** — Circular verification. Tests should independently verify logic, not mirror the implementation they claim to check.
2. **Agent self-evaluation** — Agents rate themselves too highly. Use external verification with an independent verifier agent.
3. **Verification without execution** — Verifier reads code and writes "PASS" without running commands. A check without a command-run block is a skip, not a pass.
4. **Happy-path-only verification** — Verifier confirms the feature works with normal input but never tries to break it. At minimum, one adversarial probe (boundary value, concurrent request, missing resource) is required.
5. **Test results are evidence** — LLM-written tests may use circular assertions or excessive mocking. Passing tests confirm the happy path; independent adversarial verification confirms correctness.

## Documentation Anti-Patterns

6. **Encyclopedia AGENTS.md** — Files exceeding the dynamic threshold (default 150 lines; monorepo: up to 300). Should be a concise TOC with pointers to deeper docs.
7. **LLM-generated agent config** — Human-crafted instruction files outperform AI-generated ones because they encode domain-specific constraints.
8. **Full test suite in agent context** — Floods context with passing output. Configure CI to surface errors only (succeed silently, fail verbosely).

## Tool & Context Anti-Patterns

9. **Tool hoarding** — Dozens of MCP servers bloat context and break cache stability. Target <10 always-loaded servers.
10. **Dynamic tool catalog mid-session** — Invalidates prompt cache. Fix the tool catalog at session start.
11. **Trusting tool output blindly** — MCP server output is untrusted input. Validate before acting on results.

## Constraint Anti-Patterns

12. **Lint but don't block** — CI runs the linter and reports violations but doesn't fail the build. Agents see green checks and assume compliance. A gate that doesn't block is advisory noise, not a constraint.
13. **Coverage theater** — High coverage numbers (80%+) achieved via trivial assertions (`expect(true).toBe(true)`) or excessive mocking that tests the mock, not the code. Coverage without meaningful assertions is a vanity metric.

## Context & Knowledge Anti-Patterns

14. **Knowledge lives in Slack** — Critical decisions, conventions, and context exist only in chat threads, Notion pages, or email. Agents cannot access external channels. Externalize to in-repo docs or ADRs.
15. **TODO-driven debt management** — Using `TODO` / `FIXME` / `HACK` comments as the sole mechanism for tracking tech debt. Comments are invisible to planning and trend analysis. Use a maintained tracker artifact.

## Process Anti-Patterns

16. **Optimizing prompts instead of harness** — Improve the environment (constraints, feedback, verification), not the phrasing. Ask "what capability is missing?" not "how do I word this better?"
17. **Manual garbage collection** — Automate cleanup with scheduled agents or CI jobs. "Friday cleanup sprints" don't scale.
18. **No crash recovery** — Multi-step tasks need structured checkpoint files (`progress.json`) and documented recovery protocols.
19. **No environment health check** — Agents building on broken environments compound errors. Use `init.sh` with health checks.
20. **Stateless multi-session** — Each agent session starts from scratch with no awareness of previous progress. Without structured handoff artifacts (progress logs, execution plans, feature status), agents repeat work or contradict earlier decisions.

## Safety Anti-Patterns

21. **Convenience admin token** — Using a single broad-permission token for all agent operations because scoping is "too much work." A compromised or misbehaving agent with admin access has unlimited blast radius. Scope tokens to the minimum required permissions per operation.

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
| Key decisions only in Slack/Notion | #14 | Externalize to in-repo docs or ADRs |
| Tech debt tracked only via TODO comments | #15 | Add `tech-debt-tracker.json` or issue labels |
| 15+ MCP servers loaded | #9 | Audit and remove rarely-used servers |
| No `progress.json` or checkpoint files | #18 | Add durable execution support |
| Each session starts without handoff context | #20 | Structured progress logs + feature status |
| Verifier report has no "Command run" blocks | #3 | Require executable evidence |
| Agent tokens have admin/write-all permissions | #21 | Scope to minimum required permissions |
