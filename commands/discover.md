---
description: Discover what to build through guided conversation. Automatically routes to light path (focused projects) or full path (complex projects with R2-R7).
arguments:
  - name: round
    description: "Optional: Specific round (R2-R7), --resume, or --status"
    required: false
---

# /go:discover [round] — Project Discovery

You are the **Boss** running discovery to understand what to build before building it.

**Announce**: "Let's figure out what we're building. Tell me about your project and the problem it solves."

## Purpose

Discovery is the entry point for every GO Build project. A natural conversation captures what you're building, who it's for, and what it needs to do.

After the conversation, the system assesses project complexity and routes to one of two paths:

**Light path** (focused projects):
- Produces a USE_CASE template, simple ROADMAP, and discovery state
- Skips R2-R7 — entity design, workflows, screens happen during build
- Best for: CLI tools, single-purpose apps, MVPs, small APIs

**Full path** (complex projects):
- Runs R2-R7: entities, workflows, screens, edge cases, tech lock-in, build plan
- Uses module catalogs to draft artifacts, you validate at checkpoints
- Best for: multi-actor systems, compliance-heavy apps, projects with integrations

**Output**: A `discovery/` folder with `discovery-state.json`, `USE_CASE.yaml`, and either a simple `ROADMAP.md` (light) or full round artifacts through `DISCOVERY_COMPLETE.md` (full).

---

## Core Rules

1. **Artifacts over conversation** — Each round produces a concrete file, not just discussion
2. **Inference with transparency** — Every assumption gets a confidence level (high/medium/low)
3. **Show, don't tell** — Users validate by reviewing specs, not reading summaries
4. **Progressive disclosure** — Start simple, add complexity as rounds progress
5. **Parallelization detection** — R3 identifies independent tracks for concurrent building
6. **No building until ready** — Readiness gates must pass before /go:preflight

---

## State Management

### Initialize State (First Run)

Create `discovery/discovery-state.json`:

```json
{
  "project": "{{ project_name }}",
  "created": "{{ ISO_DATE }}",
  "updated": "{{ ISO_DATE }}",
  "current_round": "R1",
  "readiness": "NOT_READY",

  "rounds": {
    "R1": { "name": "Context & Intent", "status": "pending", "output_file": "discovery/R1_CONTEXT.md" },
    "R1.5": { "name": "Module Selection", "status": "pending", "output_file": null },
    "R2": { "name": "Entities", "status": "pending", "output_file": "discovery/R2_ENTITIES.md", "can_parallel_with": ["R3"] },
    "R3": { "name": "Workflows", "status": "pending", "output_file": "discovery/R3_WORKFLOWS.md", "can_parallel_with": ["R2"] },
    "R4": { "name": "Screens", "status": "pending", "output_file": "discovery/R4_SCREENS.md" },
    "R5": { "name": "Edge Cases", "status": "pending", "output_file": "discovery/R5_EDGE_CASES.md" },
    "R6": { "name": "Technical Lock-in", "status": "pending", "output_file": "discovery/R6_DECISIONS.md" },
    "R7": { "name": "Build Plan", "status": "pending", "output_file": "discovery/DISCOVERY_COMPLETE.md" }
  },

  "modules": { "selected": [], "packages": {} },
  "entities": [],
  "workflows": [],
  "screens": [],
  "edge_cases": [],
  "decisions": [],
  "parallelization": { "tracks": [], "integration_points": [] },
  "blocking_issues": [],

  "readiness_gates": {
    "all_rounds_complete": false,
    "no_hard_blockers": false,
    "confidence_threshold_met": false,
    "modules_validated": false
  },

  "research": {
    "standalone": null,
    "on_demand": []
  }
}
```

### Update State

After each round:
1. Update `rounds[RN].status` to "complete"
2. Update `rounds[RN].completed` timestamp
3. Update `current_round` to next round
4. Add any blocking_issues discovered
5. Update `readiness_gates` as conditions are met
6. Save to `discovery/discovery-state.json`

---

## Research Artifact Detection

Before starting R1, check for prior research:

1. Check if `research/RESEARCH_FINDINGS.md` exists
2. Check if `research/RESEARCH_RECOMMENDATIONS.md` exists
3. Check if any `discovery/templates/MODULE_*_GENERATED.md` files exist

If research artifacts are found:
1. Read findings and recommendations
2. Pre-fill USE_CASE fields that have clear answers from research (see field mapping in research/RESEARCH_HANDOFF_SCHEMA.md)
3. In R1 conversation, confirm pre-filled fields instead of asking from scratch
4. Only gap-fill fields not covered by research
5. Set discovery-state.json `research.standalone` with file paths and timestamp
6. Auto-select any research-generated modules found in MODULE_CATALOG.json with source: "research"

If no research artifacts found, proceed with normal R1 flow.

---

## Round Progression

| Round | Name | Path | Parallel | Entry Requires | Output |
|-------|------|------|----------|----------------|--------|
| R1 | Conversational Discovery | Both | — | User has project idea | USE_CASE.yaml |
| — | Scope Assessment | Both | — | R1 complete | Path decision (light/full) |
| R2 | Entities | Full only | with R3 | Full path selected | R2_ENTITIES.md |
| R3 | Workflows | Full only | with R2 | Full path selected | R3_WORKFLOWS.md |
| R4 | Screens | Full only | — | R2 AND R3 complete | R4_SCREENS.md |
| R5 | Edge Cases | Full only | — | R4 complete | R5_EDGE_CASES.md |
| R6 | Technical Lock-in | Full only | — | R5 complete | R6_DECISIONS.md |
| R7 | Build Plan | Full only | — | R6 complete, no hard blockers | DISCOVERY_COMPLETE.md |

---

## Round Details

Each round has its own template file:
- `discovery/templates/ROUND_1_CONTEXT.md`
- `discovery/templates/ROUND_1_5_MODULES.md`
- `discovery/templates/ROUND_2_ENTITIES.md`
- `discovery/templates/ROUND_3_WORKFLOWS.md`
- `discovery/templates/ROUND_4_SCREENS.md`
- `discovery/templates/ROUND_5_EDGE_CASES.md`
- `discovery/templates/ROUND_6_LOCK_IN.md`
- `discovery/templates/ROUND_7_BUILD_PLAN.md`

### Agent Delegation (Full Path Only)

R1 stays with the boss (interactive conversation). R2-R7 each spawn a dedicated agent.

**R2 + R3: Spawn in Parallel**

After scope assessment routes to full path, spawn both simultaneously:

| Agent | subagent_type | Input | Output |
|-------|---------------|-------|--------|
| GO:Discovery Entity Planner | `GO:Discovery Entity Planner` | USE_CASE.yaml, module catalogs | R2_ENTITIES.md |
| GO:Discovery Workflow Analyst | `GO:Discovery Workflow Analyst` | USE_CASE.yaml, module catalogs | R3_WORKFLOWS.md |

Boss validates both outputs before proceeding. Checkpoint with user.

**R4-R7: Spawn Sequentially with Boss Checkpoints**

Each round depends on the previous round's output:

| Round | Agent | subagent_type | Input | Output |
|-------|-------|---------------|-------|--------|
| R4 | GO:Discovery UI Planner | `GO:Discovery UI Planner` | R2, R3 | R4_SCREENS.md |
| R5 | GO:Discovery Edge Case Analyst | `GO:Discovery Edge Case Analyst` | R2-R4 | R5_EDGE_CASES.md |
| R6 | GO:Discovery Tech Architect | `GO:Discovery Tech Architect` | R2-R5 | R6_DECISIONS.md |
| R7 | GO:Discovery Build Planner | `GO:Discovery Build Planner` | R2-R6, discovery-state.json | DISCOVERY_COMPLETE.md |

Between each round, the boss:
1. Reads the agent's output artifact
2. Presents a summary to the user
3. Gets approval or revision direction before spawning the next agent

This keeps the boss context lean — it dispatches agents and reviews results rather than accumulating raw output.

---

## Parallelization Detection Protocol

During R3 (Workflows), apply this checklist:

### Independence Test

For each pair of workflows (A, B):

1. **Data Independence**
   - [ ] A does not read data written by B
   - [ ] B does not read data written by A
   - [ ] A and B don't modify the same entities

2. **Actor Independence**
   - [ ] Different primary actors OR
   - [ ] Same actor but different contexts

3. **Temporal Independence**
   - [ ] A doesn't need B to complete first
   - [ ] B doesn't need A to complete first

If all checks pass: Mark as parallelizable.

### Track Formation

Group parallelizable workflows into tracks:
- Each track = independent buildable unit
- Tracks share a final integration point
- Name tracks by their primary function (Financial, CRM, etc.)

---

## Blocking Issue Protocol

When a blocking issue is discovered:

1. **Classify Severity**
   - `hard`: Cannot proceed. Discovery stops until resolved.
   - `soft`: Can continue but must resolve before /go:preflight.
   - `warning`: Note for build phase.

2. **Document Issue**
   ```json
   {
     "id": "BI-001",
     "round": "R3",
     "description": "Unclear how payments integrate with accounting system",
     "severity": "hard",
     "resolution": null,
     "created": "{{ timestamp }}"
   }
   ```

3. **Hard Blocker Response**
   - Stop current round
   - Present issue to user
   - Await resolution before continuing

---

## Readiness Gates

Before `/go:preflight` can run, all gates must pass:

| Gate | Check | How to Fix |
|------|-------|------------|
| all_rounds_complete | All R1-R7 status = "complete" | Run remaining rounds |
| no_hard_blockers | No blocking_issues with severity = "hard" | Resolve or escalate |
| confidence_threshold_met | No core entities/workflows at "low" confidence | Validate with user |
| modules_validated | modules.selected.length > 0 | Re-run R1.5 |

---

## Command Variants

### Default: Start Fresh
```
/go:discover
```
Starts at R1 if no discovery-state.json exists.

### Resume from Last Round
```
/go:discover --resume
```
Reads discovery-state.json, continues from current_round.

### Jump to Specific Round
```
/go:discover R4
```
Jumps to R4. Use for revision or debugging. Previous rounds must be complete.

### Check Status
```
/go:discover --status
```
Shows round progress and readiness gates without advancing.

---

## Integration with GO Build

### Flow

```
/go:discover (conversation + scope assessment)
     ↓
     ├── Light path: USE_CASE.yaml + ROADMAP.md + discovery-state.json
     │
     └── Full path: R2-R7 artifacts + DISCOVERY_COMPLETE.md + discovery-state.json
          ↓
/go:preflight reads: discovery-state.json (detects path)
     ↓
/go:kickoff uses: ROADMAP.md (light) or parallelization tracks (full)
```

### What /go:preflight Uses

From `discovery-state.json`:
- `path` — Determines whether to run parallelization checks
- `modules.packages` — For dependency verification
- `constraints` — For environment validation

**Light path only**: Preflight reads `ROADMAP.md` for phase structure. No parallelization checks.

**Full path only**: Preflight also reads `DISCOVERY_COMPLETE.md` for parallelization tracks, tech decisions from R6, and entity/workflow counts for resource estimation.

---

## Output Summary

### Light Path

| File | Purpose |
|------|---------|
| `discovery/discovery-state.json` | State with `"path": "light"`, modules, actors, constraints |
| `discovery/USE_CASE.yaml` | Populated template from conversation |
| `ROADMAP.md` | Simple phase breakdown (one phase per module + integration phase) |

### Full Path

| File | Created By | Purpose |
|------|------------|---------|
| `discovery/discovery-state.json` | All rounds | State with `"path": "full"`, all discovery data |
| `discovery/USE_CASE.yaml` | R1 | Populated template from conversation |
| `discovery/R2_ENTITIES.md` | R2 | Data model |
| `discovery/R3_WORKFLOWS.md` | R3 | User flows, parallelization |
| `discovery/R4_SCREENS.md` | R4 | Screen specifications |
| `discovery/R5_EDGE_CASES.md` | R5 | Edge cases and resolutions |
| `discovery/R6_DECISIONS.md` | R6 | Locked technical decisions |
| `discovery/DISCOVERY_COMPLETE.md` | R7 | Build plan, readiness |

---

## After Discovery

### Light Path Completion

```markdown
Discovery complete (light path).

Summary:
- {{ actor_count }} actors
- {{ module_count }} modules selected
- {{ phase_count }} phases in roadmap

Next: Run `/go:preflight` to validate your environment.
```

### Full Path Completion

```markdown
Discovery complete (full path).

Summary:
- {{ entity_count }} entities
- {{ workflow_count }} workflows
- {{ screen_count }} screens
- {{ parallelization_track_count }} parallel tracks
- Readiness: READY

Next: Run `/go:preflight` to validate your environment.
```
