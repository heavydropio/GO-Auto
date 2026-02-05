# HANDOFF.md (Autonomous Mode)

Simplified handoff document for GO-Auto. Focuses on decision tracking (Beads) and essential build state. Does NOT include session-restart prompts or phase-by-phase narrative summaries.

---

## Template

```markdown
# HANDOFF.md

## Build Info

| Field | Value |
|-------|-------|
| Project | {{ project_name }} |
| Started | {{ timestamp }} |
| Mode | Autonomous (GO-Auto) |
| Phases Planned | {{ total_phases }} |
| Current Phase | {{ current_phase }} |
| Status | {{ in_progress | completed | aborted }} |

---

## Beads Log

Track all significant decisions, discoveries, assumptions, friction points, and pivots.

| ID | Type | Summary | Phase | Status |
|----|------|---------|-------|--------|
| DD-001 | Decision | {{ decision summary }} | {{ N }} | Active |
| DS-001 | Discovery | {{ discovery summary }} | {{ N }} | Active |
| AS-001 | Assumption | {{ assumption summary }} | {{ N }} | Open |
| FR-001 | Friction | {{ friction summary }} | {{ N }} | Resolved |
| PV-001 | Pivot | {{ pivot summary }} | {{ N }} | Active |

### Bead Types

- **DD (Decision)**: Architectural or design choice with rationale
- **DS (Discovery)**: Non-obvious learning about codebase/domain/tools
- **AS (Assumption)**: Unvalidated bet that could be wrong
- **FR (Friction)**: Something harder than expected with root cause
- **PV (Pivot)**: Direction change from original plan

### Bead Status

- **Active**: Current, applies to ongoing work
- **Open**: Unvalidated (for assumptions)
- **Validated**: Confirmed correct (for assumptions)
- **Resolved**: Issue addressed (for friction)
- **Superseded**: Replaced by newer decision

---

## UI Impact Log

Changes during build phases that affect UI screens. Auto-populated by ui-impact-detection hook.

| ID | Type | Summary | Details | Screens Affected | Bead |
|----|------|---------|---------|------------------|------|
| UI-001 | entity_change | {{ field/entity change }} | {{ what UI needs }} | {{ screen_id, screen_id }} | UI-DS-NNN |

**Impact Types**: entity_change, new_endpoint, api_shape_change, enum_change, workflow_change

**When entries are added**:
- Entity field added/removed/changed that appears in UI
- New API endpoint that UI will consume
- Response shape change affecting data bindings
- Enum value added/removed affecting dropdowns or badges
- Workflow step change affecting wizard or multi-step UI

**UI Phase**: After all build phases, run `/go-auto:ui` to generate screens based on this log.

---

## Deferred Issues

Issues that couldn't be fixed in the current phase.

| ID | Issue | Reason Deferred | Assigned Phase | What Breaks If Not Fixed |
|----|-------|-----------------|----------------|--------------------------|
| DEF-001 | {{ issue }} | {{ reason }} | {{ phase N }} | {{ consequence }} |

**Rule**: "Non-blocking" is NOT a valid reason. Must specify technical reason.

---

## Auto-Retry Summary

Track autonomous recovery attempts.

| Phase | Task | Attempts | Outcome |
|-------|------|----------|---------|
| {{ N }} | {{ task_id }} | {{ count }} | {{ recovered | aborted }} |

---

## Git Log

| Phase | Commit | Tag | Message |
|-------|--------|-----|---------|
| 1 | {{ hash }} | v{{ version }}-phase-1 | {{ message }} |
| 2 | {{ hash }} | v{{ version }}-phase-2 | {{ message }} |

---

## Phase Completion Status

| Phase | Status | Tasks | Tests | Duration |
|-------|--------|-------|-------|----------|
| 1 | {{ complete | in_progress | aborted }} | {{ N }} | {{ N }} | {{ time }} |
| 2 | {{ complete | in_progress | aborted }} | {{ N }} | {{ N }} | {{ time }} |

---

## Final Status

**Completed**: {{ timestamp }} or **Aborted**: {{ timestamp }}

**Outcome**: {{ VERIFIED | ISSUES_FOUND | ABORTED }}

**Next Steps**:
{{ if completed: Review FINAL_VERIFICATION.md and PROJECT_REPORT.md }}
{{ if aborted: See abort section in PHASE_N_PLAN.md for recovery options }}
```

---

## What's NOT in Autonomous HANDOFF.md

Unlike GO-Build's full HANDOFF.md, this version omits:

1. ~~Session-specific context~~ — No session breaks in autonomous mode
2. ~~RESTART_PROMPT references~~ — Not created
3. ~~Phase narrative summaries~~ — Detailed execution is in PHASE_N_PLAN.md
4. ~~Preflight notes cascade~~ — Single session, no future human warnings
5. ~~Human-oriented explanations~~ — Data-focused, not narrative

---

## When to Update

| Event | Action |
|-------|--------|
| Phase completes | Add beads, update git log, update phase status |
| Assumption validated | Update bead status |
| Issue deferred | Add to deferred issues table |
| Auto-retry occurs | Add to auto-retry summary |
| Build completes | Set final status |
| Build aborts | Set final status with abort info |

---

## Usage Notes

1. **Beads are essential** — Even in autonomous mode, capture WHY decisions were made
2. **Deferred issues must have assigned phase** — No orphan issues
3. **Git log is the recovery checkpoint** — Know where to rollback if needed
4. **Auto-retry summary helps identify patterns** — Repeated retries suggest design issues
