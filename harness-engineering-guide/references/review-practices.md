# Code Review Practices for AI-Generated Code

## Why AI Code Needs Different Review

AI-generated code has specific failure modes traditional review doesn't catch:
- **Hallucinated APIs** — calls to functions or libraries that don't exist
- **Deleted tests** — removing failing tests instead of fixing code
- **Over-abstraction** — unnecessary wrappers, factories, and indirection
- **Pattern replication** — copying suboptimal patterns from elsewhere in the codebase
- **Architectural erosion** — gradually violating module boundaries through convenience imports

## Two-Tier Review Process

### Tier 1: Agent Invoker Review
The person who prompted the agent reviews first:
- Does output match intent?
- Obvious hallucinations or nonsensical code?
- Did agent solve the actual problem or just the prompt?
- Prompt agent to fix issues before Tier 2

### Tier 2: Independent Review
A different reviewer examines finalized changes:
- Architectural fit
- Data flow tracing (input to output)
- Edge case coverage
- Dependency implications
- Security considerations

## AI-Specific Review Checklist

Use in PR templates:

```markdown
## AI Code Review Checklist
- [ ] No hallucinated APIs (all imports resolve to real packages)
- [ ] No deleted or skipped tests
- [ ] Architectural boundaries respected (no cross-layer imports)
- [ ] No unnecessary abstractions
- [ ] No duplicate implementations (uses existing shared utilities)
- [ ] Error handling is proportionate
- [ ] Data flow traced from input to output
- [ ] No secrets, tokens, or credentials in code
- [ ] PR is appropriately sized (one concern, <500 additions)
```

## Agent-to-Agent Review (Adversarial Pattern)

For high-throughput teams:

1. **Coding agent** writes implementation (no knowledge of review criteria)
2. **Review agent** examines output (read-only, cannot modify)
3. **Optional: Red team agent** targets edge cases and failure modes

Rules:
- Coding agent has no knowledge of what review agent checks
- Review agent must cite evidence from the diff
- Findings without evidence are low confidence
- Cap at 8 findings per PR — prioritize ruthlessly

## Three-Party Verification Chain

For high-stakes changes (3+ files, backend/API, infrastructure), use the three-party chain: Implementer → Verifier (read-only, adversarial) → Auditor (spot-checks verifier's report). See `references/adversarial-verification.md` for the complete pattern including permission isolation, anti-rationalization engineering, structured output format, and type-specialized verification strategies.

## Spec-Driven Review

At scale, shift human review from code to specs:

1. Human reviews and approves the **spec** (what to build, constraints, criteria)
2. Agent generates code against the spec
3. Mechanical verification (tests, types, lint) validates output
4. Human spot-checks but trusts mechanical gates

Shifts the question from "did you write this correctly?" to "are we solving the right problem?"

## What to Focus On

### High Value (always check)
- Does it solve the actual business problem?
- Security implications?
- Will this break existing functionality?
- Architecture preserved?

### Medium Value (larger PRs)
- Could this be simpler?
- Missing edge cases?
- Error handling appropriate?

### Low Value (trust the linter)
- Formatting and style
- Naming conventions
- Import ordering

## Review Metrics

| Metric | What It Tells You |
|--------|------------------|
| Rework rate | How often AI PRs need revision |
| Review time | Whether AI PRs are faster or slower to review |
| Finding categories | What issues recur |
| False positive rate | Whether review catches real issues or nitpicks |
