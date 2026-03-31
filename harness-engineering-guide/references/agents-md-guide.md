# Writing Effective AGENTS.md / CLAUDE.md Files

Based on GitHub's analysis of 2,500+ repositories and OpenAI's internal practices.

## Core Principle

AGENTS.md is a **table of contents**, not an encyclopedia. Keep the root file under 60-100 lines. Detailed knowledge lives in `docs/` and is referenced by path.

AGENTS.md is now an open standard under the Agentic AI Foundation, supported by OpenAI Codex, Amp, Jules (Google), Cursor, and Factory. It is tool-agnostic and works across all major agent platforms.

## What to Include (6 Core Areas)

### 1. Commands (put these FIRST)
```markdown
## Commands
- Build: `npm run build`
- Test all: `npm test`
- Test single: `npm test -- --grep "test name"`
- Lint: `npm run lint -- --fix`
- Type check: `npx tsc --noEmit`
- Dev server: `npm run dev`
```
Include exact flags. Agents should be able to copy-paste and run.

### 2. Testing Conventions
```markdown
## Testing
- Tests live in `__tests__/` next to source files
- Use `describe/it` pattern with meaningful names
- Mock external services, never the database
- Run `npm test` before every commit
```

### 3. Project Structure
```markdown
## Structure
- `src/api/` -- API routes and handlers
- `src/services/` -- Business logic (no HTTP awareness)
- `src/repos/` -- Database access layer
- `src/types/` -- Shared TypeScript types
- See `docs/architecture.md` for dependency rules
```

### 4. Code Style
```markdown
## Style
- Follow existing patterns in the codebase
- Prefer composition over inheritance
- No barrel exports (index.ts re-exports)
- Error handling: use Result types, not try/catch for business logic
```

### 5. Git Workflow
```markdown
## Git
- Branch from `main`, PR back to `main`
- Commit messages: `type(scope): description` (conventional commits)
- One concern per PR -- do not bundle unrelated changes
- Squash merge only
```

### 6. Boundaries
```markdown
## Boundaries
### Always Do
- Run tests before committing
- Check types before pushing
- Read existing code before modifying

### Ask First
- Adding new dependencies
- Changing public API signatures
- Modifying CI configuration

### Never Do
- Delete or skip failing tests
- Commit secrets, tokens, or credentials
- Modify files outside your task scope
- Force push to main
```

## Progressive Disclosure Pattern

```
repo/
├── AGENTS.md          # ~60-100 lines, TOC + commands + boundaries
├── docs/
│   ├── architecture.md    # Dependency rules, module boundaries
│   ├── api-patterns.md    # How to write API endpoints
│   ├── testing-guide.md   # Testing conventions in detail
│   └── deployment.md      # Deploy process
└── src/
    ├── api/
    │   └── AGENTS.md      # API-specific conventions (20-40 lines)
    ├── services/
    │   └── AGENTS.md      # Service layer conventions
    └── database/
        └── AGENTS.md      # DB access patterns
```

OpenAI uses 88 AGENTS.md files in their repo — one per major subsystem — keeping instructions local and minimal.

## What NOT to Include

These waste tokens with no measurable benefit:
- Directory listings / file trees (agents can explore the filesystem)
- Codebase overviews (duplicates README)
- History or changelog
- Motivational statements
- Redundant information already available from code

## Critical Rules

1. **Human-written only.** LLM-generated AGENTS.md files consistently underperform human-written ones while costing 20%+ more tokens.
2. **Commands early, code examples over explanations.** The best AGENTS.md files from the GitHub analysis put executable commands first and use code examples rather than prose descriptions.
3. **Staleness is an active hazard.** If AGENTS.md says "auth logic is in src/auth/handlers.ts" and that file moves, the agent will confidently look in the wrong place. Describe capabilities and intent, not filesystem structure.

## Validation Checklist

- [ ] Under 100 lines at root level
- [ ] Commands section is first, with exact flags
- [ ] Three-tier boundaries defined (always/ask first/never)
- [ ] References docs/ for detailed knowledge
- [ ] Specifies tech stack with versions
- [ ] Written by a human, not generated
- [ ] Updated within the last 30 days
