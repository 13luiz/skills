# Protocol Layer Hygiene (MCP / ACP / A2A)

How agent communication protocols affect harness security and reliability. Read when auditing Safety Rails (Dimension 8), designing Level 3 harness strategies, or evaluating MCP server configurations.

---

## The Three Protocol Boundaries

By 2026, agent systems communicate across three distinct protocol layers:

| Protocol | Relationship | Purpose |
|----------|-------------|---------|
| **MCP** (Model Context Protocol) | Agent → Tools/Resources | Tool discovery, execution, and data access |
| **ACP** (Agent Client Protocol) | Client/IDE → Agent Runtime | Session management, approvals, streaming |
| **A2A** (Agent-to-Agent Protocol) | Agent → Remote Agent | Task delegation, capability discovery, artifact exchange |

These protocols are **complementary, not competing**. MCP handles vertical integration (agent-to-tools), A2A handles horizontal integration (agent-to-agent), and ACP handles the user-facing surface.

---

## MCP: Tool Trust Boundaries

MCP is the most relevant protocol for harness auditing because it defines what tools agents can access and how.

### Security Principles

1. **Tool output is untrusted.** MCP server responses — including tool descriptions and annotations — should be treated as potentially adversarial. Do not let tool output dictate agent behavior without validation.

2. **Least-privilege tool scoping.** Each MCP server should expose only the tools needed for its purpose. A database MCP server should not also have filesystem write access.

3. **Namespace hygiene.** Tools should use clear namespaces (`db.query`, `fs.read`, `web.search`) to prevent confusion and enable policy rules per namespace.

4. **Deferred loading for large catalogs.** When many MCP servers are configured, use deferred/lazy loading so only frequently-used tools are always present. This preserves cache stability and reduces selection confusion.

5. **Audit trail for tool invocations.** Log which MCP tools were called, with what arguments, and what they returned. This is essential for post-incident analysis.

### Common MCP Anti-Patterns

- **Tool hoarding**: 20+ MCP servers loaded simultaneously, most rarely used
- **Broad filesystem access**: MCP servers with unrestricted read/write to the entire filesystem
- **No approval gates**: Destructive MCP tools (delete, deploy, migrate) without human confirmation
- **Trusted by default**: Treating all MCP server output as authoritative without validation

---

## ACP and A2A (Future Reference)

Two emerging protocols complement MCP but do not yet map to audit checklist items:

- **ACP** (Agent Client Protocol): Standardizes IDE/client-to-agent communication — typed events, session management, approval flows. Design your internal event model to be ACP-compatible.
- **A2A** (Agent-to-Agent Protocol): Enables task delegation to remote specialized agents via Agent Cards and artifact-based outputs. Relevant for production organizations with specialized agent roles.

These protocols are complementary, not competing: MCP handles agent-to-tools (vertical), A2A handles agent-to-agent (horizontal), ACP handles user-to-agent.

---

## Audit Relevance

### Checklist Item 8.6: Tool Protocol Trust Boundaries

When auditing, check for:

| Evidence | Score |
|----------|-------|
| MCP servers scoped to minimum permissions, tool output treated as untrusted, audit trail for invocations | PASS |
| Some MCP configuration but broad permissions or no audit trail | PARTIAL |
| No awareness of tool trust boundaries, or unrestricted tool access | FAIL |

### What to Look For
- Count of configured MCP servers (flag if >10 always-loaded)
- Filesystem access scope of each MCP server
- Presence of approval gates for destructive tool operations
- Whether tool output validation exists before acting on results
- Namespace conventions in tool naming

---

## References

- MCP Specification (Linux Foundation, 2025-11-25): Trust boundaries and tool safety
- A2A Protocol: Agent Cards, task-based execution, artifact separation
- ACP: JSON-RPC 2.0 session management for IDE/client integration
- 2026 Blueprint: "Do not force one protocol to do all three jobs"
