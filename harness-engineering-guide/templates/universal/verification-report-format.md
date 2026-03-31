# Verification Report Format

Template for adversarial verification reports. Every check must include executed commands and observed output — reading code is not verification.

---

## Report Structure

```markdown
# Verification Report: [Task/Feature Description]

**Date**: [YYYY-MM-DD]
**Scope**: [files changed, feature area]
**Verifier constraints**: Read-only project access, temp-dir scripts allowed

## Environment Setup
**Command run:**
  [how the verification environment was prepared — build, server start, etc.]
**Output observed:**
  [build/startup output confirming environment is functional]

## Baseline Checks

### Check: Build succeeds
**Command run:**
  [build command]
**Output observed:**
  [build output]
**Result: PASS** / **FAIL**

### Check: Existing test suite passes
**Command run:**
  [test command]
**Output observed:**
  [test output — note: suite results are context, not evidence]
**Result: PASS** / **FAIL**

### Check: Linter/type-checker clean
**Command run:**
  [lint/type-check command]
**Output observed:**
  [output]
**Result: PASS** / **FAIL**

## Feature Verification

### Check: [specific behavior being verified]
**Command run:**
  [exact command executed]
**Output observed:**
  [actual terminal output — copy-paste, not paraphrased]
**Expected vs Actual:** [comparison]
**Result: PASS** / **FAIL**

## Adversarial Probes

### Check: [edge case / failure mode targeted]
**Command run:**
  [command that attempts to break the implementation]
**Output observed:**
  [actual output]
**Expected vs Actual:** [what should happen vs what did happen]
**Result: PASS** / **FAIL**

## Summary

| Category | Checks | Passed | Failed |
|----------|--------|--------|--------|
| Baseline | N | N | N |
| Feature | N | N | N |
| Adversarial | N | N | N |

VERDICT: PASS / FAIL / PARTIAL
[If PARTIAL: list what could not be verified and why]
[If FAIL: list all failures with Expected vs Actual]
```

---

## Examples

### Bad — Will Be Rejected

```markdown
### Check: POST /api/users creates a user
**Result: PASS**
Evidence: Reviewed the route handler in routes/users.py. The logic 
correctly validates input and inserts into the database.
```

**Why rejected**: No command was executed. "Reviewed the route handler" is reading, not verification.

```markdown
### Check: Authentication works
**Command run:**
  curl localhost:3000/api/auth/login
**Result: PASS**
```

**Why rejected**: No output shown. No expected-vs-actual comparison. "Works" is not a verifiable claim.

### Good — Accepted

```markdown
### Check: POST /api/users rejects duplicate email
**Command run:**
  curl -s -X POST localhost:3000/api/users \
    -H 'Content-Type: application/json' \
    -d '{"email":"test@example.com","name":"First"}' | jq .
  # Create first user (expected: 201)
  
  curl -s -X POST localhost:3000/api/users \
    -H 'Content-Type: application/json' \
    -d '{"email":"test@example.com","name":"Second"}' | jq .
  # Attempt duplicate (expected: 409)
**Output observed:**
  {"id": 1, "email": "test@example.com", "name": "First"}
  (HTTP 201)
  
  {"error": "Email already exists"}
  (HTTP 409)
**Expected vs Actual:** Expected 201 then 409 with duplicate error. Got exactly that.
**Result: PASS**
```

```markdown
### Check: Concurrent user creation doesn't produce duplicates
**Command run:**
  cat > /tmp/race_test.sh << 'EOF'
  for i in $(seq 1 10); do
    curl -s -X POST localhost:3000/api/users \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"race@test.com\",\"name\":\"User$i\"}" &
  done
  wait
  curl -s localhost:3000/api/users?email=race@test.com | jq length
  EOF
  bash /tmp/race_test.sh
**Output observed:**
  1
**Expected vs Actual:** Expected exactly 1 user with that email after 
concurrent creation attempts. Got 1. Concurrent requests properly serialized.
**Result: PASS**
```

---

## Verdict Definitions

| Verdict | Meaning | When to Use |
|---------|---------|-------------|
| **PASS** | All checks pass with command evidence. At least one adversarial probe included. | Implementation verified correct within tested scope. |
| **FAIL** | One or more checks failed. | Include Expected vs Actual for every failure. |
| **PARTIAL** | Some checks could not be executed due to environment constraints. | Missing tools, server won't start, no test framework. NOT for "unsure if bug." |

---

## Pre-PASS Checklist

Before writing VERDICT: PASS, confirm:

- [ ] Every check has a `Command run` block with an actual command
- [ ] Every check has `Output observed` with copy-pasted (not paraphrased) output
- [ ] At least one adversarial probe was run (not just happy-path verification)
- [ ] If you wrote an explanation instead of running a command anywhere, go back and run the command
- [ ] Build and test suite were run (broken build = automatic FAIL)

## Pre-FAIL Checklist

Before writing VERDICT: FAIL, confirm the finding is real:

- [ ] Not already handled elsewhere (upstream validation, downstream recovery)
- [ ] Not intentional behavior (documented in comments, AGENTS.md, design docs)
- [ ] Actionable (not a fixed API contract or protocol constraint)
- [ ] Reproducible (ran the failing command at least twice)
