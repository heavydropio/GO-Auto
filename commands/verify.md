---
description: Run final verification and generate project report (Phase H). E2E tests + comprehensive analysis.
arguments:
  - name: phase
    description: Phase number or "all" for milestone verification
    required: true
---

# /go:verify [phase] — Final Verification & Report

You are the **Boss** running Phase H: Final Verification for Phase {{ phase }}.

## Purpose

1. Validate the system actually works end-to-end
2. Analyze build plans for patterns and insights
3. Generate comprehensive project report

## Part 1 & 2: Verification and Analysis

Spawn a Task agent with subagent_type "GO:Verifier" and pass it:
- Phase number: {{ phase }}
- Path to all PHASE_*_PLAN.md files
- Path to REQUIREMENTS.md (if exists)

The GO:Verifier agent knows its full role — it will run E2E tests, verify all "Done When" criteria, check requirements coverage, and produce FINAL_VERIFICATION.md and PROJECT_REPORT.md.

Wait for it to complete. If it returns ❌ ISSUES FOUND, the Boss must decide whether to address the issues or document them as known limitations.

## Part 3: Compile Final Report

Combine outputs into:
- `FINAL_VERIFICATION.md` — E2E test results
- `PROJECT_REPORT.md` — Comprehensive analysis

## Final Checklist

- [ ] E2E tests pass
- [ ] Primary user journey works
- [ ] All integration points verified
- [ ] Edge cases documented
- [ ] Skill usage report complete
- [ ] Issue tracking report complete
- [ ] Decision audit trail complete
- [ ] Metrics compiled
- [ ] Lessons learned documented

## Present to Human

```markdown
## Phase H Complete: Final Verification & Report

### Verification Status: ✅ VERIFIED / ❌ ISSUES FOUND

### E2E Test Results
- Primary journey: PASS/FAIL
- Integration points: [n]/[n] passing
- Edge cases: [n] tested

### Key Insights

**Skill Usage**:
- TDD applied [n]% of tasks
- Most skipped skill: [skill] ([n]% skip rate)
- Recommendation: [insight]

**Issues**:
- [n] fixed during build
- [n] deferred with tracking
- [n] orphaned (should be 0)

**Decisions**:
- [n] implementation decisions documented
- [key decision with highest future impact]

### Documents Created
- FINAL_VERIFICATION.md
- PROJECT_REPORT.md

### Milestone Status
Ready for release: YES/NO
```

## If Issues Found

Do not proceed to release. Address:
1. E2E failures (blocking)
2. Orphaned issues (must track or fix)
3. Missing test coverage

Re-run verification after fixes.
