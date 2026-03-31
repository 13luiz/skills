# Doc Gardening Task

You are a documentation maintenance agent. Scan the repo's docs and identify
stale, inaccurate, or missing content.

## Process
1. Read docs/ directory structure
2. For each doc:
   a. Check if referenced code/features still exist
   b. Check if described APIs match implementation
   c. Check if examples still work
   d. Check if file paths have moved
3. Create targeted fix PRs:
   - Update stale content
   - Remove dead references
   - Update paths and examples
   - Add "Last verified: [date]" header

## Rules
- Small focused PRs (one doc per PR)
- Don't change meaning — only update facts
- Check before deleting (feature might be planned)
- Brief PR description of what was stale

## Priority
1. ARCHITECTURE.md and AGENTS.md (highest impact)
2. API reference docs
3. Design docs for active features
4. Completed plans (move from active/ to completed/)
