# Phase [N]: Validation

## Purpose

Test the system on real work, identify gaps, and make an explicit decision about project completion. This phase produces a decision gate that determines whether to close, extend, or pivot.

**This phase is mandatory** - every roadmap should end with validation before declaring completion.

---

## Context

- **Previous Phase**: [Phase N-1 name and what it delivered]
- **System Under Test**: [What capabilities are being validated]
- **Decision Authority**: [Who approves the final decision - human/autonomous]

---

## Deliverables

1. **Real-world test execution** - Not unit tests, but actual usage scenarios
2. **GAP_ANALYSIS.md** - Categorized list of what's missing or broken
3. **DECISION.md** - Explicit verdict with rationale

---

## Validation Tests

Define what to test. Each test should exercise real functionality, not mocked scenarios.

### Test 1: [Name]

**Scenario**: [Describe the real-world scenario being tested]

**Steps**:
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Outcome**: [What success looks like]

**Metrics to Capture**:
- [Metric 1 - e.g., "Time to complete"]
- [Metric 2 - e.g., "Error rate"]

---

### Test 2: [Name]

**Scenario**: [Description]

**Steps**:
1. [Step]

**Expected Outcome**: [Success criteria]

**Metrics to Capture**:
- [Metric]

---

### Test 3: [Name]

[Repeat pattern as needed]

---

## Gap Analysis Template

After running validation tests, categorize findings using this structure.

### Content Gaps
What's missing from the implementation?

| Gap | Description | Severity | Evidence |
|-----|-------------|----------|----------|
| [ID] | [What's missing] | P1/P2/P3/P4 | [Test that revealed it] |

### Process Gaps
What's missing from workflows or procedures?

| Gap | Description | Severity | Evidence |
|-----|-------------|----------|----------|

### Tooling Gaps
What's missing from CLI, APIs, or developer experience?

| Gap | Description | Severity | Evidence |
|-----|-------------|----------|----------|

### Documentation Gaps
What's missing from guides, references, or examples?

| Gap | Description | Severity | Evidence |
|-----|-------------|----------|----------|

### Integration Gaps
What doesn't work well with other systems?

| Gap | Description | Severity | Evidence |
|-----|-------------|----------|----------|

### Severity Definitions

- **P1 (Blocking)**: System unusable for primary use case. Must fix before close.
- **P2 (High)**: Significant functionality missing. Should address in next milestone.
- **P3 (Medium)**: Inconvenient but workable. Track as technical debt.
- **P4 (Low)**: Nice to have. Add to backlog.

---

## Decision Gate

The validation phase MUST produce one of three verdicts:

### CLOSE
**Criteria**: All P1 gaps addressed. P2 gaps are documented and acceptable for MVP. Primary use case validated.

**Actions**:
- Bump version to release version
- Create git tag
- Archive phase documents
- Generate final project report
- Mark project complete

### EXTEND
**Criteria**: P1 or critical P2 gaps remain that are addressable in defined scope.

**Actions**:
- Document Phase N+1 scope (must be bounded)
- Create new phase plan
- Continue development
- Re-run validation after Phase N+1

### PIVOT
**Criteria**: Fundamental issues discovered that require architectural changes, scope redefinition, or stakeholder reconsideration.

**Actions**:
- Document what's broken and why
- Escalate to human stakeholder
- Create new project brief if continuing
- Archive current work as reference

---

## Decision Document Template

Create `DECISION.md` with this structure:

```markdown
# Validation Decision

## Verdict: [CLOSE / EXTEND / PIVOT]

## Date: [YYYY-MM-DD]

## Summary

[1-2 paragraphs explaining the decision]

## Validation Results

| Test | Status | Notes |
|------|--------|-------|
| [Test 1] | Pass/Fail | [Brief note] |
| [Test 2] | Pass/Fail | |

## Gap Summary

| Severity | Count | Blocking? |
|----------|-------|-----------|
| P1 | [N] | [Yes/No] |
| P2 | [N] | - |
| P3 | [N] | - |
| P4 | [N] | - |

## Rationale

[Why this verdict? What evidence supports it?]

## If EXTEND: Phase N+1 Scope

**Goal**: [What Phase N+1 will achieve]

**Tasks**:
1. [Task 1 - addresses Gap X]
2. [Task 2 - addresses Gap Y]

**NOT in scope**: [What is explicitly excluded to keep scope bounded]

**Exit Criteria**: [When Phase N+1 is done]

## If PIVOT: What Needs to Change

**Fundamental Issue**: [What's broken at the architecture/scope level]

**Options**:
1. [Option A]
2. [Option B]

**Recommended Path**: [Which option and why]

**Human Decision Required**: [Yes/No - what they need to decide]

## If CLOSE: Final Actions

- [ ] Version: [X.Y.Z]
- [ ] Tag created: [Yes/No]
- [ ] Final report: [Link]
- [ ] Archive location: [Path]
```

---

## Decision Execution

**IMPORTANT**: The decision gate produces documents, not immediate action.

### If CLOSE

- Create final PROJECT_REPORT.md from template
- Update HANDOFF.md with final phase summary
- Tag release version: `git tag vX.Y.Z`
- Session ends

### If EXTEND

- Create RESTART_PROMPT_PHASE_[N+1].md with scope from DECISION.md
- Update ROADMAP.md with new phase
- Update HANDOFF.md with validation phase summary
- Session ends
- New session starts fresh with restart prompt

### If PIVOT

- Document pivot rationale in DECISION.md
- Escalate to human stakeholder
- Create pivot summary in HANDOFF.md
- Session ends
- Human decides next steps

### Why Not Continue Immediately?

Phases exist because context windows fill up. The decision gate is a natural break point.

**Problems with continuing:**
1. Context window may already be at 70-85% after validation work
2. Fresh session gets clean context for Phase N+1
3. RESTART_PROMPT ensures Agent B has proper orientation
4. Separation prevents "sunk cost" bias from affecting Phase N+1 scope

**The pattern:**
```
Session 1: Phases 1-3 + validation
  -> Validation says EXTEND
  -> Creates RESTART_PROMPT_PHASE_4.md
  -> Session ends

Session 2: Reads RESTART_PROMPT_PHASE_4.md
  -> Phases 4-5 + validation
  -> Validation says CLOSE
  -> Creates PROJECT_REPORT.md
  -> Session ends
```

---

## Execution Checklist

Use this checklist to run the validation phase:

- [ ] All previous phases marked Complete
- [ ] Validation tests defined (at least 3 real-world scenarios)
- [ ] Tests executed and results documented
- [ ] GAP_ANALYSIS.md created with all gaps categorized
- [ ] Each gap has severity assigned
- [ ] DECISION.md created with explicit verdict
- [ ] If EXTEND: Phase N+1 plan created
- [ ] If PIVOT: Human stakeholder notified
- [ ] If CLOSE: Final report generated

---

## Example: Engram Handshake Phase 6 Validation

For reference, here's how the Engram Handshake project ran validation:

**Tests**:
1. Simulated A/B handoff on real feature work (adding `handoff list` command)
2. Measured Agent B orientation time (target: <2 min, actual: ~0 min)
3. Tracked tacit message usage in implementation

**Gaps Found**:
- P3: Atomic operations for handoff+state (TD-001)
- P2: CLI commands incomplete (led to Phase 7 extension)
- P4: Multi-session testing infrastructure

**Decision**: EXTEND - Added Phase 7 to complete CLI tooling

**Phase 7 Scope**: Add `list` and `show` commands, `validate_handoff_content()` function
