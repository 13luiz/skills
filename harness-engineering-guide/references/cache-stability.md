# Cache Stability & Context Management

How repository design affects agent context efficiency. Read when implementing Context Engineering improvements (Dimension 5) or diagnosing context overflow problems.

---

## Why Cache Stability Matters for Harness Engineering

Prompt caching (reusing KV cache across requests) reduces API costs by 41-80% and improves latency by 13-31%. But cache stability is fragile: any change to the prompt prefix invalidates everything below it.

A well-designed harness **naturally supports cache stability** by:
- Externalizing knowledge into files the agent reads on demand (not stuffed into prompts)
- Using structured state files that agents can search/read rather than carrying in context
- Organizing documentation for progressive disclosure rather than monolithic loading

This is not about the agent runtime implementation — it is about how the **repository itself** is structured to be cache-friendly.

---

## Core Principles

### 1. Stable Prompt Prefix
The most cache-friendly prompt ordering is:
1. Static system prompt and tool definitions
2. Project memory (AGENTS.md, conventions)
3. Session-level state summary
4. Recent messages and tool results
5. Latest user turn

**Harness implication**: AGENTS.md should be stable and concise (under 150 lines for single-package projects; monorepo: base 150 + ~5 lines per package, cap 300). Volatile information belongs in separate files the agent reads on demand, not in the instruction file itself.

### 2. Fixed Tool Catalog Per Session
Adding or removing tools mid-session invalidates the entire cache below the tool definitions. This is one of the most expensive mistakes in agent operations.

**Harness implication**: MCP server configurations should be deliberate. Don't load 50 MCP servers "just in case." Keep the always-loaded set small and stable; use deferred loading for rarely-used tools.

### 3. Externalize Large Outputs
When tool outputs exceed ~8-16k tokens, they should be written to files and referenced by path rather than kept in context. This prevents context bloat and preserves cache for more valuable content.

**Harness implication**: Projects should have clear artifact directories (`reports/`, `artifacts/`, `exec-plans/`) where agents can park large intermediate results.

### 4. Structured State Over Prose
JSON/YAML state files are more cache-friendly than prose because:
- They are compact (less token waste)
- They are searchable (agents can grep for specific fields)
- Models are less likely to casually rewrite them

**Harness implication**: Use `progress.json` or `features.json` for structured tracking, not markdown narratives.

---

## Multi-Tier Context Management

When agents hit context limits, the harness should support a tiered recovery strategy:

| Tier | Strategy | When to Use |
|------|----------|------------|
| 0 | **Structured outputs** | Always — tool results should be concise and typed by default |
| 1 | **Large-result eviction** | When any single tool output exceeds ~8k tokens — write to file, return summary + path |
| 2 | **Deferred compression** | When context reaches ~80% capacity — rewrite old bulky results into references |
| 3 | **Compaction** | When still too full — summarize older history into goal/state/tasks/next-step |
| 4 | **Fresh-window restart** | When state is well-externalized — start fresh, rediscover from files/tests/git |

**Key insight**: A repository with strong externalized state (structured docs, progress files, passing tests) makes Tier 4 restarts cheap and effective. This is why Dimensions 1 and 7 of the audit directly support cache stability.

---

## Audit Relevance

### Checklist Item 5.5: Cache-Friendly Context Design

When auditing, check for:
- AGENTS.md size (under dynamic threshold: default <150, monorepo up to 300; stable content, no volatile data)
- Artifact directories for large intermediate outputs
- Structured state files (JSON/YAML) vs prose-only tracking
- Documentation organized for search/read rather than bulk loading
- MCP server count (flag if >10 always-loaded servers)

### Anti-Patterns

- **Monolithic AGENTS.md** (>200 lines) — forces entire instruction set into every prompt
- **No artifact directories** — large tool outputs stay in context permanently
- **Prose-only progress tracking** — hard to search, easy to lose in compaction
- **Dynamic tool catalog** — tools added/removed mid-session destroy cache
- **Stuffing all docs into system prompt** — use search/read instead of preloading

---

## References

- Anthropic: "Prompt caching" — cache hierarchy is tools → system → messages
- arXiv 2601.06007: "Don't Break the Cache" — strategic cache block control outperforms full-context caching
- 2026 Blueprint: Append-only event log plus typed state snapshots for cache stability
