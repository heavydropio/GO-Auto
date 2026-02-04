# Issue Resolution Protocol

When an issue is discovered during any phase:

## Step 1: EVALUATE

Is this fixable now without blocking the critical path?
- **YES** → Proceed to Step 2 (Fix)
- **NO** → Skip to Step 3 (Deferral)

## Step 2: FIX AND VERIFY

1. Spawn fix agent with specific issue context
2. Fix agent MUST:
   - Implement the fix
   - Write a test that would have caught this issue
   - Run the test (confirm it passes)
   - Run regression tests (confirm no breakage)

3. Document in PHASE_X_PLAN.md under the relevant task:

```markdown
#### ⚠️ Issue Fixed (agent-id, YYYY-MM-DD HH:MM)
> **Issue**: [What broke or was wrong]
> **Root Cause**: [Why it happened]
> **Fix**: [What was changed, which file/line]
> **Test Added**: [test_name() in test_file.py]
> **Verified**: Test passes, no regression in existing tests
```

4. Continue execution only after fix is verified

## Step 3: JUSTIFY DEFERRAL

If Step 1 = NO, Boss MUST document ALL of:

```markdown
#### ⚠️ Issue Deferred (Boss, YYYY-MM-DD HH:MM)
> **Issue**: [Description]
> **Why Can't Fix Now**: [Specific technical reason — NOT "non-blocking"]
> **Assigned Phase**: Phase [N] (specific number)
> **What Breaks If Never Fixed**: [Concrete consequence]
> **Test To Write When Fixed**: [Describe the test that should exist]
```

## Step 4: CREATE TRACKING

For deferred issues:
```bash
bd create --title="[DEFERRED] Issue description" --type=bug -p 1
bd dep add <new-issue-id> <phase-that-must-fix>
```

Add to Issues Log at end of PHASE_X_PLAN.md:

| ID | Description | Blocking? | Owner | Bead | Status |
|----|-------------|-----------|-------|------|--------|
| ISS-001 | [description] | No | Phase N | bd-xxxx | Tracked |

## Step 5: PHASE-END VERIFICATION

Before Phase G, Boss reviews ALL issues:

1. **Fixed issues**: Verify test exists and passes
2. **Deferred issues**: Verify:
   - Bead exists (`bd show <id>`)
   - Owner phase is specified
   - Justification is substantive (not "non-blocking")
3. **Orphan check**: Every issue has either:
   - Fix + test, OR
   - Bead + owner

**No orphan issues allowed in handoff.**

## Valid Deferral Reasons

| Valid | Invalid |
|-------|---------|
| "Requires Phase 5 infrastructure (not built yet)" | "Non-blocking" |
| "Needs API that Phase 7 creates" | "Can do later" |
| "Database migration in Phase 6 will address" | "Low priority" |
| "Out of scope for this milestone" | "Didn't have time" |

## Rule

**"Non-blocking" is NOT a valid justification.**

Only "technically impossible to fix in this phase" qualifies for deferral.

When in doubt: **FIX IT NOW.**
