# Testing Patterns for AI-Assisted Development

## The Generator-Evaluator Pattern

From Anthropic's research: separate the agent that writes code from the agent that verifies it. This is the single most impactful testing pattern for AI-assisted development.

"Tuning a standalone evaluator to be skeptical turns out to be far more tractable than making a generator critical of its own work." Models confidently praise their own output regardless of quality.

### Implementation

```
Human defines acceptance criteria
        |
        v
Generator Agent --> writes code --> Evaluator Agent --> runs tests, checks types
        ^                                    |
        |                                    v
        +--- feedback with specific errors --+
```

The evaluator:
- Runs deterministic checks (tests, types, lint)
- Cannot modify code (read-only access)
- Reports specific, actionable failures
- Has no knowledge of what the generator was told to do

## Test Results Are Context, Not Evidence

A passing test suite tells you what the implementer *intended* to verify. It does not prove the system works correctly. When the implementer is an LLM, its tests may be:

- **Heavy on mocks** — testing that the mock behaves as coded, not that the system works
- **Circular assertions** — the test asserts the exact output the implementation produces, rather than independently computing the expected result
- **Happy-path only** — 100% coverage on normal inputs, 0% on error paths, edge cases, and concurrent access

Run the test suite and note results — then move on to independent verification. The suite is input to your assessment, not the assessment itself.

### Verification Signal Hierarchy

Signals are not equal. Rank evidence by independence from the implementer:

| Tier | Signal | Independence | Why |
|------|--------|-------------|-----|
| 1 | Type checks, linters | Highest | Deterministic, predates implementation, cannot be gamed |
| 2 | Human-written tests | High | Independent author with different assumptions |
| 3 | E2E / browser tests hitting real endpoints | High | Exercises actual system behavior end-to-end |
| 4 | Adversarial verifier probes | High | Deliberately targets failure modes |
| 5 | AI-written tests (reviewed) | Medium | Subject to same biases but human-validated |
| 6 | AI-written tests (unreviewed) | Low | Circular — same model, same blind spots |
| 7 | Agent self-assessment ("looks correct") | None | Models confidently praise their own output |

A robust verification strategy combines signals from tiers 1-4. Relying solely on tier 6-7 is open-loop verification.

## Anti-Pattern: AI Tests for AI Code

AI-generated tests validating AI-generated code defeats verification. Same biases that produce wrong code produce wrong tests.

**Rules:**
- Tests should be written or verified by humans
- If an agent writes tests, a human must review before they join the verification suite
- "Double bookkeeping": tests independently verify logic from a different angle
- If all your checks are "returns 200" or "test suite passes," you have confirmed the happy path, not verified correctness

## Test Hierarchy for Agent Work

### 1. Type Checks (fastest, always run)
Catches: wrong types, missing properties, hallucinated APIs.
Time: seconds. Run on every save.

### 2. Lint Rules (fast, always run)
Catches: style violations, architectural boundaries, anti-patterns.
Time: seconds. Run on every save.

### 3. Unit Tests (fast, run on commit)
Catches: logic errors in isolated functions.
Time: seconds to minutes.

### 4. Integration Tests (medium, run in CI)
Catches: incorrect interactions between components.
Time: minutes.

### 5. Structural Tests (medium, run in CI)
Catches: architectural violations, dependency direction breaches.
Time: seconds.

### 6. End-to-End Tests (slow, run in CI or post-merge)
Catches: user-visible failures, workflow breakages.
Time: minutes.

**Critical rule:** Only surface errors to agent context. Suppress passing output. Passing output floods context and degrades performance.

## Structured Completion Tracking

From Anthropic — use JSON, not prose:

```json
{
  "features": [
    {
      "id": "auth-login",
      "description": "User can log in with email and password",
      "status": false,
      "e2e_verified": false
    }
  ]
}
```

**Rules:**
- Agents may only set `status: true` after tests pass
- Agents may NOT delete features, change descriptions, or modify criteria
- `e2e_verified` requires browser-based verification

## Test-Driven Agent Workflow

From OpenHands research:

1. Agent reads the issue/task
2. Agent writes failing tests demonstrating the problem
3. Agent is told NOT to implement until tests fail
4. Agent implements the fix
5. CI verifies all tests pass
6. Human reviews both tests and implementation

Prevents agents from writing trivially-passing tests.

## Back-Pressure Verification

From HumanLayer's research on effective hooks:

```bash
#!/bin/bash
set -e

npx tsc --noEmit 2>&1 | tail -20
npx eslint --quiet . 2>&1 | tail -20
npx vitest run --reporter=verbose --changed 2>&1 | tail -30

# Only errors reach the agent. Passing output suppressed.
```

Key: **swallow passing output, surface errors only.** Full test suite output floods context causing hallucinations.

## Competitive Generation

For critical features, generate multiple solutions:

1. Ask 3 agents to implement independently
2. Rank by: tests passed, smallest diff, no new dependencies
3. Merge the winner
4. Cost is 3x but significantly reduces rework

Use selectively for high-risk changes.
