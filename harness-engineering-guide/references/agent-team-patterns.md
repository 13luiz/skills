# Multi-Agent Coordination Patterns

## When to Read This Document

- Design Mode Level 3 (Production Organization) — choosing a coordination topology
- Designing harness for projects using 2+ concurrent AI agents
- Planning CI/verification for multi-agent workflows
- Diagnosing coordination failures in existing multi-agent setups

---

## The Coordination Problem

A single agent failing produces a bad PR. Multiple agents failing in coordination produce **cascading corruption**: conflicting writes, duplicated work, boundary violations, and verification blind spots where each agent assumes another checked it.

Multi-agent workflows need stronger harness than single-agent setups. The coordination topology determines which dimensions need reinforcement.

---

## Six Coordination Topologies

### 1. Pipeline

Sequential stages where each agent's output feeds the next agent's input.

```
[Analyze] → [Design] → [Implement] → [Verify]
```

**When to use:** Strict sequential dependencies — each stage requires the previous stage's complete output.

**Examples:** Novel writing (worldbuilding → characters → plot → prose → editing), migration workflows (analysis → plan → execute → verify).

**Harness requirements by dimension:**

- **Dim 7 (Long-Running):** Checkpoint files between stages. If stage 3 fails, restart from stage 2 output, not from scratch. Use structured handoff files at each stage boundary.
- **Dim 4 (Testing):** Contract tests between stages — validate that stage N's output matches stage N+1's expected input schema.
- **Dim 3 (Observability):** Per-stage timing metrics. Pipeline bottleneck detection requires knowing which stage is slow.

**Anti-pattern:** Long pipelines (5+ stages) without checkpoints. One crash restarts hours of work.

---

### 2. Fan-out / Fan-in

Parallel independent work converging at a merge point.

```
         ┌→ [Expert A] ─┐
[Split]  ├→ [Expert B] ─┼→ [Merge]
         └→ [Expert C] ─┘
```

**When to use:** Same input needs analysis from multiple independent perspectives, or a large task can be split into non-overlapping subtasks.

**Examples:** Multi-angle research (web, academic, community, industry), parallel code review (security, performance, architecture), multi-language translation.

**Harness requirements by dimension:**

- **Dim 2 (Mechanical):** Directory isolation. Each parallel agent writes to its own directory (`_workspace/agent-a/`, `_workspace/agent-b/`). File locking or directory partitioning prevents conflicting writes.
- **Dim 4 (Testing):** Merge-point integration tests. Individual agent outputs may each be valid but incompatible when combined.
- **Dim 6 (Entropy):** Deduplication at merge. Parallel agents independently produce overlapping content — the merge step must detect and consolidate duplicates.

**Anti-pattern:** Multiple agents writing to the same file without coordination. Git merge conflicts at best, silent data loss at worst.

---

### 3. Expert Pool / Router

A router dispatches work to specialized agents based on input type.

```
[Router] → { Security Expert | Performance Expert | Architecture Expert }
```

**When to use:** Input types vary and each type needs different domain expertise. Not all experts are needed for every request.

**Examples:** Code review routing (security issues → security expert, performance issues → performance expert), customer support triage, multi-language code generation.

**Harness requirements by dimension:**

- **Dim 1 (Architecture):** Router rules documented in a machine-readable format. The routing decision must be deterministic or at least auditable.
- **Dim 2 (Mechanical):** Routing accuracy tests. A misrouted task wastes the expert's context and produces wrong output.
- **Dim 3 (Observability):** Route distribution logs. Monitor which experts are overloaded and which are idle.

**Anti-pattern:** Routing logic embedded in a prompt instead of a structured rule set. Routing drifts silently as prompts change.

---

### 4. Producer-Reviewer (Generator-Evaluator)

One agent generates output, another independently verifies it. Failures loop back for correction.

```
[Producer] → [Reviewer] → (issues found?) → [Producer] retry
                         → (clean?) → done
```

**When to use:** Output quality is critical and objective verification criteria exist.

**Examples:** Code generation + adversarial verification, content creation + editorial review, data extraction + validation.

**Harness requirements by dimension:**

- **Dim 4 (Testing):** Reviewer must be permission-isolated (read-only). A reviewer that can modify code is no longer independent. See `references/adversarial-verification.md` for the complete pattern.
- **Dim 8 (Safety):** Maximum retry count (2-3). Unbounded retry loops waste tokens and may never converge.
- **Dim 2 (Mechanical):** Reviewer's findings must be in structured format (not prose). Structured output enables automated tracking of issue categories and resolution rates.

**Anti-pattern:** Reviewer has write access and "fixes" issues directly, collapsing the separation between generator and evaluator.

**Note:** This pattern maps directly to the Generator-Evaluator pattern described in `references/testing-patterns.md` and the adversarial verification system in `references/adversarial-verification.md`. Those documents contain implementation-level detail; this section covers the coordination topology.

---

### 5. Supervisor / Dynamic Dispatch

A central supervisor monitors progress and dynamically assigns work to worker agents.

```
              ┌→ [Worker A]
[Supervisor]  ├→ [Worker B]    ← assigns based on progress and load
              └→ [Worker C]
```

**When to use:** Work volume is variable, task assignment depends on runtime state, or workers have different speeds/capacities.

**Examples:** Large-scale code migration (supervisor assigns file batches based on completion rate), parallel test suite execution, bulk data processing.

**Harness requirements by dimension:**

- **Dim 7 (Long-Running / Durable Execution):** Structured progress tracking — supervisor needs a machine-readable task list with status per worker (use JSON task trackers, not prose). Checkpoint after each completed batch so a crashed supervisor resumes from the last checkpoint, not from the beginning.
- **Dim 3 (Observability):** Task assignment and completion logs. Diagnose bottleneck workers and reassign stalled tasks.

**Difference from Fan-out:** Fan-out assigns all work upfront. Supervisor assigns dynamically based on progress. Use Supervisor when the total work is large or unpredictable.

**Anti-pattern:** Supervisor micro-manages with too-small task units. Coordination overhead exceeds the work itself.

---

### 6. Hierarchical Delegation

Upper-level agents decompose work and delegate to lower-level agents, potentially recursively.

```
[Lead]  → [Team-A Lead] → [Worker A1]
                         → [Worker A2]
        → [Team-B Lead] → [Worker B1]
```

**When to use:** Problem naturally decomposes into hierarchical domains (e.g., fullstack: frontend lead + backend lead, each with specialists).

**Harness requirements by dimension:**

- **Dim 1 (Architecture):** Clear boundary documentation between hierarchy levels. Each level must know its scope and not reach into other branches.
- **Dim 2 (Mechanical):** Cross-branch dependency detection. Worker A1 importing from Worker B1's domain is a boundary violation.
- **Dim 5 (Context):** Context budget per level. Deeper hierarchies lose context at each delegation step. Maximum 2 levels recommended.

**Anti-pattern:** Hierarchies deeper than 3 levels. Context degrades at each level, and the top-level agent loses visibility into leaf-level decisions.

---

## Composite Patterns

Real-world workflows commonly combine patterns:

| Composite | Components | Example |
|-----------|-----------|---------|
| Fan-out + Producer-Reviewer | Parallel generation, each with independent review | Multi-language translation — 4 parallel translators, each paired with a native reviewer |
| Pipeline + Fan-out | Sequential stages with a parallel phase in the middle | Analysis (sequential) → Implementation (parallel by module) → Integration testing (sequential) |
| Supervisor + Expert Pool | Supervisor routes to domain experts dynamically | Customer support — supervisor classifies tickets, assigns to appropriate expert |

**Harness implication:** Composite patterns stack dimension requirements. A Pipeline + Fan-out needs both checkpoint files (Dim 7) and directory isolation (Dim 2).

---

## Dimension Impact Matrix

Which dimensions need reinforcement for each topology:

| Topology | Dim 1 Arch | Dim 2 Mechanical | Dim 3 Observability | Dim 4 Testing | Dim 5 Context | Dim 6 Entropy | Dim 7 Long-Running | Dim 8 Safety |
|----------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Pipeline | - | - | M | H | - | - | H | - |
| Fan-out/Fan-in | - | H | - | H | - | H | - | - |
| Expert Pool | H | H | M | - | - | - | - | - |
| Producer-Reviewer | - | M | - | H | - | - | - | H |
| Supervisor | - | - | H | - | - | - | H | - |
| Hierarchical | H | H | - | - | H | - | - | - |

H = High priority, M = Medium priority, - = Standard priority

---

## Choosing a Topology — Decision Tree

```
How many agents are involved?
├── 1 agent → No coordination pattern needed. Focus on single-agent harness.
│
└── 2+ agents →
    │
    ├── Is the work strictly sequential?
    │   └── Yes → Pipeline
    │
    ├── Can work be done in parallel without inter-agent communication?
    │   └── Yes → Fan-out / Fan-in
    │
    ├── Does the input type determine which agent should handle it?
    │   └── Yes → Expert Pool / Router
    │
    ├── Does output need independent quality verification?
    │   └── Yes → Producer-Reviewer
    │
    ├── Is work volume dynamic or unpredictable?
    │   └── Yes → Supervisor
    │
    └── Does the problem decompose into natural hierarchical domains?
        └── Yes → Hierarchical Delegation
```

When multiple patterns apply, prefer the simpler one. Combine patterns only when a single pattern cannot express the workflow.

---

## Platform-Agnostic Implementation

These patterns are independent of any specific AI coding tool. Implementation mechanisms vary by platform:

| Mechanism | Purpose | Examples |
|-----------|---------|---------|
| **File-based handoff** | Pass data between agents via structured files in a workspace directory | `_workspace/stage-1-output.json`, `_workspace/agent-a/results.md` |
| **Task tracking file** | Shared JSON/YAML tracking task status and assignments | `progress.json`, feature tracker (see `references/durable-execution.md`) |
| **Directory isolation** | Prevent parallel agents from conflicting writes | Each agent gets a dedicated output directory |
| **Structured messages** | Pass findings or requests between coordinated agents | JSON-formatted inter-agent messages with schema |
| **Checkpoint files** | Enable crash recovery at stage boundaries | Stage output files that persist across sessions |

The harness ensures these mechanisms are in place regardless of which multi-agent framework orchestrates the agents — the coordination patterns and their dimension requirements remain the same.
