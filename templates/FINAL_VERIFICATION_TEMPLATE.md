# Final Verification Report

**Project**: [Project Name]
**Milestone**: v[version]
**Date**: YYYY-MM-DD
**Prepared by**: Boss (Phase H)

> **Scope**: This report answers "Does it work?" through technical verification. It does NOT replace VALIDATION_PHASE (the CLOSE/EXTEND/PIVOT decision gate), which answers "Should we ship?" through real-world gap analysis.

---

## Part 1: End-to-End Validation

### Primary User Journey

**Journey**: [Description of the main thing a user does]

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | [Action] | [Expected result] | [Actual result] | ✅/❌ |
| 2 | [Action] | [Expected result] | [Actual result] | ✅/❌ |
| 3 | [Action] | [Expected result] | [Actual result] | ✅/❌ |
| 4 | [Action] | [Expected result] | [Actual result] | ✅/❌ |

**Result**: ✅ PASS / ❌ FAIL

### Integration Points Tested

| From Phase | To Phase | Data Flow | Test | Status |
|------------|----------|-----------|------|--------|
| 1 ([name]) | 2 ([name]) | [what flows] | [test name] | ✅/❌ |
| 2 ([name]) | 3 ([name]) | [what flows] | [test name] | ✅/❌ |

### Edge Cases

| Scenario | Expected | Actual | Status |
|----------|----------|--------|--------|
| Empty input | [behavior] | [behavior] | ✅/❌ |
| Malformed data | [behavior] | [behavior] | ✅/❌ |
| Large dataset | [behavior] | [behavior] | ✅/❌ |
| Concurrent access | [behavior] | [behavior] | ✅/❌ |

### Smoke Test Log

```bash
# Commands run and their output
$ [command 1]
[output]

$ [command 2]
[output]
```

---

## Part 2: Test Suite Results

### Summary

| Category | Count | Passed | Failed | Skipped |
|----------|-------|--------|--------|---------|
| Unit tests | [n] | [n] | [n] | [n] |
| Integration tests | [n] | [n] | [n] | [n] |
| E2E tests | [n] | [n] | [n] | [n] |
| **Total** | **[n]** | **[n]** | **[n]** | **[n]** |

### Test Run Output

```bash
$ uv run pytest tests/ -v
[output summary]
```

### Coverage Report

| Module | Coverage | Target | Status |
|--------|----------|--------|--------|
| `src/module1` | [n]% | 80% | ✅/❌ |
| `src/module2` | [n]% | 80% | ✅/❌ |
| **Overall** | **[n]%** | **80%** | ✅/❌ |

---

## Part 3: Requirements Verification

[If using requirements traceability]

| REQ-ID | Description | Phase | Verified | Evidence |
|--------|-------------|-------|----------|----------|
| [ID] | [description] | [N] | ✅/❌ | [test or demo] |
| [ID] | [description] | [N] | ✅/❌ | [test or demo] |

**Requirements Met**: [n] / [total] ([percentage]%)

---

## Part 4: Verification Checklist

### Functionality
- [ ] All success criteria from each phase met
- [ ] Primary user journey works end-to-end
- [ ] All integration points functional
- [ ] Edge cases handled appropriately

### Quality
- [ ] All tests pass
- [ ] Coverage meets target (80%+)
- [ ] No security vulnerabilities identified
- [ ] Code review complete for all phases

### Documentation
- [ ] HANDOFF.md current
- [ ] All PHASE_X_PLAN.md have agent notes
- [ ] API documentation accurate (if applicable)

### Operations
- [ ] Build process documented
- [ ] Dependencies pinned
- [ ] Environment requirements clear

### Bead Tracking
- [ ] All AS-NNN assumptions have status (Validated/Accepted/Open)
- [ ] All blocking OQ-NNN questions resolved or explicitly deferred
- [ ] No Falsified assumptions without remediation

---

## Part 5: Bead Status Audit

Verify that all tracked assumptions and open questions have appropriate resolution before claiming the build works.

### Assumptions (AS-NNN)

Query: `rg "AS-[0-9]+" HANDOFF.md | grep -v "Validated\|Accepted"`

| ID | Assumption | Status | Action Required |
|----|------------|--------|-----------------|
| AS-NNN | [text] | Open/Validated/Accepted/Falsified | [None / Must address before ship] |

**Status key:**
- **Validated**: Evidence proves assumption correct
- **Accepted**: Stakeholder accepts risk without validation
- **Falsified**: Proven wrong (requires remediation)
- **Open**: Unresolved (flag for VALIDATION_PHASE decision)

### Open Questions (OQ-NNN)

Query: `rg "OQ-[0-9]+" HANDOFF.md | grep "Yes" | grep -v "Resolved"`

| ID | Question | Blocking? | Resolution |
|----|----------|-----------|------------|
| OQ-NNN | [text] | Yes/No | Resolved/Deferred to v[X] |

**Audit Result**: ✅ All beads addressed / ⚠️ [N] items flagged for VALIDATION_PHASE

---

## Verification Result

### Status: ✅ VERIFIED / ❌ ISSUES FOUND

[If verified]:
> All end-to-end tests pass. Primary user journey works. All [n] tests pass with [n]% coverage. Ready for release.

[If issues found]:
> Issues identified that must be resolved before release:
> 1. [Issue 1]
> 2. [Issue 2]

---

## Sign-Off

| Role | Name | Date | Approval |
|------|------|------|----------|
| Boss | Claude | YYYY-MM-DD | ✅ |
| Human | [name] | YYYY-MM-DD | ⏳ Pending |
