# Control Theory Framework for Harness Engineering

The theoretical grounding for harness engineering. Read when someone asks "why does this matter?" or to explain the deeper rationale behind the checklist.

---

## Four Elements at a Glance

| # | Element | One-Liner | In the Harness | Audit Dimensions |
|---|---------|-----------|---------------|-----------------|
| 1 | **Goal State** | What "correct" looks like | Architecture docs, quality standards, done criteria, golden principles | Dim 1 (Arch Docs) + Dim 5 (Context Eng.) |
| 2 | **Sensor** | Detects deviation from the goal | Tests, linters, logs, metrics, screenshots, browser automation | Dim 3 (Observability) + Dim 4 (Testing) |
| 3 | **Actuator** | Forces correction | CI gates that block PRs, auto-formatters, revert scripts, refactoring PRs | Dim 2 (Mechanical) + Dim 4 (Testing) |
| 4 | **Feedback Loop** | Routes results back to goal comparison | CI fail→fix→pass cycles, review→lint rule capture, quality trend tracking | Dim 3 (Observability) + Dim 6 (Entropy) + Dim 7 (Long-Running) |

> **Key insight**: A system missing any one element is **open-loop** — it cannot self-correct. The audit checklist is structured so that each dimension maps to one or more control loop elements. A repo that scores F on any element's dimensions has a broken control loop regardless of other scores.

---

## The Core Equation

Harness engineering is cybernetics applied to AI agent systems. The same control loop governing a steam engine governor, a thermostat, a Kubernetes controller, and a PID controller also governs a well-designed agent harness.

```
    ┌──────────────┐
    │  Goal State   │ ← What "correct" looks like
    └──────┬───────┘
           │ compare
           ▼
    ┌──────────────┐
    │   Sensor      │ ← Detects deviation (tests, lints, logs)
    └──────┬───────┘
           │ deviation signal
           ▼
    ┌──────────────┐
    │  Actuator     │ ← Corrects the system (revert, fix, refactor)
    └──────┬───────┘
           │ correction
           ▼
    ┌──────────────┐
    │ Feedback Loop │ ← Routes results back to goal comparison
    └──────┬───────┘
           │
           └────────── back to Goal State
```

Without any one of these four components, the system is **open-loop** — it cannot self-correct.

---

## Three Historical Precedents

### 1. The Steam Engine Governor (18th Century)

Before the centrifugal governor, workers manually adjusted steam valves to prevent engines from running too fast or too slow. The governor automated this: spinning weights sensed rotational speed (sensor), which mechanically adjusted the valve (actuator), keeping RPM near target (goal state).

The key shift: workers moved from **manually adjusting valves** to **setting target speed and tuning sensitivity**. This is exactly the shift harness engineering demands.

### 2. Kubernetes Controllers (Cloud-Native Era)

Before Kubernetes, ops engineers manually restarted failed services, scaled replicas, and rolled back deployments. K8s declarative controllers automated this:

- **Goal State**: YAML manifests ("3 replicas of service X")
- **Sensor**: Controller watches actual cluster state
- **Actuator**: Creates/destroys pods, routes traffic, rolls back
- **Feedback Loop**: Reconciliation runs continuously, converging actual -> desired

The engineer's job shifted from **pressing buttons** to **writing specifications**.

### 3. The Agent Harness (AI-Native Era)

| Component | Without Harness | With Harness |
|-----------|----------------|--------------|
| Goal State | Vague prompt ("make it better") | Encoded standards (architecture rules, quality scores, feature list) |
| Sensor | Nothing — agent can't see mistakes | Tests, linters, logs, metrics, screenshots |
| Actuator | Nothing — mistakes persist | Auto-fix, revert, refactor PRs, doc updates |
| Feedback | Open loop — same mistakes repeat | CI results inform next run, review -> lint rules, quality trends |

---

## The Four Components in Practice

### 1. Goal State: Defining "Correct"
> **Audit mapping**: Dimension 1 (Architecture Docs & Knowledge) + Dimension 5 (Context Engineering)

Everything that defines what the agent should produce:
- Architecture documentation (boundaries, dependency directions, layer rules)
- Quality standards (naming, file sizes, code style)
- Done criteria (feature lists with pass/fail, acceptance tests)
- Golden principles ("validate at boundaries", "prefer shared utilities")
- Product specs (what the software should do)

**Critical insight from OpenAI: anything not written in the repository does not exist for the agent.** If your goal state lives in heads, Slack, or Google Docs, the agent cannot see it.

### 2. Sensor: Detecting Deviation
> **Audit mapping**: Dimension 3 (Feedback Loops & Observability) + Dimension 4 (Testing & Verification)

Multiple layers provide defense in depth:

| Sensor Layer | What It Catches | Speed |
|--------------|-----------------|-------|
| Type checker | Structural errors | Immediate |
| Linter | Style and pattern violations | Immediate |
| Unit tests | Logic errors | Fast (seconds) |
| Integration tests | Interface mismatches | Moderate |
| E2E tests | Functional regressions | Slow (minutes) |
| Observability | Runtime behavior | Real-time |
| Browser automation | UI correctness | Slow (minutes) |
| Human review | Taste, strategy, novel issues | Very slow |

Fast sensors catch cheap mistakes early; slow sensors catch expensive mistakes that fast sensors miss.

### 3. Actuator: Correcting Deviation
> **Audit mapping**: Dimension 2 (Mechanical Constraints) + Dimension 4 (Testing & Verification)

Without actuators, sensors just report problems nobody fixes.

- **Immediate**: Auto-formatters, auto-fix lint rules
- **CI-gate**: Blocked PRs force fixing before merge
- **Refactoring**: Background agents opening cleanup PRs
- **Revert**: Git revert workflows for bad changes
- **Documentation**: Agent-driven doc updates when code changes

The richer the actuator set, the stronger the system's self-repair capability.

### 4. Feedback Loop: Closing the Circuit
> **Audit mapping**: Dimension 3 (Observability) + Dimension 6 (Entropy Management) + Dimension 7 (Long-Running Tasks)

Turns isolated checks into a self-correcting system:

- **CI failure -> agent fix -> CI pass**: Basic closed loop
- **Code review comment -> lint rule**: Human taste captured once, enforced forever
- **Quality score decline -> refactoring PR -> improvement**: Continuous maintenance
- **Stale doc detected -> doc-gardening PR -> fresh docs**: Automated knowledge upkeep
- **Production error -> log analysis -> fix PR**: Runtime driving correction

---

## Open Loop vs Closed Loop

**Open Loop (no harness)**:
```
Prompt → Agent → Code → (hope for the best)
```
No mechanism to detect or correct mistakes. Throughput limited by human attention.

**Closed Loop (with harness)**:
```
Prompt → Agent → Code → Tests/Lint/Metrics → Pass? → Merge
                                            → Fail? → Agent fixes → recheck
```
Mistakes caught mechanically. Only novel problems need human attention. Throughput scales beyond human capacity.

---

## The Evolution Chain

Three layers of increasing control:

1. **Prompt Engineering** — How you talk to the model (single interaction). Communication.
2. **Context Engineering** — What the model sees at decision time (information supply). Logistics.
3. **Harness Engineering** — What the system prevents, measures, and corrects (closed-loop control). Governance.

Prompt is expression. Context is supply. Harness is the feedback loop that makes the whole system converge on correctness.

---

## Why the Harness Matters More Than the Model

Confirmed empirically by multiple teams:

- **LangChain**: Same model, different harness -> 52.8% to 66.5% on Terminal Bench 2.0 (Top 30 to Top 5)
- **OpenAI**: Harness design, not model upgrades, was the primary lever for agent reliability in their million-line experiment
- **Anthropic**: Generator-evaluator separation (a harness pattern) was the single most impactful improvement for long-running agents

Through the control theory lens: upgrading the model is like putting a more powerful engine in a car with no steering wheel. It goes faster but still can't stay on the road. The harness is the steering, the lane markers, the guardrails.

**Practical implication: if agents produce bad output, improve the harness before upgrading the model.**

---

## The Engineering Role Shift

Control theory predicts a consistent pattern as automation increases: human roles shift from **direct operation** to **system design**.

| Era | Human Role | Control Mechanism |
|-----|-----------|-------------------|
| Pre-automation | Turn the valve | Direct physical action |
| Governor era | Set target speed | Mechanical feedback |
| Kubernetes era | Write YAML specs | Declarative reconciliation |
| Agent era | Define "correct" + design harness | Multi-layered control loops |

The harness maturity grade measures how far along this shift a team has progressed. An F-grade repo is still "turning the valve." An A-grade repo has reached "writing YAML specs."

The model determines how fast you can go. The harness determines how far you can go.
