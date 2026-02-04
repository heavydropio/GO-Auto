# Round 3: Workflows

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 15-20 minutes

---

## Purpose

Round 3 serves a **dual role** in the discovery process:

1. **Workflow Mapping** — How work flows through the system: user journeys, decision points, state transitions, and the data touched along the way

2. **Parallelization Detection** — Identify which workflows are independent and can be built concurrently, splitting the project into parallel build tracks

Workflows become `feature` and `screen` type nodes. The parallelization analysis directly feeds into R7's build plan, determining which phases can run simultaneously.

### Why This Matters

Without workflow mapping, you build features in isolation. Without parallelization detection, you build everything sequentially. Both waste time and create integration nightmares.

**Example**: An inspection app might have:
- "Report Generation" track (office-based, read-heavy)
- "Field Data Collection" track (mobile, write-heavy)

These can be built in parallel because they don't share data writes until the final integration point.

---

## Entry Requirements

Before starting R3:
- [ ] R1 (Context & Intent) complete
- [ ] R1.5 (Module Selection) complete
- [ ] `discovery/R1_CONTEXT.md` exists with actors and goals
- [ ] `discovery/discovery-state.json` has modules.selected populated

**Note**: R3 can run in parallel with R2 (Entities). They inform each other but don't block.

---

## Instructions for Boss Agent

### Preparation (2 minutes)

1. **Review R1 Outputs**
   - Load `discovery/R1_CONTEXT.md`
   - Extract all actors and their primary goals
   - Note success criteria (these become workflow end states)

2. **Review Module Packages**
   - From `discovery-state.json`, get `modules.packages`
   - Each package suggests workflows (e.g., `invoicing` → invoice creation workflow)

### Workflow Discovery Protocol (10-15 minutes)

#### Step 1: Start from Actor Goals

For each primary actor in R1:

```
Actor: [Name]
Primary Goal: [From R1]
→ Question: "Walk me through how [Actor] accomplishes [Goal] today, or how you imagine them doing it."
```

Listen for:
- Steps and sequence
- Decisions and branches
- What data they need to see
- What data they create/modify
- Where they might get stuck

#### Step 2: Map Happy Path First

For each workflow identified:

1. **Trigger**: What starts this workflow?
2. **Steps**: What happens in sequence?
3. **End State**: What does success look like?
4. **Outputs**: What artifacts are created?

```yaml
workflow_id: WF-001
name: [Descriptive name]
actor: [Primary actor]
trigger: [What initiates this workflow]

happy_path:
  - step: 1
    action: [What the user does]
    screen: [Screen name or "TBD"]
    data_read: [Entities read]
    data_write: [Entities created/modified]

  - step: 2
    action: [Next action]
    # ... etc

end_state: [Success criteria]
outputs: [What gets created]
```

#### Step 3: Identify Variations and Branches

For each happy path, explore:

- **Error paths**: "What if step N fails?"
- **Alternative paths**: "Are there other ways to reach the same goal?"
- **Decision points**: "Where does the user choose between options?"
- **Edge cases**: "What about [unusual scenario]?"

Add these as variations to the workflow:

```yaml
variations:
  - id: VAR-001
    name: [Variation name]
    branches_at: [Step number]
    condition: [When this path is taken]
    different_steps:
      - step: [N]
        action: [Alternative action]
    rejoins_at: [Step number or "end"]

  - id: VAR-002
    name: "Error: [Error name]"
    branches_at: [Step number]
    condition: [Error condition]
    recovery_steps:
      - [Recovery action 1]
      - [Recovery action 2]
    end_state: [Error resolution or escalation]
```

#### Step 4: Note Entity Interactions

For each workflow, track which entities are:
- **Read**: Data consumed but not changed
- **Created**: New records added
- **Modified**: Existing records changed
- **Deleted**: Records removed (rare but important)

This feeds parallelization analysis — workflows that write to the same entities cannot run in parallel.

### Parallelization Detection Protocol (5 minutes)

**This is critical for efficient builds.**

#### Independence Test Checklist

For each pair of workflows (A, B), apply these tests:

**1. Data Independence**
```
[ ] A does not read data written by B (no read-after-write dependency)
[ ] B does not read data written by A (no read-after-write dependency)
[ ] A and B don't modify the same entities (no write-write conflict)
```

**2. Actor Independence**
```
[ ] Different primary actors, OR
[ ] Same actor but different contexts (e.g., office vs. field)
```

**3. Temporal Independence**
```
[ ] A doesn't need B to complete first (no sequence dependency)
[ ] B doesn't need A to complete first (no sequence dependency)
```

**Scoring**:
- All 5 checks pass → **PARALLEL** (can build simultaneously)
- 1-2 checks fail → **SOFT DEPENDENCY** (document the constraint)
- 3+ checks fail → **SEQUENTIAL** (must build in order)

#### Track Formation Rules

Group parallelizable workflows into **tracks**:

1. **Seed tracks** with workflows that have no dependencies
2. **Add workflows** that share data patterns but don't conflict
3. **Name tracks** by their primary function (e.g., "Financial Track", "Field Track")
4. **Identify integration points** where tracks must merge

```yaml
tracks:
  - track_id: TRACK-A
    name: [Functional name]
    primary_actor: [Actor or "multiple"]
    workflows: [WF-001, WF-003, WF-007]
    entities_owned: [Entities this track primarily writes]
    can_start_after: [Track or phase dependency]

  - track_id: TRACK-B
    name: [Functional name]
    # ... etc

integration_points:
  - point_id: INT-001
    tracks: [TRACK-A, TRACK-B]
    description: [What must integrate]
    entities_shared: [Entities both tracks touch]
    integration_type: [merge | handoff | sync]
    when: [Phase or milestone when integration occurs]
```

---

## Output Template

### Workflows Summary

| ID | Name | Actor | Trigger | Steps | Entities Written | Track |
|----|------|-------|---------|-------|------------------|-------|
| WF-001 | [Name] | [Actor] | [Trigger] | [N] | [List] | [Track ID] |
| WF-002 | [Name] | [Actor] | [Trigger] | [N] | [List] | [Track ID] |

### Workflow Details

```yaml
# Workflow WF-001
workflow:
  id: WF-001
  name: "[Descriptive Name]"
  actor: "[Primary Actor]"
  module: "[Module from R1.5]"
  package: "[Package from R1.5]"

  trigger:
    type: [user_action | scheduled | event | external]
    description: "[What initiates this workflow]"

  preconditions:
    - "[Condition that must be true before workflow can start]"

  happy_path:
    - step: 1
      action: "[User action or system action]"
      screen: "[Screen name]"
      data_read:
        - entity: "[Entity name]"
          purpose: "[Why this data is needed]"
      data_write: []
      decision_point: false

    - step: 2
      action: "[Next action]"
      screen: "[Screen name]"
      data_read: []
      data_write:
        - entity: "[Entity name]"
          operation: [create | update | delete]
          fields: ["field1", "field2"]
      decision_point: true
      branches:
        - condition: "[Condition A]"
          goto: 3
        - condition: "[Condition B]"
          goto: 5

    # Continue for all steps...

  end_state:
    success_criteria: "[What makes this workflow successful]"
    outputs:
      - type: [entity | document | notification | state_change]
        description: "[What is produced]"

  variations:
    - id: VAR-001
      name: "[Variation name]"
      branches_at: [step_number]
      condition: "[When this variation applies]"
      different_steps:
        - step: [N]
          action: "[Alternative action]"
      rejoins_at: [step_number | "end"]

    - id: VAR-ERR-001
      name: "Error: [Error type]"
      branches_at: [step_number]
      condition: "[Error condition]"
      recovery:
        - "[Recovery step 1]"
        - "[Recovery step 2]"
      end_state: "[How error resolves]"

  metadata:
    confidence: [high | medium | low]
    source: "[What user said or inference basis]"
    open_questions:
      - "[Question needing validation]"
```

### Decision Points Matrix

| Workflow | Step | Decision | Options | Criteria | Confidence |
|----------|------|----------|---------|----------|------------|
| WF-001 | 3 | [Decision] | A: [Option], B: [Option] | [How decided] | [confidence] |

### Entity Interaction Matrix

| Workflow | Entities Read | Entities Created | Entities Modified | Entities Deleted |
|----------|---------------|------------------|-------------------|------------------|
| WF-001 | [List] | [List] | [List] | [List] |
| WF-002 | [List] | [List] | [List] | [List] |

---

## Parallelization Output

### Independence Analysis

```yaml
parallelization_analysis:
  timestamp: "{{ ISO_DATE }}"
  total_workflows: [N]
  parallel_pairs: [N]
  sequential_pairs: [N]

  pairwise_analysis:
    - pair: [WF-001, WF-002]
      data_independence:
        a_reads_b_writes: false
        b_reads_a_writes: false
        shared_writes: []
        result: PASS
      actor_independence:
        same_actor: false
        result: PASS
      temporal_independence:
        a_needs_b: false
        b_needs_a: false
        result: PASS
      verdict: PARALLEL

    - pair: [WF-001, WF-003]
      data_independence:
        a_reads_b_writes: true
        b_reads_a_writes: false
        shared_writes: ["Invoice"]
        result: FAIL
      actor_independence:
        same_actor: true
        same_context: true
        result: FAIL
      temporal_independence:
        a_needs_b: false
        b_needs_a: true
        result: FAIL
      verdict: SEQUENTIAL
      soft_dependency: "WF-003 must wait for Invoice created by WF-001"

    # ... analyze all pairs
```

### Track Assignments

```yaml
tracks:
  - track_id: TRACK-A
    name: "[Primary function name]"
    description: "[What this track accomplishes]"
    primary_actor: "[Actor or 'multiple']"
    workflows:
      - WF-001
      - WF-003
      - WF-007
    entities_owned:
      - entity: "[Entity name]"
        operations: [create, update]
    estimated_effort: [xs | s | m | l | xl]
    can_parallel_with: [TRACK-B, TRACK-C]
    must_precede: [TRACK-D]
    notes: "[Any special considerations]"

  - track_id: TRACK-B
    name: "[Primary function name]"
    description: "[What this track accomplishes]"
    primary_actor: "[Actor]"
    workflows:
      - WF-002
      - WF-004
    entities_owned:
      - entity: "[Entity name]"
        operations: [create, update]
    estimated_effort: [xs | s | m | l | xl]
    can_parallel_with: [TRACK-A]
    must_precede: []
    notes: "[Any special considerations]"

integration_points:
  - point_id: INT-001
    name: "[Integration name]"
    tracks: [TRACK-A, TRACK-B]
    description: "[What needs to come together]"
    shared_entities:
      - entity: "[Entity name]"
        track_a_role: [reads | writes]
        track_b_role: [reads | writes]
    integration_type: [merge | handoff | sync | aggregate]
    timing: "[When integration must occur]"
    risks:
      - "[Potential integration issue]"
    acceptance_criteria:
      - "[How we know integration works]"
```

### Track Dependency Graph

```
[ASCII representation of track dependencies]

TRACK-A (Financial) ─────────────────────┐
                                          │
TRACK-B (Field) ─────────────────────────├──→ INT-001 ──→ TRACK-D (Reporting)
                                          │
TRACK-C (Customer) ───────────────────────┘

Legend:
  ───→  Sequential dependency
  ─┐ ├  Parallel tracks merging
```

---

## Validation Checklist

R3 cannot be marked complete until all REQUIRED items are checked:

### Required (Blocks Completion)

**Workflow Coverage**
- [ ] At least 1 workflow defined per primary actor
- [ ] All actor goals from R1 have corresponding workflows
- [ ] Each workflow has trigger, happy path, and end state
- [ ] Each workflow has at least one variation or error path documented

**Entity Tracking**
- [ ] Every workflow identifies data_read entities
- [ ] Every workflow identifies data_write entities (or explicitly notes "none")
- [ ] Entity interaction matrix is complete

**Parallelization**
- [ ] Independence test applied to all workflow pairs
- [ ] At least 1 track defined
- [ ] Track assignments cover all workflows
- [ ] Integration points identified if multiple tracks exist

**Confidence**
- [ ] No workflows at "low" confidence without documented follow-up questions
- [ ] User has validated at least the happy path of primary workflows

### Recommended

- [ ] Decision points matrix complete
- [ ] Error paths documented for critical workflows
- [ ] Effort estimates on tracks
- [ ] Track dependency graph visualized

### Items Needing Validation

| Item | Current Assumption | Risk if Wrong | Follow-up Question |
|------|-------------------|---------------|-------------------|
| [Workflow step] | [Assumption] | [What breaks] | [Question to ask] |

---

## State Update

When R3 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R3": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "workflows_discovered": [N],
      "tracks_identified": [N],
      "integration_points": [N]
    }
  },
  "current_round": "[R4 if R2 complete, else waiting]",

  "workflows": [
    {
      "id": "WF-001",
      "name": "[Name]",
      "actor": "[Actor]",
      "track": "TRACK-A",
      "entities_read": ["Entity1", "Entity2"],
      "entities_write": ["Entity3"],
      "confidence": "high"
    }
  ],

  "parallelization": {
    "tracks": [
      {
        "id": "TRACK-A",
        "name": "[Name]",
        "workflows": ["WF-001", "WF-003"],
        "can_parallel_with": ["TRACK-B"],
        "estimated_effort": "m"
      }
    ],
    "integration_points": [
      {
        "id": "INT-001",
        "tracks": ["TRACK-A", "TRACK-B"],
        "shared_entities": ["Entity3"],
        "timing": "Phase 3"
      }
    ]
  }
}
```

---

## Integration with R2 (Entities)

R3 and R2 inform each other:

| R3 Discovers | R2 Validates |
|--------------|--------------|
| Entities mentioned in workflows | Entity attributes needed |
| Entity relationships implied by data flow | Relationship cardinality |
| New entities needed for workflow state | Entity lifecycle states |

| R2 Discovers | R3 Uses |
|--------------|---------|
| Core entity list | Validates workflow entity references |
| Entity attributes | Informs what data screens must display |
| Entity relationships | Validates workflow data dependencies |

**Sync Protocol** (if running in parallel):
1. After R3 Step 4, share entity list with R2
2. After R2 completes entity definitions, validate R3 entity references
3. Update R3 if new entities discovered or renamed

---

## Example: Inspection App

### Workflows

| ID | Name | Actor | Track |
|----|------|-------|-------|
| WF-001 | Create Inspection | Dispatcher | TRACK-A |
| WF-002 | Complete Field Inspection | Technician | TRACK-B |
| WF-003 | Generate Report | Office Staff | TRACK-A |
| WF-004 | Review and Approve | Supervisor | TRACK-A |

### Track Analysis

```yaml
tracks:
  - track_id: TRACK-A
    name: "Report Generation"
    primary_actor: Office Staff
    workflows: [WF-001, WF-003, WF-004]
    entities_owned:
      - entity: Report
        operations: [create, update]
      - entity: InspectionTemplate
        operations: [create, update]
    can_parallel_with: [TRACK-B]
    notes: "Office-based, read-heavy, focuses on templates and reports"

  - track_id: TRACK-B
    name: "Field Data Collection"
    primary_actor: Technician
    workflows: [WF-002]
    entities_owned:
      - entity: Inspection
        operations: [update]
      - entity: Finding
        operations: [create]
      - entity: Photo
        operations: [create]
    can_parallel_with: [TRACK-A]
    notes: "Mobile, write-heavy, needs offline support"

integration_points:
  - point_id: INT-001
    name: "Inspection Completion Handoff"
    tracks: [TRACK-A, TRACK-B]
    description: "Field data must sync before report can generate"
    shared_entities:
      - entity: Inspection
        track_a_role: reads
        track_b_role: writes
    integration_type: handoff
    timing: "After TRACK-B completes field sync"
```

**Why Parallel?**
- TRACK-A writes to Report, InspectionTemplate
- TRACK-B writes to Inspection, Finding, Photo
- No overlap in write entities
- Integration happens at defined point (INT-001)

---

## Common Patterns

### Workflow Types

| Type | Characteristics | Examples |
|------|-----------------|----------|
| **CRUD** | Simple create-read-update-delete | Contact management, Settings |
| **Linear** | Sequential steps, no branches | Checkout flow |
| **Branching** | Decision points with multiple paths | Approval workflows |
| **State Machine** | Entity moves through defined states | Order fulfillment |
| **Batch** | Process multiple items | Report generation |
| **Scheduled** | Triggered by time | Daily sync, notifications |

### Parallelization Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| **Actor Split** | Different actors, different tracks | Office vs. Field |
| **Domain Split** | Different functional areas | Financial vs. CRM |
| **Read/Write Split** | Readers don't conflict with writers | Reporting vs. Data Entry |
| **Frontend/Backend Split** | UI can parallelize with API | Screen components |

---

## Blocking Issues

If any of these arise, document as a blocking issue:

| Issue Type | Severity | Action |
|------------|----------|--------|
| Actor goal unclear | soft | Clarify with user before finalizing workflow |
| Circular workflow dependency | hard | Redesign workflow boundaries |
| No parallelization possible | warning | Note for R7 build planning |
| Entity ownership conflict | hard | Resolve before track assignment |

---

## Next Steps

After R3 completes:

1. Save as `discovery/R3_WORKFLOWS.md`
2. Update `discovery-state.json` with workflows and parallelization data
3. If R2 also complete:
   - Cross-validate entity references
   - Proceed to R4 (Screens)
4. If R2 not complete:
   - Wait for R2 or share interim entity list
   - Announce: "R3 complete. Waiting for R2 to proceed to R4."

---

## Quick Reference

### Workflow YAML Template (Minimal)

```yaml
workflow:
  id: WF-XXX
  name: ""
  actor: ""
  trigger:
    type: user_action
    description: ""
  happy_path:
    - step: 1
      action: ""
      screen: ""
      data_read: []
      data_write: []
  end_state:
    success_criteria: ""
  metadata:
    confidence: medium
    source: ""
```

### Independence Test Quick Check

```
Pair (A, B):
[ ] No read-after-write: A→B
[ ] No read-after-write: B→A
[ ] No write-write conflict
[ ] Different actors or contexts
[ ] No temporal dependency

All pass? → PARALLEL
```

### Track Assignment Quick Check

```
For each workflow:
1. What entities does it write?
2. What other workflows write same entities?
3. Group co-writers into same track
4. Non-conflicting groups → separate tracks
```
