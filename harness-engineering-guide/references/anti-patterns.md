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

## Process Anti-Patterns

12. **Optimizing prompts instead of harness** — Improve the environment (constraints, feedback, verification), not the phrasing. Ask "what capability is missing?" not "how do I word this better?"
13. **Manual garbage collection** — Automate cleanup with scheduled agents or CI jobs. "Friday cleanup sprints" don't scale.
14. **No crash recovery** — Multi-step tasks need structured checkpoint files (`progress.json`) and documented recovery protocols.
15. **No environment health check** — Agents building on broken environments compound errors. Use `init.sh` with health checks.

---

## Quick Diagnostic

When reviewing a codebase, check for these red flags:

| Red Flag | Anti-Pattern # | Quick Fix |
|----------|---------------|-----------|
| AGENTS.md exceeds threshold (>150 / >300 monorepo) | #6 | Trim to TOC, move content to `docs/` |
| No CI or CI doesn't block | Dim 2 gap | Add blocking CI pipeline (checklist 2.1) |
| Tests written by same agent that wrote code | #1 | Independent verifier agent |
| 15+ MCP servers loaded | #9 | Audit and remove rarely-used servers |
| No `progress.json` or checkpoint files | #14 | Add durable execution support |
| Verifier report has no "Command run" blocks | #3 | Require executable evidence |
