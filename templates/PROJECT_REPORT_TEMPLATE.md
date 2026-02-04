# Project Report: [Project Name] v[version]

**Date**: YYYY-MM-DD
**Milestone**: v[version]
**Phases Completed**: [N]

> **Document Type**: Final aggregation of progressive handoffs. This report summarizes beads and decisions tracked in HANDOFF.md and HANDOFF_PHASE_N.md files. Reference sources rather than duplicating content.

---

## For the Next Agent

### Orientation

Before diving in, read these documents in order:
1. `CLAUDE.md` - Project identity and constraints
2. `ROADMAP.md` - Phase structure and goals
3. `HANDOFF.md` - Full handoff history with Design Decisions, Open Questions, Assumptions, Discoveries, and Pivots
4. This report - Aggregated summary and what remains

### Key Constraints

- [Constraint 1 - e.g., "All changes require tests"]
- [Constraint 2 - e.g., "No breaking changes to public API"]
- [Constraint 3]

### Unresolved Open Questions

Questions from HANDOFF.md that remain unresolved. Investigate or escalate.

| ID | Question | Blocking? | Source |
|----|----------|-----------|--------|
| OQ-NNN | [Question text] | Yes/No | HANDOFF.md |

### Unvalidated Assumptions

Assumptions from HANDOFF.md that were never validated. Verify or falsify.

| ID | Assumption | Risk if Wrong | Source |
|----|------------|---------------|--------|
| AS-NNN | [Assumption text] | [Risk] | HANDOFF.md |

### Recommended First Action

[What should the next agent do first? e.g., "Run `pytest tests/` to verify everything passes, then review TD-001 in Technical Debt section."]

---

## Executive Summary

[3-5 sentences: What was built, key achievements, overall health]

---

## Completion Metrics

### Planned vs Actual

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Phases | [n] | [n] | [+/-n] |
| Tasks | [n] | [n] | [+/-n] |
| Requirements (v1) | [n] | [n] | [+/-n] |
| Tests | [n]+ | [n] | [+/-n] |

### Quality Metrics

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total tests | [n] | [n]+ | ✅/❌ |
| Test coverage | [n]% | 80% | ✅/❌ |
| Issues fixed | [n] | — | — |
| Issues deferred | [n] | — | — |

### Code Impact

| Metric | Value |
|--------|-------|
| Files created | [n] |
| Files modified | [n] |
| Lines added | [n] |
| Lines removed | [n] |
| Net change | [+/-n] |

---

## Phase Summary

| Phase | Tasks | Tests Added | Duration | Key Deliverable |
|-------|-------|-------------|----------|-----------------|
| 1 | [n] | [n] | [waves] | [deliverable] |
| 2 | [n] | [n] | [waves] | [deliverable] |
| ... | ... | ... | ... | ... |

---

## Skill Usage Analysis

### Summary

| Skill | Applied | Skipped | Skip Rate |
|-------|---------|---------|-----------|
| test-driven-development | [n] | [n] | [n]% |
| verification-before-completion | [n] | [n] | [n]% |
| systematic-debugging | [n] | [n] | [n]% |
| brainstorming | [n] | [n] | [n]% |
| writing-plans | [n] | [n] | [n]% |

### Skip Justification Quality

| Skill | Good Justifications | Weak Justifications | Notes |
|-------|---------------------|---------------------|-------|
| TDD | [n] | [n] | [observations] |
| brainstorming | [n] | [n] | [observations] |

### Recommendations

- [Recommendation 1 based on patterns]
- [Recommendation 2 based on patterns]

---

## Issue Tracking Analysis

### Resolution Summary

| Category | Count | Percentage |
|----------|-------|------------|
| Fixed immediately | [n] | [n]% |
| Fixed with test added | [n] | [n]% of fixes |
| Deferred (with Bead) | [n] | [n]% |
| Deferred (no tracking) | [n] | [n]% |
| Orphaned | [n] | [n]% |

### Issue Discovery by Phase

| Phase | Found | Fixed | Deferred |
|-------|-------|-------|----------|
| 1 | [n] | [n] | [n] |
| 2 | [n] | [n] | [n] |
| ... | ... | ... | ... |

### Deferred Issues Status

| Issue | Description | Assigned | Bead | Priority |
|-------|-------------|----------|------|----------|
| ISS-[n] | [description] | Phase [N] | bd-xxxx | P[n] |

### Pattern Analysis

- [Pattern 1: e.g., "Most issues found in Phase 3 (integration complexity)"]
- [Pattern 2: e.g., "All fixes include tests (protocol followed)"]

---

## Decision Audit Trail

### Key Decisions Made

| Phase | Task | Decision | Rationale | Made By |
|-------|------|----------|-----------|---------|
| [N] | [task] | [decision] | [why] | [agent] |
| [N] | [task] | [decision] | [why] | [agent] |

### Decisions with Future Impact

| Decision | Phase | Potential Impact | Mitigation |
|----------|-------|------------------|------------|
| [decision] | [N] | [impact] | [mitigation] |

---

## Git Health

| Metric | Value | Target | Status |
|--------|-------|--------|--------|
| Total commits | [n] | — | — |
| Per-wave commits | [n] | — | — |
| Conventional format | [n]% | 100% | ✅/❌ |
| Force pushes | [n] | 0 | ✅/❌ |

### Commit Distribution

| Phase | Commits | Pattern |
|-------|---------|---------|
| 1 | [n] | [pattern notes] |
| 2 | [n] | [pattern notes] |

---

## Velocity Analysis

| Phase | Tasks | Waves | Parallelization | Notes |
|-------|-------|-------|-----------------|-------|
| 1 | [n] | [n] | [max parallel] | [notes] |
| 2 | [n] | [n] | [max parallel] | [notes] |

### Bottlenecks Identified

- [Bottleneck 1]
- [Bottleneck 2]

---

## Lessons Learned

### What Worked Well

1. [Success 1]
2. [Success 2]
3. [Success 3]

### What Could Improve

1. [Improvement 1]
2. [Improvement 2]
3. [Improvement 3]

### Recommendations for Next Project

1. [Recommendation 1]
2. [Recommendation 2]
3. [Recommendation 3]

---

## Outstanding Items

### Deferred Issues (Require Future Phases)

| Issue | Owner | Bead | ETA |
|-------|-------|------|-----|
| [description] | Phase [N] | bd-xxxx | v[version] |

### Technical Debt

| Item | Severity | Recommendation |
|------|----------|----------------|
| [item] | Low/Med/High | [action] |

### Future Enhancements (Out of Scope)

| Enhancement | Value | Effort |
|-------------|-------|--------|
| [enhancement] | High/Med/Low | High/Med/Low |

---

## Appendix: Phase Reports

[Links or references to individual PHASE_X_PLAN.md files]

- Phase 1: `PHASE_1_PLAN.md`
- Phase 2: `PHASE_2_PLAN.md`
- ...

---

## Sign-Off

| Role | Status | Date |
|------|--------|------|
| Build Complete | ✅ | YYYY-MM-DD |
| Tests Passing | ✅ | YYYY-MM-DD |
| Documentation Current | ✅ | YYYY-MM-DD |
| Ready for Release | ✅/⏳ | YYYY-MM-DD |
