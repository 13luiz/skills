# Adversarial Verification Patterns

How to build verification systems where the verifier actively tries to break the implementation, rather than confirming it works. Based on production patterns from Claude Code's three-layer verification architecture.

---

## Core Principle: Distrust by Default

LLM-generated self-assessments are unreliable. Models confidently praise their own output regardless of quality. The harness must enforce separation:

1. **Implementer cannot self-verify** — spawn an independent verifier
2. **Verifier cannot trust implementer's tests** — test suite results are context, not evidence
3. **Verifier's PASS must be audited** — spot-check commands from the verification report

This creates a three-party verification chain:

```
Implementer (writes code)
    → Verifier (tries to break it, read-only)
        → Auditor (re-runs 2-3 commands from verifier's report)
```

If any link breaks (verifier skips commands, auditor finds divergent output), the chain resets.

---

## Three-Layer Verification Architecture

Production verification systems use three complementary layers, each targeting a different failure point in the development lifecycle:

### Layer 1: Pre-Implementation Advisory

**When**: Before substantive work — before writing code, committing to an approach, or building on an assumption.

**Purpose**: Prevent direction errors. Cheaper to catch a wrong approach before implementation than after.

**Design**:
- Advisory agent has read-only access to the full conversation context
- May use a stronger model than the implementer
- Output is free-text guidance, not structured verdicts
- Invoked at decision points, not on every action

**Key behavior**: If the implementer has evidence pointing one way and the advisor suggests another, surface the conflict explicitly rather than silently switching direction.

### Layer 2: Post-Implementation Adversarial Verification

**When**: After non-trivial implementation is complete (3+ file edits, backend/API changes, infrastructure changes).

**Purpose**: Independently verify the implementation works end-to-end by trying to break it.

**Design**:
- Verification agent runs as a separate process (background, non-blocking)
- Strictly read-only for project files (see Permission Isolation below)
- Must produce structured reports with evidence (see Output Format below)
- Ends with a verdict: PASS / FAIL / PARTIAL

**Trigger rule**: Non-trivial implementation → independent verification → before reporting completion. The implementer, forks, and subagents' self-checks do NOT substitute for adversarial verification.

### Layer 3: Plan Verification

**When**: After exiting a planning phase, once implementation claims to be complete.

**Purpose**: Verify every item in the plan was actually completed, not just the easy ones.

**Design**:
- Walks the plan item by item
- Checks each against actual state (files exist, tests pass, features work)
- Periodic reminders ensure verification isn't forgotten (e.g., every N turns)

---

## Anti-Rationalization Engineering

LLMs have documented patterns of rationalizing away the need to run actual verification. A well-designed verification system must preemptively identify and block these patterns.

### The Six Rationalization Traps

Embed these in verifier system prompts as "failure modes you must recognize in yourself":

| Rationalization | Why It's Wrong | Counter-Instruction |
|----------------|---------------|-------------------|
| "The code looks correct based on my reading" | Reading is not verification. Code review catches ~60% of bugs; execution catches the rest. | Run the code. If you wrote an explanation instead of a command, stop and run the command. |
| "The implementer's tests already pass" | The implementer is an LLM too. Tests may use circular assertions, excessive mocking, or happy-path-only coverage. | Tests are context, not evidence. Run your own independent checks. |
| "This is probably fine" | "Probably" is not "verified." Confidence without execution is the primary failure mode. | The word "probably" in your reasoning is a red flag. Replace it with a command. |
| "Let me check the code to verify" | Checking code means reading it. Verification means executing it and observing behavior. | Start the server. Hit the endpoint. Click the button. Observe the output. |
| "I don't have the right tools for this" | Dynamic tool catalogs mean tools may be available that you haven't checked for. | Enumerate your actual available tools before claiming inability. |
| "This would take too long to verify properly" | Scope is not your decision. Partial verification with evidence beats no verification with explanations. | Run what you can. Report what you couldn't as PARTIAL with specific blockers. |

### Pre-emptive Metacognition

Tell the verifier about its own failure modes *before* it starts work. This is analogous to Constitutional AI's constraint pre-declaration but applied operationally:

```
You have two documented failure patterns:

1. Verification avoidance: when faced with a check, you find reasons not 
   to run it — you read code, narrate what you would test, write "PASS," 
   and move on.

2. Being seduced by the first 80%: you see a polished UI or a passing 
   test suite and feel inclined to pass it, not noticing half the buttons 
   do nothing, the state vanishes on refresh, or the backend crashes on 
   bad input.
```

### Balanced Verification Principle

Inspired by DeepMind's "balanced prompting" technique (Gemini Deep Think, 2026): instruct the verifier to simultaneously search for evidence that the implementation is correct AND evidence that it is broken. This prevents confirmation bias — a verifier told only to "try to break it" may still unconsciously favor passing when the first few checks succeed.

**Implementation**: Add to the verifier's system prompt:

```
For each check, actively seek BOTH:
- Evidence that this works correctly (the implementation satisfies the requirement)
- Evidence that this is broken (boundary cases, missing handling, incorrect behavior)

Report both. If you only found confirming evidence, you haven't looked hard enough.
```

This dual-search approach also improves the quality of PASS verdicts — a PASS backed by "I tried X, Y, Z to break it and couldn't" is stronger than "I confirmed A, B, C work."

### Graceful Failure Admission

Agents should be able to report "I cannot verify this" or "I cannot complete this task" rather than producing low-confidence output. An admitted failure is cheaper than a false PASS that reaches production.

**Implementation**: Include in the verifier prompt:

```
If you encounter a check you genuinely cannot perform (missing tools, 
environment issues, insufficient access), report it as PARTIAL with 
specific blockers — never guess or infer a result you cannot verify.
```

### Implementation Guidance

When building anti-rationalization into a verification system:

1. **Name the failure modes explicitly** in the system prompt — vague warnings are ignored
2. **Provide the counter-behavior** for each trap — "don't do X" is weaker than "do Y instead"
3. **Use concrete examples** of bad vs good verification (see Output Format section)
4. **Add a structural check**: if the verification report lacks command execution blocks, reject it programmatically
5. **Require balanced evidence** — verifier must report both confirming and disconfirming evidence per check

---

## Permission Isolation

The verifier must be structurally unable to modify the project, not just instructed not to.

### Dual-Layer Enforcement

**Layer 1 — Programmatic (cannot be bypassed by the model)**:
- Blocklist of write tools: file edit, file write, notebook edit, agent spawn, mode changes
- Enforced at the tool-routing level, not the prompt level

**Layer 2 — Prompt-based (defense in depth)**:
- System prompt explicitly states read-only constraint
- Critical system reminder reinforces the constraint at message boundaries

### Strategic Permission Holes

Pure read-only access is too restrictive for meaningful verification. The verifier needs to:
- Write ephemeral test scripts (race condition harnesses, multi-step tests)
- Pipe data through temporary files for complex assertions

**Solution**: Allow writes only to a temporary directory (`/tmp` or `$TMPDIR`), enforced by allowing `BashTool` while blocking `FileWrite`/`FileEdit`. The verifier can create test scripts in temp space without touching project files.

```
Allowed:
  echo 'test script' > /tmp/verify_race.sh && bash /tmp/verify_race.sh

Blocked:
  FileEdit("src/main.ts", ...)    → tool not available
  FileWrite("tests/new.test.ts")  → tool not available
```

### Isolation Checklist

When designing verifier permissions:
- [ ] All file-write tools removed from available tool set
- [ ] Agent-spawn tool removed (prevents nested agents bypassing restrictions)
- [ ] Bash/shell tool retained (needed for running commands)
- [ ] File-read and search tools retained (needed for code inspection)
- [ ] Web/API tools retained (needed for endpoint testing)
- [ ] Browser automation retained if available (needed for frontend verification)
- [ ] Temp directory write-path documented and communicated to verifier

---

## Structural Nudges and Trigger Mechanisms

Relying on the model's "self-discipline" to invoke verification is insufficient. Build programmatic triggers that fire at the exact moments where skipping is most likely.

### Three Complementary Trigger Types

**1. System Prompt Contract (soft constraint)**

Inject a verification obligation into the main agent's system prompt:

```
The contract: when non-trivial implementation happens on your turn, 
independent adversarial verification must happen before you report 
completion — regardless of who did the implementing.
```

Define "non-trivial": 3+ file edits, backend/API changes, infrastructure changes.

**2. Tool Return Injection (hard nudge)**

When task-tracking tools detect all tasks marked complete but none involve verification, inject a reminder into the tool's return value:

```
NOTE: You just closed out 3+ tasks and none was a verification step. 
Before writing your final summary, spawn the verification agent.
```

This fires at the "loop-exit moment where skips happen" — when the agent is about to declare completion and move on. The nudge appears in a tool response the agent must process, making it harder to ignore than a system prompt instruction.

**Trigger conditions** (all must be true):
- Verification feature is enabled
- Running in the main thread (not inside a sub-agent)
- All tasks are marked complete
- Task count >= 3 (non-trivial work)
- No task content matches `/verif/i` (no verification step exists)

**3. Periodic Reminders (cyclic nudge)**

For plan verification, attach a reminder every N user turns (e.g., every 10 turns) if verification hasn't started:

```
You have completed implementing the plan. Please verify that all plan 
items were completed correctly.
```

### Choosing the Right Trigger

| Situation | Best Trigger |
|-----------|-------------|
| General verification obligation | System prompt contract |
| Task completion without verification | Tool return injection |
| Long-running plan execution | Periodic reminders |
| Critical infrastructure changes | All three simultaneously |

---

## Type-Specialized Verification Strategies

Different change types require different verification approaches. Generic "run the tests" is insufficient.

### Verification Strategy Matrix

| Change Type | Core Strategy | Key Commands | Watch For |
|------------|--------------|-------------|-----------|
| **Frontend** | Start dev server → browser automation (screenshot, click, console) → curl sub-resources | `npm run dev`, Playwright/browser MCP, `curl` image/API routes | Buttons that render but do nothing; state lost on refresh; console errors hidden by UI |
| **Backend/API** | Start server → curl endpoints → verify response structure → error handling → edge cases | `curl -s -X POST`, `jq`, response status + body | Status 200 with wrong body; missing error responses; no input validation |
| **CLI/Script** | Run with representative inputs → check stdout/stderr/exit code → boundary inputs → `--help` accuracy | Direct execution, `echo $?`, `--help` | Exit code 0 on failure; `--help` that doesn't match actual flags |
| **Infrastructure** | Syntax validation → dry-run → verify env var references exist | `terraform plan`, `kubectl --dry-run`, `docker compose config` | References to undefined secrets; misconfigured networking |
| **Library/Package** | Build → full test suite → import public API from fresh context → types match docs | `npm pack && npm install`, import tests | Exports that don't match documentation; type definitions that diverge from runtime |
| **Bug Fix** | Reproduce original bug → verify fix → regression test → side-effect check | Bug reproduction steps, then fix verification | Fix that masks the bug without resolving root cause; regressions in related features |
| **Mobile** | Clean build → simulator install → accessibility tree dump → tap verification → kill/restart persistence | `xcodebuild`, `xcrun simctl`, accessibility dump | Crashes on specific device sizes; state lost after process kill |
| **Data/ML** | Sample input run → output schema/type validation → empty/NaN/null → silent data loss | Pipeline execution, schema validation | Silent row drops; type coercion hiding errors; NaN propagation |
| **DB Migration** | Migrate up → schema check → migrate down (reversibility) → test with existing data | `migrate up`, `migrate down`, schema diff | Irreversible migrations; data loss on rollback; fails with non-empty tables |
| **Refactoring** | Existing tests pass unchanged → public API surface diff → behavioral spot-checks | Test suite, API diff tool | Tests modified to pass; public API silently changed; behavioral drift |

### The Universal Pattern

Regardless of change type, verification always follows:

1. **Exercise the change directly** — don't just read the code
2. **Check outputs against expectations** — compare actual vs expected
3. **Try to break it** — inputs and conditions the implementer didn't test

---

## Output Format Enforcement

Require structured evidence in verification reports. A check without executed commands is a skip, not a pass.

### Required Structure Per Check

```
### Check: [what you're verifying]
**Command run:**
  [exact command executed]
**Output observed:**
  [actual terminal output — copy-paste, not paraphrased]
**Result: PASS** (or FAIL — with Expected vs Actual)
```

### Bad Example (reject this)

```
### Check: POST /api/register validation
**Result: PASS**
Evidence: Reviewed the route handler in routes/auth.py. The logic 
correctly validates email format and password length.
```

Why rejected: No command was executed. Reading code is not verification.

### Good Example (accept this)

```
### Check: POST /api/register rejects short password
**Command run:**
  curl -s -X POST localhost:8000/api/register \
    -H 'Content-Type: application/json' \
    -d '{"email":"t@t.co","password":"short"}' | python3 -m json.tool
**Output observed:**
  {"error": "password must be at least 8 characters"}
  (HTTP 400)
**Expected vs Actual:** Expected 400 with password-length error. Got exactly that.
**Result: PASS**
```

### Verdict Rules

| Verdict | When to Use |
|---------|------------|
| **PASS** | All checks pass with evidence. At least one adversarial probe was run. |
| **FAIL** | Any check fails. Include Expected vs Actual for each failure. |
| **PARTIAL** | Environment limitations prevent full verification (no test framework, tools unavailable, server won't start). NOT for "unsure if this is a bug." |

### PASS Validation

Before accepting a PASS verdict, the auditor (main agent or human) must:
1. Confirm every PASS check has a `Command run` block with output
2. Re-run 2-3 commands from the report and verify output matches
3. If any PASS lacks evidence or outputs diverge, resume the verifier with specifics

---

## False Positive Defense (Before Issuing FAIL)

Not every anomaly is a bug. Before marking FAIL, check for three categories of "looks wrong but isn't":

### 1. Already Handled
The apparent vulnerability has defensive code elsewhere:
- Upstream validation catches the bad input before it reaches this code
- Downstream error recovery handles the failure gracefully
- A middleware/interceptor provides the missing check

**Action**: Search for the defense. If found, note it as context and continue testing other paths.

### 2. Intentional Behavior
The code comment, AGENTS.md, commit message, or design doc explains this is deliberate:
- A known limitation documented as acceptable
- A performance trade-off with documented justification
- Backward compatibility requiring specific behavior

**Action**: Cite the documentation. Do not FAIL on intentional, documented behavior.

### 3. Not Actionable
A real limitation that cannot be fixed:
- Stable API contracts that cannot change
- Protocol specifications requiring specific behavior
- Backward compatibility constraints

**Action**: Note as context. Do not FAIL on constraints outside the project's control.

**Critical guard**: These categories must not become excuses. If the issue is a real bug with real impact, FAIL it regardless of rationalizations. The categories exist to prevent false positives, not to suppress true findings.

---

## Progressive Rollout for Verification Systems

Deploy verification incrementally: internal dogfood first → power user opt-in → percentage rollout (5% → 25% → 50% → 100%) → default-on. Track false positive rate and verification time cost to validate the system itself.

---

## Adversarial Probe Seeds

Reusable probe categories to adapt per change type. Pick the ones that fit — these are seeds, not a complete checklist.

### Concurrency
For servers and APIs: send parallel requests to create-if-not-exists paths.
- Duplicate sessions?
- Lost writes?
- Race condition in resource creation?

### Boundary Values
- `0`, `-1`, empty string, very long string, Unicode (emoji, RTL), `MAX_INT`
- Null where non-null expected, array where object expected

### Idempotency
Send the same mutation twice:
- Created duplicates?
- Error on second attempt?
- Correct no-op?

### Orphan Operations
Reference non-existent resources:
- Delete a non-existent ID
- Update a deleted record
- Reference a foreign key that doesn't exist

---

## Verification Agent System Prompt Template

A production-ready template distilled from Claude Code's built-in verification agent. Copy, adapt, and embed in your verification system.

### Complete Template

```text
You are a verification specialist. Your job is not to confirm the implementation works — it is to try to break it.

=== YOUR FAILURE MODES (recognize and resist) ===

You will feel the urge to skip checks. These are the exact excuses you reach for — recognize them and do the opposite:

1. "The code looks correct based on my reading" — Reading is not verification. Run the code.
2. "The implementer's tests already pass" — The implementer is an LLM. Their tests may use circular assertions or excessive mocking. Verify independently.
3. "This is probably fine" — "Probably" is not "verified." Replace it with a command.
4. "Let me check the code to verify" — Checking code means reading it. Verification means executing it. Start the server. Hit the endpoint. Observe the output.
5. "I don't have the right tools" — Did you actually enumerate your available tools? Check before claiming inability.
6. "This would take too long" — Not your call. Run what you can. Report what you couldn't as PARTIAL with specific blockers.

You have two documented failure patterns:
1. Verification avoidance: when faced with a check, you find reasons not to run it — you read code, narrate what you would test, write "PASS," and move on.
2. Being seduced by the first 80%: you see a polished UI or a passing test suite and feel inclined to pass it, not noticing half the buttons do nothing or the backend crashes on bad input.

=== OUTPUT FORMAT (mandatory for every check) ===

### Check: [what you're verifying]
**Command run:**
  [exact command you executed]
**Output observed:**
  [actual terminal output — copy-paste, not paraphrased]
**Result: PASS** (or FAIL — with Expected vs Actual)

A check without a "Command run" block is not a PASS — it is a skip.

=== VERDICT PROTOCOL ===

End your report with exactly one of:
- VERDICT: PASS — All checks passed with command evidence. At least one adversarial probe was run.
- VERDICT: FAIL — Any check failed. Include Expected vs Actual for each failure.
- VERDICT: PARTIAL — Environment limitations prevent full verification. List specific blockers.

Rules:
- The implementer's own checks do NOT substitute for your verdict
- The implementer cannot self-assign PARTIAL or PASS — only you assign verdicts
- Every PASS check must have a Command run block with actual output
- Your report must include at least one adversarial probe (boundary value, concurrent request, missing resource, or similar)
- If all your checks are "returns 200" or "test suite passes," you have confirmed the happy path, not verified correctness

=== BEFORE REPORTING FAIL ===

Check you haven't missed why it's actually fine:
- Already handled: is there defensive code elsewhere?
- Intentional: does AGENTS.md / comments explain this as deliberate?
- Not actionable: is this a real limitation but unfixable?

=== CRITICAL: DO NOT MODIFY THE PROJECT ===

You are STRICTLY PROHIBITED from creating, modifying, or deleting any files in the project directory. You may write ephemeral test scripts to /tmp only. You must end with VERDICT: PASS, VERDICT: FAIL, or VERDICT: PARTIAL.
```

### Adaptation Notes

When adapting this template:

- Add project-specific context (tech stack, key endpoints, critical files) to the preamble
- Adjust the adversarial probe requirements based on change type (see Type-Specialized Verification Strategies above)
- For frontend changes, add: "Start the dev server. Open the browser. Click the buttons. Check the console."
- For API changes, add: "curl every endpoint. Try malformed input. Check error responses."

---

## Platform Implementation Guide

How to implement adversarial verification on the three major AI coding platforms.

### Claude Code

Claude Code has built-in verification agent support via `AgentTool`:

**Spawning the verifier:**

```
Spawn the AgentTool with subagent_type="verification". Pass:
- The original user request
- All files changed (by anyone)
- The approach taken
- The plan file path if applicable

Flag your concerns but do NOT share test results or claim things work.
```

**Permission isolation** (enforced at tool-routing level):

- Write tools (FileEdit, FileWrite, NotebookEdit) are removed from the verifier's available tool set
- Agent spawn tool is removed (prevents nested agents bypassing restrictions)
- BashTool is retained (needed for running verification commands)
- File read and search tools retained
- Browser/web tools retained if available
- Verifier can write to /tmp for ephemeral test scripts

**Anti-rationalization reinforcement:**

Use `criticalSystemReminder_EXPERIMENTAL` to reinforce constraints at message boundaries:

```
CRITICAL: This is a VERIFICATION-ONLY task. You CANNOT edit, write, or create 
files IN THE PROJECT DIRECTORY (tmp is allowed for ephemeral test scripts). 
You MUST end with VERDICT: PASS, VERDICT: FAIL, or VERDICT: PARTIAL.
```

**Trigger contract** (embed in main agent system prompt):

```
The contract: when non-trivial implementation happens on your turn, 
independent adversarial verification must happen before you report 
completion. Non-trivial means: 3+ file edits, backend/API changes, 
or infrastructure changes.
```

**Spot-check protocol:**

On PASS: re-run 2-3 commands from the verifier's report. Confirm every PASS has a Command run block with output that matches your re-run. If any PASS lacks a command block or diverges, resume the verifier with the specifics.

### Cursor

Cursor implements verification through the Task tool with readonly mode:

**Spawning the verifier:**

```
Use the Task tool with:
- subagent_type: "generalPurpose" (or a dedicated verification type if available)
- readonly: true  (restricts write operations)
- prompt: [verification agent system prompt template + task details]
```

**Permission isolation:**

- `readonly: true` restricts file modifications
- The verifier can still execute shell commands for testing
- Embed the "DO NOT MODIFY THE PROJECT" constraint in the prompt as defense-in-depth

**Structural nudge:**

After completing implementation, before reporting to the user, spawn a readonly verification task. Include in the task prompt:

- List of all files changed
- Description of what was implemented
- The full verification agent system prompt template

### Codex (OpenAI)

Codex uses sandbox isolation for verification:

**Spawning the verifier:**

- Use the agent-spawn mechanism to create a separate verification agent
- The sandbox environment provides natural isolation

**Permission isolation:**

- Codex agents run in sandboxed environments by default
- Configure the verification agent's sandbox to have read-only access to the project
- Allow network access for API testing

**Integration pattern:**

1. Implementation agent completes work and commits
2. Verification agent is spawned with read-only project access
3. Verification agent runs checks against the committed state
4. Results are reported back to the orchestrator

---

## End-to-End Example: API Feature Verification

A complete implement → verify → fix → re-verify cycle for a REST API endpoint.

### Scenario

Task: Add a `POST /api/users/register` endpoint with email validation and password hashing.

### Step 1: Implementation Complete

The implementer has:

- Created `src/routes/auth.ts` with the register endpoint
- Added `src/services/auth.ts` with password hashing
- Added `src/validators/user.ts` with email validation
- Written 3 unit tests (all passing)

Files changed: 4 (above non-trivial threshold of 3). Verification triggered.

### Step 2: Spawn Verifier

The main agent spawns a verification agent with:

- Read-only access to the project
- The system prompt template (above)
- Context: "Verify the new POST /api/users/register endpoint. Files changed: src/routes/auth.ts, src/services/auth.ts, src/validators/user.ts, src/tests/auth.test.ts"

### Step 3: Verifier Runs Checks

```text
### Check: Server starts without errors
**Command run:**
  cd /project && npm run dev &
  sleep 3
  curl -s http://localhost:3000/health
**Output observed:**
  {"status":"ok"}
**Result: PASS**

### Check: Register with valid data returns 201
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"SecurePass123!"}'
**Output observed:**
  {"id":"usr_abc123","email":"test@example.com"}
  201
**Result: PASS**

### Check: Register with short password returns 400
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test2@example.com","password":"short"}'
**Output observed:**
  {"error":"password must be at least 8 characters"}
  400
**Result: PASS**

### Check: Register with invalid email returns 400
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"not-an-email","password":"SecurePass123!"}'
**Output observed:**
  {"error":"invalid email format"}
  400
**Result: PASS**

### Check: [ADVERSARIAL] Duplicate registration
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com","password":"SecurePass123!"}'
**Output observed:**
  {"error":"Internal Server Error"}
  500
**Expected:** 409 Conflict with descriptive error message
**Result: FAIL** — Duplicate email causes unhandled database unique constraint error instead of a proper 409 response.

### Check: [ADVERSARIAL] SQL injection in email field
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@example.com\" OR 1=1--","password":"SecurePass123!"}'
**Output observed:**
  {"error":"invalid email format"}
  400
**Result: PASS** — Email validation catches the injection attempt.

VERDICT: FAIL
- 5 checks passed, 1 failed
- Duplicate registration returns 500 instead of 409
- Fix required: Add unique constraint error handling in src/routes/auth.ts
```

### Step 4: Fix and Re-verify

The implementer fixes the duplicate registration handling, then resumes the verifier:

"Fixed the duplicate registration issue. Added catch for unique constraint violation in src/routes/auth.ts, now returns 409. Please re-verify the failed check."

The verifier re-runs the failed check:

```text
### Check: [RE-VERIFY] Duplicate registration
**Command run:**
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"retest@example.com","password":"SecurePass123!"}'
  curl -s -w "\n%{http_code}" -X POST http://localhost:3000/api/users/register \
    -H "Content-Type: application/json" \
    -d '{"email":"retest@example.com","password":"SecurePass123!"}'
**Output observed:**
  {"id":"usr_def456","email":"retest@example.com"}
  201
  {"error":"email already registered"}
  409
**Result: PASS**

VERDICT: PASS
```

### Step 5: Spot-Check

The main agent re-runs the duplicate registration check from the verifier's report:

```text
Re-running: curl -s -w "\n%{http_code}" -X POST ... (duplicate email)
Output matches verifier's report: 409 with "email already registered"
Spot-check confirmed. ✓
```

