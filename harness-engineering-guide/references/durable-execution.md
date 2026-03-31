# Durable Execution for Long-Running Agent Tasks

How to make multi-step agent workflows survive crashes, interruptions, and session boundaries. Read when implementing Long-Running Task Support (Dimension 7) or designing production agent workflows.

---

## Why Durable Execution Matters for Harness Engineering

Multi-step agent tasks spanning minutes to hours routinely face:
- Session timeouts and context window exhaustion
- Human approval pauses (minutes to days)
- Transient failures in external tools or APIs
- IDE crashes or network disconnections

Without durability, any interruption means restarting from scratch — wasting LLM tokens, duplicating API calls, and losing partially completed work. Durable execution ensures agents can **resume exactly where they left off**.

---

## Core Mechanisms

### 1. Structured Progress Files (Lightweight)
The simplest form of durability: write structured state to files after each meaningful step.

```json
{
  "task": "implement-auth-module",
  "phase": 2,
  "completed_steps": ["schema-design", "migration", "model-layer"],
  "current_step": "service-layer",
  "blocked_on": null,
  "artifacts": ["src/auth/models.py", "migrations/003_auth.sql"],
  "last_updated": "2026-03-31T14:30:00Z"
}
```

A new agent session reads this file and continues from `current_step` without repeating completed work.

**When to use**: Solo developers, projects without complex orchestration needs. This is the minimum viable durable execution for any project using AI agents.

### 2. Execution Plan Checkpointing (Moderate)
Combine structured progress with a phased execution plan (see `templates/execution-plan.md`):
- Each phase has explicit status (NOT_STARTED / IN_PROGRESS / COMPLETED)
- Commits are recorded per phase for easy rollback
- Decision logs capture rationale for future sessions
- Handoff notes provide context for the next agent

**When to use**: Small teams, multi-day features, any task requiring more than one agent session.

### 3. Journal-Based Replay (Advanced)
Record each completed step in an append-only log. On crash, replay the log to reconstruct state without re-executing side effects.

Requirements for journal-based replay:
- **Idempotent operations**: Replaying a step must not duplicate its effects
- **Step boundaries**: Clear demarcation of what constitutes a single step
- **Side-effect wrapping**: External calls wrapped so replay skips already-completed ones

**When to use**: Production organizations, agent workflows with external API calls, tasks where re-execution has real costs (payments, deployments, notifications).

### 4. Saga Pattern for Compensating Rollbacks
When a multi-step task partially fails, the saga pattern provides automatic compensating actions:

```
Step 1: Create migration → (compensate: delete migration)
Step 2: Update models → (compensate: revert models)
Step 3: Update tests → (compensate: revert tests)
Step 4: Run CI → (if fail: execute compensations in reverse order)
```

**When to use**: Tasks where partial completion is worse than no completion. Database migrations, multi-service changes, deployment pipelines.

---

## Harness Design Implications

### For the Repository
- Establish `progress.json` or `progress.txt` conventions in AGENTS.md
- Create `exec-plans/` directory for multi-phase task tracking
- Include `init.sh` that validates environment before new work begins
- Define "clean state discipline" — each session ends with committable code

### For CI/CD
- CI should be able to detect and report on partially-completed execution plans
- Pre-commit hooks can validate that progress files are updated
- Post-session cleanup should flag orphaned branches or uncommitted changes

### For Agent Instructions
Document in AGENTS.md:
- How to read and update progress files
- When to create execution plan checkpoints
- What constitutes a "safe stopping point"
- How to hand off work to the next session

---

## Audit Relevance

### Checklist Item 7.6: Durable Execution Support

When auditing, check for:
- Structured progress files (`progress.json`, `progress.txt`, execution plans)
- Session recovery protocol (init.sh + state file reading)
- Clean state discipline (documented expectation for session-end state)
- Rollback capability for partially-completed multi-step changes

| Evidence | Score |
|----------|-------|
| Structured checkpoint files + recovery script + documented protocol | PASS |
| Some progress tracking but no formal recovery mechanism | PARTIAL |
| No progress persistence between sessions | FAIL |

---

## References

- Anthropic: "Harness design for long-running application development" — planner/generator/evaluator pattern
- Temporal: Durable execution as infrastructure (checkpoint-based, $5B valuation, 2026)
- Restate: Journal-based replay for AI agent workflows
- LangGraph: Durable execution with persistence threads and checkpointing
