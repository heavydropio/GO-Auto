---
description: Run code shortening and code review phases (E and F) on completed phase work.
arguments:
  - name: phase
    description: Phase number to review (e.g., 1, 2, 3)
    required: true
---

# /go:review [phase] — Code Shortening & Review

You are the **Boss** running Phases E (Shortening) and F (Code Review) for Phase {{ phase }}.

## Prerequisites

- Phase {{ phase }} execution complete (Phase D done)
- All smoke tests passing
- PHASE_{{ phase }}_PLAN.md has worker notes

## Phase E: Code Shortening

### Spawn Shortening Agents

Spawn a Task agent with subagent_type "GO:Refactor" for each major file or component that was built in Phase D. The GO:Refactor agent will reduce code without breaking tests and return ✂️ Shortening Notes.

### Collect Results

For each file shortened:
- Add ✂️ Shortening Notes to relevant task in plan
- Verify tests still pass

### After Shortening

Commit if changes made:
```bash
git add [files]
git commit -m "refactor(phase-{{ phase }}): shorten code without breaking tests"
```

## Phase F: Code Review

### Spawn Review Agents

Spawn these two agents in parallel:

1. Task agent with subagent_type "GO:Code Reviewer" — Reviews code quality, runs test suite, checks coverage
2. Task agent with subagent_type "GO:Security Reviewer" — Dedicated OWASP security audit, secrets scan, input validation

Both agents return their findings. BOTH must approve (✅) for Phase F to pass. If either returns ❌ BLOCKED, the Boss must address the findings before proceeding.

### Handle Review Findings

If issues found:
1. Spawn fix agent with issue details
2. Fix agent uses `systematic-debugging` skill
3. Fix must include test
4. Re-run review on fixed code

### After Review

Add to PHASE_{{ phase }}_PLAN.md:
- 🔍 Review Notes for each component
- Any ⚠️ Issue Fixed notes

```
Phase {{ phase }} review complete!
- Shortening: [n] files, [lines saved] lines reduced
- Review: [n] components, all APPROVED

Next: Run /go:status {{ phase }} to finalize
```
