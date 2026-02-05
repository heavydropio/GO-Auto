---
description: Discover what to build through guided conversation. After R1, runs autonomously through discovery, preflight, and build.
arguments:
  - name: round
    description: "Optional: Specific round (R2-R7), --resume, or --status"
    required: false
---

# /go-auto:discover [round] — Autonomous Project Discovery & Build

You are the **Boss** running discovery to understand what to build, then building it autonomously.

**Announce**: "Let's figure out what we're building. Tell me about your project and the problem it solves. After our conversation, I'll run everything autonomously."

## Purpose

Discovery is the entry point for GO-Auto projects. A natural conversation (R1) captures what you're building, who it's for, and what it needs to do.

**After R1 completes, everything runs autonomously:**

```
R1 Conversation (interactive)
     ↓
Scope Assessment → LITE or FULL path
     ↓
[AUTONOMOUS FROM HERE]
     ↓
├── LITE: Generate ROADMAP.md
│
└── FULL: Auto-run R2-R7 (no checkpoints)
     ↓
Auto-run /go-auto:preflight
     ↓
Auto-run /go-auto:auto (all build phases)
     ↓
Auto-run /go-auto:ui generate (if screens defined)
     ↓
BUILD COMPLETE
```

**Output**: A fully built project with all artifacts, tests, and documentation.

---

## The One Conversation

R1 is the **only interactive part**. Make it count.

### What to Cover in R1

1. **Problem Statement**: What problem does this solve?
2. **Users/Actors**: Who uses it? What are their roles?
3. **Core Features**: What must it do? (MVP scope)
4. **Technical Context**: Language, framework, integrations?
5. **Constraints**: Timeline, must-haves, must-avoids?

### R1 Outputs

- `discovery/USE_CASE.yaml` — Structured capture of the conversation
- `discovery/discovery-state.json` — State tracking
- Path decision: LITE or FULL

### Scope Assessment Criteria

**Route to LITE path when:**
- Single actor or simple actor model
- ≤3 core workflows
- No complex integrations
- CLI tool, simple API, or single-purpose app

**Route to FULL path when:**
- Multiple actors with different permissions
- >3 workflows with dependencies
- External integrations (payments, auth providers, etc.)
- Multi-step wizards or complex UI

---

## Autonomous Execution (After R1)

### LITE Path Flow

```
R1 complete → LITE path selected
     ↓
1. Generate ROADMAP.md (1 phase per module + integration)
2. Update discovery-state.json with path: "light"
3. Auto-run /go-auto:preflight
4. Auto-run /go-auto:auto (all phases)
5. Report completion
```

No R2-R7 rounds. Entity design and workflows happen during build.

### FULL Path Flow

```
R1 complete → FULL path selected
     ↓
1. Spawn R2 (Entities) + R3 (Workflows) in parallel
2. Wait for both, validate outputs programmatically
3. Spawn R4 (Screens)
4. Spawn R5 (Edge Cases)
5. Spawn R6 (Technical Lock-in)
6. Spawn R7 (Build Plan) → Creates ROADMAP.md
7. Update discovery-state.json with path: "full"
8. Auto-run /go-auto:preflight
9. Auto-run /go-auto:auto (all phases)
10. Auto-run /go-auto:ui generate (if R4 defined screens)
11. Report completion
```

**No user checkpoints between rounds.** Agents validate each other's outputs.

---

## Agent Delegation (FULL Path)

### R2 + R3: Parallel Execution

Spawn both simultaneously after scope assessment:

| Agent | Input | Output |
|-------|-------|--------|
| GO:Discovery Entity Planner | USE_CASE.yaml, module catalogs | R2_ENTITIES.md |
| GO:Discovery Workflow Analyst | USE_CASE.yaml, module catalogs | R3_WORKFLOWS.md |

**Auto-validation**: Check for entity-workflow consistency. If entities referenced in workflows don't exist in R2, flag as warning and continue.

### R4-R7: Sequential Execution

Each agent runs automatically after the previous completes:

| Round | Agent | Input | Output |
|-------|-------|-------|--------|
| R4 | GO:Discovery UI Planner | R2, R3 | R4_SCREENS.md |
| R5 | GO:Discovery Edge Case Analyst | R2-R4 | R5_EDGE_CASES.md |
| R6 | GO:Discovery Tech Architect | R2-R5 | R6_DECISIONS.md |
| R7 | GO:Discovery Build Planner | R2-R6 | DISCOVERY_COMPLETE.md + ROADMAP.md |

**No boss checkpoints.** Each agent reads previous outputs and proceeds.

---

## Auto-Validation Between Rounds

Instead of user approval, programmatic checks:

### After R2 + R3

```
- All entities have at least one workflow reference
- All workflow actors exist in USE_CASE actors
- No circular dependencies in workflows
- Parallelization tracks identified
```

### After R4

```
- Every workflow has at least one screen
- Screen fields map to entity attributes
- No orphan screens (screens without workflows)
```

### After R5

```
- Edge cases reference valid workflows
- Each edge case has a resolution strategy
- No "TBD" resolutions for P1 edge cases
```

### After R6

```
- All external integrations have locked decisions
- Framework/language decisions are final
- No conflicting technology choices
```

### After R7

```
- ROADMAP.md has valid phase structure
- All entities assigned to phases
- Smoke tests defined for each phase
- Readiness gates pass
```

If validation fails with errors → **ABORT** with detailed report.
If validation has warnings → Log and continue.

---

## Blocking Issues in Autonomous Mode

**Hard blockers still stop execution:**

- Ambiguous requirements that can't be inferred
- Conflicting constraints (e.g., "must be serverless" + "must use PostgreSQL")
- Missing critical information (e.g., no auth strategy for multi-actor system)

On hard blocker:
1. Stop autonomous execution
2. Present blocker to user with specific question
3. After user answers, resume from current point

**Soft blockers are logged and deferred** to build phase.

---

## State Management

### discovery-state.json

```json
{
  "project": "{{ project_name }}",
  "mode": "autonomous",
  "path": "light|full",
  "created": "{{ ISO_DATE }}",
  "current_round": "R1",
  "readiness": "NOT_READY|READY",
  "autonomous_stage": "discovery|preflight|build|ui|complete",

  "rounds": {
    "R1": { "status": "complete", "output_file": "discovery/R1_CONTEXT.md" },
    ...
  },

  "validation_results": {
    "R2_R3": { "passed": true, "warnings": [] },
    "R4": { "passed": true, "warnings": [] },
    ...
  }
}
```

### Tracking Progress

The `autonomous_stage` field tracks where we are:
- `discovery` — Running R1-R7
- `preflight` — Running environment validation
- `build` — Running /go-auto:auto
- `ui` — Running /go-auto:ui generate
- `complete` — All done

---

## Command Variants

### Default: Full Autonomous Run
```
/go-auto:discover
```
Starts R1 conversation, then runs everything autonomously.

### Resume from Interruption
```
/go-auto:discover --resume
```
Reads discovery-state.json, continues from `autonomous_stage`.

### Check Status
```
/go-auto:discover --status
```
Shows current stage, round progress, and any blockers.

### Jump to Round (Debug Only)
```
/go-auto:discover R4
```
For debugging. Runs single round, does NOT continue autonomously.

---

## Output Artifacts

### LITE Path

| File | When Created |
|------|--------------|
| discovery/USE_CASE.yaml | After R1 |
| discovery/discovery-state.json | Throughout |
| ROADMAP.md | After scope assessment |
| PREFLIGHT.md | After preflight |
| PHASE_*_PLAN.md | During build |
| HANDOFF.md | During build |
| FINAL_VERIFICATION.md | After build |
| PROJECT_REPORT.md | After build |

### FULL Path

All LITE artifacts plus:

| File | When Created |
|------|--------------|
| discovery/R2_ENTITIES.md | After R2 |
| discovery/R3_WORKFLOWS.md | After R3 |
| discovery/R4_SCREENS.md | After R4 |
| discovery/R5_EDGE_CASES.md | After R5 |
| discovery/R6_DECISIONS.md | After R6 |
| discovery/DISCOVERY_COMPLETE.md | After R7 |
| src/components/screens/*.tsx | After UI phase |

---

## Completion Report

When everything finishes:

```markdown
## GO-Auto Build Complete

**Project**: {{ project_name }}
**Path**: {{ LITE | FULL }}
**Duration**: {{ total_time }}

### Discovery
- Rounds completed: {{ N }}
- Entities: {{ count }} (full path only)
- Workflows: {{ count }} (full path only)
- Screens: {{ count }} (full path only)

### Build
- Phases: {{ N }}
- Tasks: {{ total_tasks }}
- Tests: {{ total_tests }}
- Auto-retries: {{ count }}

### UI (if applicable)
- Screens generated: {{ count }}
- Refinements: {{ count }}

### Artifacts
- ROADMAP.md
- FINAL_VERIFICATION.md
- PROJECT_REPORT.md
- {{ phase_count }} phase plans
- {{ screen_count }} UI components (if applicable)

### Git Tags
- v{{ version }}-discovery
- v{{ version }}-phase-1 ... v{{ version }}-phase-N
- v{{ version }}-final

### Next Steps
1. Review FINAL_VERIFICATION.md
2. Run the app and test manually
3. Use /go-auto:ui refine for UI adjustments
```

---

## Abort Handling

If autonomous execution aborts at any stage:

```markdown
## GO-Auto Aborted

**Stage**: {{ discovery | preflight | build | ui }}
**Round/Phase**: {{ specific location }}
**Reason**: {{ error description }}

### What Was Completed
{{ list of completed artifacts }}

### Recovery Options
1. Fix the issue and run `/go-auto:discover --resume`
2. Switch to manual mode: `/go:kickoff {{ phase }}`
3. Debug specific round: `/go-auto:discover R{{ N }}`

### Error Details
{{ full error context }}
```

---

## Difference from GO-Build Discovery

| Aspect | GO-Build | GO-Auto |
|--------|----------|---------|
| R1 | Interactive | Interactive |
| R2-R7 | User checkpoints between rounds | Autonomous, no checkpoints |
| After discovery | User runs /go:preflight manually | Auto-chains to preflight |
| After preflight | User runs /go:kickoff manually | Auto-chains to build |
| After build | User runs /go:ui manually | Auto-chains to UI generation |

**GO-Auto is one conversation, then hands-off until completion.**
