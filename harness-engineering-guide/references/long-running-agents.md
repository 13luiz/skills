# Patterns for Long-Running Agent Tasks

## The Two Problems

Long-running agent tasks fail for two reasons:
1. **Context amnesia** — New sessions don't know what the previous one did
2. **Context overload** — Single sessions try too much, filling the context window until coherence degrades

## Anthropic's Multi-Agent Architecture

### Phase 1: Planning Agent (Initializer)
- Converts brief prompt into detailed specification
- Creates structured feature list in JSON
- Defines acceptance criteria per feature
- Writes initial project scaffold

### Phase 2: Generator Agent (Builder)
- Picks one feature at a time
- Implements completely before moving to next
- Runs verification after each feature
- Updates feature status in JSON tracker

### Phase 3: Evaluator Agent (Verifier)
- Separate from generator (no self-verification)
- Runs tests, type checks, E2E verification
- Provides specific, actionable feedback
- Grades against acceptance criteria

## Session Startup Protocol

Every new agent session begins with:

```
1. pwd                          # Confirm working directory
2. git log --oneline -10        # See recent commits
3. cat progress.json            # Read handoff state
4. Read feature tracker JSON    # Know what's done vs pending
5. Run dev server               # Verify environment works
6. Run basic health check       # E2E smoke test
7. Select highest-priority uncompleted feature
8. Begin work
```

Never start coding before verifying the environment is healthy.

## Memory Bridge Pattern

### Progress File (progress.json)
```json
{
  "last_session": "2026-03-31T10:00:00Z",
  "current_feature": "auth-login",
  "completed_features": ["project-setup", "database-schema"],
  "blocked_features": [],
  "environment_status": "healthy",
  "notes": "Login API endpoint works. Need frontend form next.",
  "next_steps": [
    "Create login form component",
    "Wire form to API endpoint",
    "Add error handling for invalid credentials"
  ]
}
```

### Feature Tracker (features.json)
```json
{
  "features": [
    {
      "id": "auth-login",
      "description": "User can log in with email and password",
      "priority": 1,
      "status": false,
      "e2e_verified": false,
      "assigned_session": null
    }
  ]
}
```

Rules:
- Agents may set `status: true` only after tests pass
- Agents may NOT delete features or modify descriptions
- `e2e_verified` requires browser-based verification

## Context Reset > Context Compaction

Anthropic's key finding: **clearing context entirely and starting fresh works better than compressing existing context.**

When a session's context is filling up:
1. Save state to progress file
2. Commit current work
3. Start a completely new session
4. New session reads progress file and git history
5. Resume from known good state

This works because:
- Compacted context loses nuance and introduces artifacts
- Fresh sessions have clean attention patterns
- File-based state is lossless (unlike summarization)

## Environment Health Checks

```bash
#!/bin/bash
echo "Checking environment health..."

npm install --frozen-lockfile || { echo "FAIL: Dependencies"; exit 1; }
npm run build || { echo "FAIL: Build"; exit 1; }
npm test || { echo "FAIL: Tests"; exit 1; }

timeout 10 npm run dev &
DEV_PID=$!
sleep 5
curl -s http://localhost:3000/health > /dev/null || { echo "FAIL: Dev server"; kill $DEV_PID; exit 1; }
kill $DEV_PID

echo "Environment healthy. Ready to work."
```

If any check fails, fix the environment first. Never build on broken foundations.

## Task Decomposition

### Good: One Feature Per Session
```
Session 1: Project scaffold and database schema
Session 2: User authentication
Session 3: Dashboard page
Session 4: Data export feature
```

### Bad: Everything At Once
```
Session 1: Build the entire app
```

Each session needs clear scope, defined start state, and measurable completion criteria.

## The Cleanup Rule

Every agent session must end with the codebase in a better or equal state:
- All tests passing
- No uncommitted changes
- Progress file updated
- Feature tracker updated
- Environment verified healthy

If a feature can't be completed:
1. Revert incomplete changes (or commit to WIP branch)
2. Document what was attempted and why it failed
3. Update progress file with next steps
4. Leave main branch clean
