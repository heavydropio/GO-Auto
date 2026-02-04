# Round 7: Build Plan Auto-Generation

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: Auto-generated (Boss review: 5-10 minutes)

---

## Purpose

Round 7 is the **final discovery round** that transforms all discovery artifacts into an executable build plan. Unlike R1-R6 which require user interaction, **R7 is mostly automatic** — the Boss reviews and validates but does not manually construct the plan.

**What R7 Does**:
1. Collects all nodes discovered across R1-R6 (entities, workflows, screens, integrations)
2. Builds a complete dependency graph from `requires` fields
3. Maps R3 parallelization tracks to build phases
4. Assigns nodes to phases based on type priority
5. Within each phase, assigns nodes to waves based on dependencies
6. Estimates total effort and generates DISCOVERY_COMPLETE.md

**Why Auto-Generation**:
- Discovery has captured all the information needed
- Manual plan creation introduces inconsistencies
- Parallelization detection (R3) directly translates to parallel build tracks
- The algorithm is deterministic given the dependency graph

**R7 Output**:
- `discovery/DISCOVERY_COMPLETE.md` — The master build plan for GO Build execution
- Updated `discovery-state.json` with phase/wave assignments
- All nodes transitioned to `queued` status

---

## Entry Requirements

**R7 cannot begin until ALL gates pass**:

- [ ] R6 (Technical Lock-In) is complete
- [ ] `discovery-state.json` has `readiness = "READY"`
- [ ] All readiness gates are true:
  - [ ] `all_rounds_complete` = true
  - [ ] `no_hard_blockers` = true
  - [ ] `confidence_threshold_met` = true
  - [ ] `modules_validated` = true
  - [ ] `tech_stack_decided` = true
  - [ ] `architecture_locked` = true
  - [ ] `hard_reversibility_confirmed` = true

**If any gate fails**: Return to the appropriate round. R7 does not proceed with unresolved issues.

**Prerequisite Files**:
- `discovery/R1_CONTEXT.md` — Project summary, actors, constraints
- `discovery/R2_ENTITIES.md` — All data nodes
- `discovery/R3_WORKFLOWS.md` — All feature nodes, parallelization tracks
- `discovery/R4_SCREENS.md` — All screen nodes
- `discovery/R5_EDGE_CASES.md` — Edge case resolutions affecting nodes
- `discovery/R6_DECISIONS.md` — Locked technical decisions
- `discovery/discovery-state.json` — Complete state with all nodes

---

## Build Plan Generation Algorithm

The Boss executes this algorithm to generate the build plan.

### Step 1: Collect All Nodes

Gather nodes from discovery state, grouped by type:

```python
def collect_nodes(discovery_state):
    nodes = {
        "infrastructure": [],  # From R6 decisions, implied by tech stack
        "data": [],            # From R2 entities
        "feature": [],         # From R3 workflows
        "screen": [],          # From R4 screens
        "integration": [],     # From R3 workflows with external systems
        "agent": []            # From AI touchpoints in R3/R4
    }

    # Infrastructure nodes from tech stack decisions
    for decision in discovery_state["decisions"]:
        if decision["category"] in ["tech_stack", "auth", "data_storage"]:
            nodes["infrastructure"].append(create_infra_node(decision))

    # Data nodes from entities
    for entity in discovery_state["entities"]:
        nodes["data"].append(create_data_node(entity))

    # Feature/Integration nodes from workflows
    for workflow in discovery_state["workflows"]:
        if workflow.has_external_integration:
            nodes["integration"].append(create_integration_node(workflow))
        nodes["feature"].append(create_feature_node(workflow))

    # Screen nodes from screens
    for screen in discovery_state["screens"]:
        nodes["screen"].append(create_screen_node(screen))

    return nodes
```

**Node Sources**:

| Node Type | Source Round | Discovery Artifact |
|-----------|--------------|-------------------|
| infrastructure | R6 | Tech stack decisions (database, auth, config) |
| data | R2 | Entity definitions |
| feature | R3 | Workflow specifications |
| screen | R4 | Screen specifications |
| integration | R3 | Workflows with external API calls |
| agent | R3/R4 | AI-powered features identified |

### Step 2: Build Dependency Graph

Construct a directed acyclic graph (DAG) from node `requires` fields:

```python
def build_dependency_graph(nodes):
    graph = DirectedGraph()

    for node_type, node_list in nodes.items():
        for node in node_list:
            graph.add_node(node.id, node)

            for required_id in node.requires:
                graph.add_edge(required_id, node.id)  # required → node

    # Validate: no cycles
    if graph.has_cycle():
        raise BlockingIssue(
            severity="hard",
            description="Circular dependency detected",
            nodes=graph.find_cycle()
        )

    # Compute transitive closure for optimization
    graph.compute_blocks()  # Populate node.blocks from requires

    return graph
```

**Dependency Rules**:

| If Node Type Is | It Typically Requires |
|-----------------|----------------------|
| data | infrastructure.database |
| screen | data nodes it displays |
| feature | data nodes it modifies, screens it uses |
| integration | infrastructure.config, feature nodes that trigger it |
| agent | data nodes for context, integration nodes for APIs |

### Step 3: Detect Parallelization from R3 Tracks

Map R3 parallelization tracks to build phases:

```python
def map_tracks_to_phases(parallelization, graph):
    phases = []

    # Phase 0: Always infrastructure (no track, sequential)
    phases.append(Phase(
        number=0,
        name="Infrastructure",
        type="infrastructure",
        track=None,
        nodes=graph.nodes_of_type("infrastructure")
    ))

    # Phase 1: Always data layer (no track, may have internal waves)
    phases.append(Phase(
        number=1,
        name="Data Layer",
        type="data",
        track=None,
        nodes=graph.nodes_of_type("data")
    ))

    # Phases 2+: One per parallelization track
    for i, track in enumerate(parallelization["tracks"]):
        phases.append(Phase(
            number=2 + i,
            name=track["name"],
            type="feature",
            track=track["id"],
            can_parallel_with=[
                2 + j for j, t in enumerate(parallelization["tracks"])
                if t["id"] in track.get("can_parallel_with", [])
            ],
            nodes=collect_track_nodes(track, graph)
        ))

    # Final Phase: Integration (where tracks converge)
    phases.append(Phase(
        number=2 + len(parallelization["tracks"]),
        name="Integration",
        type="integration",
        track=None,
        requires_phases=[2 + i for i in range(len(parallelization["tracks"]))],
        nodes=collect_integration_nodes(parallelization["integration_points"], graph)
    ))

    return phases
```

**Track-to-Phase Mapping**:

| R3 Track | Becomes Phase | Can Run In Parallel With |
|----------|---------------|--------------------------|
| TRACK-A | Phase 2 | Phases from TRACK-A.can_parallel_with |
| TRACK-B | Phase 3 | Phases from TRACK-B.can_parallel_with |
| ... | ... | ... |
| (Integration Points) | Final Phase | None (waits for all) |

### Step 4: Assign Nodes to Phases by Type Priority

Apply type priority ordering within the dependency constraints:

```yaml
phase_type_priority:
  0: infrastructure  # Auth, database, config — everything depends on these
  1: data            # Entities, migrations — features depend on data
  2+: feature        # Business logic, workflows — one phase per track
  N: integration     # Cross-track features, final polish
```

```python
def assign_to_phases(nodes, phases, graph):
    for node in nodes:
        # Determine phase by node type and track
        if node.type == "infrastructure":
            node.build.phase = 0
        elif node.type == "data":
            node.build.phase = 1
        elif node.type in ["feature", "screen", "agent"]:
            # Assign to track's phase
            track_phase = find_phase_for_track(node.track, phases)
            node.build.phase = track_phase.number
        elif node.type == "integration":
            node.build.phase = len(phases) - 1  # Final phase

        phases[node.build.phase].nodes.append(node)
```

### Step 5: Assign Nodes to Waves Within Each Phase

Waves enable parallelism within a phase:

```python
def assign_waves(phase, graph):
    unassigned = set(phase.nodes)
    wave_number = 1

    while unassigned:
        # Wave N: nodes whose dependencies are all assigned to earlier waves
        wave_nodes = []

        for node in unassigned:
            deps_in_phase = [d for d in node.requires if d in phase.node_ids]
            all_deps_assigned = all(
                graph.get_node(d).build.wave < wave_number
                for d in deps_in_phase
            )

            if all_deps_assigned:
                wave_nodes.append(node)

        if not wave_nodes:
            # Stuck — circular dependency within phase
            raise BlockingIssue(
                severity="hard",
                description=f"Circular dependency in Phase {phase.number}",
                nodes=list(unassigned)
            )

        # Assign wave
        for node in wave_nodes:
            node.build.wave = wave_number
            unassigned.remove(node)

        wave_number += 1

    return wave_number - 1  # Total waves in phase
```

**Wave Assignment Rules**:

| Wave | Contains | Dependency Rule |
|------|----------|-----------------|
| Wave 1 | Nodes with no dependencies within the phase | `requires` is empty or all point to earlier phases |
| Wave 2 | Nodes depending only on Wave 1 nodes | All `requires` in this phase are in Wave 1 |
| Wave 3 | Nodes depending on Wave 1 or Wave 2 | Continue pattern... |
| ... | ... | Until all nodes assigned |

**Parallel Hints from R3**: Nodes with matching `parallel_hints` should be placed in the same wave when dependencies allow.

### Step 6: Estimate Effort Per Wave

Calculate effort for planning and progress tracking:

```python
def estimate_wave_effort(wave_nodes):
    effort_map = {"xs": 1, "s": 2, "m": 4, "l": 8, "xl": 16}
    total_points = sum(effort_map[n.build.estimated_effort] for n in wave_nodes)

    # Parallel execution reduces wall-clock time
    max_node_effort = max(effort_map[n.build.estimated_effort] for n in wave_nodes)

    return {
        "total_points": total_points,
        "parallel_time": max_node_effort,  # Wall-clock estimate
        "node_count": len(wave_nodes)
    }
```

**Effort Scale Reference**:

| Size | Meaning | Example |
|------|---------|---------|
| xs | < 30 minutes | Config file, simple model |
| s | 30 min - 2 hours | CRUD endpoint, basic screen |
| m | 2-4 hours | Complex form, business logic |
| l | 4-8 hours | Integration, complex workflow |
| xl | 1-2 days | Major feature, cross-cutting concern |

### Step 7: Generate DISCOVERY_COMPLETE.md

Compile all outputs into the final discovery document (see Output section below).

---

## Phase Structure

### Phase 0: Infrastructure

**Purpose**: Set up foundational systems that everything else depends on.

**Typical Nodes**:
- `infrastructure.core.config` — Environment configuration, secrets
- `infrastructure.core.database` — Database connection, migrations setup
- `infrastructure.auth.jwt_auth` — Authentication system
- `infrastructure.core.logging` — Logging and monitoring

**Characteristics**:
- Always runs first
- Usually 1-2 waves
- No parallelization with other phases
- Must complete before Phase 1 begins

### Phase 1: Data Layer

**Purpose**: Create all entities, schemas, and migrations.

**Typical Nodes**:
- All `data.*` nodes from R2 entities
- Schema definitions
- Initial migrations
- Seed data scripts

**Characteristics**:
- Depends on Phase 0 (database must exist)
- Internal waves based on entity relationships
- Wave 1: Entities with no foreign keys
- Wave 2+: Entities referencing Wave 1 entities

### Phases 2+: Feature Phases (One Per Track)

**Purpose**: Build the business logic for each parallelization track.

**Structure**:
- One phase per track identified in R3
- Phases can run in parallel if their tracks are independent
- Each phase has its own wave structure

**Example**:
```
Phase 2: Financial Track
  - Wave 1: Invoice model extensions, API endpoints
  - Wave 2: Invoice creation workflow, validation
  - Wave 3: Invoice PDF generation

Phase 3: Field Track (PARALLEL with Phase 2)
  - Wave 1: Inspection form screen, photo upload
  - Wave 2: Offline sync logic
  - Wave 3: Field completion workflow
```

### Final Phase: Integration

**Purpose**: Bring tracks together, implement cross-cutting features, final polish.

**Typical Nodes**:
- Integration points from R3
- Cross-track features
- System-wide concerns (notifications, audit logging)
- Performance optimizations
- E2E test setup

**Characteristics**:
- Depends on ALL feature phases completing
- Cannot parallelize (sequential)
- Final verification before deployment

---

## Wave Assignment Rules

### Rule 1: No Dependencies → Wave 1

```yaml
rule: "Nodes with no requirements within their phase go to Wave 1"
check: |
  for each node in phase:
    phase_deps = [r for r in node.requires if r.phase == this_phase]
    if len(phase_deps) == 0:
      assign_wave(node, 1)
```

### Rule 2: Dependencies Determine Minimum Wave

```yaml
rule: "A node's wave must be higher than all its dependencies' waves"
check: |
  for each node with dependencies:
    max_dep_wave = max(dep.wave for dep in node.requires if dep.phase == this_phase)
    assign_wave(node, max_dep_wave + 1)
```

### Rule 3: Parallel Hints Influence Grouping

```yaml
rule: "Nodes with matching parallel_hints should be in the same wave when possible"
check: |
  for each node with parallel_hints:
    hint_nodes = [n for n in phase if n.id in node.parallel_hints]
    target_wave = min(n.wave for n in hint_nodes if n.wave_assigned)
    if node can be in target_wave (dependencies satisfied):
      assign_wave(node, target_wave)
```

### Rule 4: File Conflict Prevention

```yaml
rule: "Nodes that modify the same files should not be in the same wave"
check: |
  for each wave:
    all_writes = collect_all_files(node.build.files.creates + node.build.files.modifies)
    if has_duplicates(all_writes):
      separate_conflicting_nodes_to_sequential_waves()
```

### Wave Assignment Visualization

```
PHASE 1: Data Layer
┌─────────────────────────────────────────────────────────────┐
│ Wave 1: [User, Config, AuditLog]                            │
│         No dependencies within phase                        │
├─────────────────────────────────────────────────────────────┤
│ Wave 2: [Client, Matter]                                    │
│         Depend on User                                      │
├─────────────────────────────────────────────────────────────┤
│ Wave 3: [Invoice, TimeEntry]                                │
│         Depend on Client + Matter                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Output: DISCOVERY_COMPLETE.md Structure

The auto-generated file follows this structure:

### Header

```markdown
# Discovery Complete: {{ project_name }}

**Generated**: {{ ISO_DATE }}
**Discovery Duration**: {{ total_time }}
**Readiness**: READY

---
```

### Project Summary (from R1)

```markdown
## Project Summary

**Problem Statement**: {{ from R1_CONTEXT }}

**Primary Actors**:
{{ for actor in actors }}
- **{{ actor.name }}**: {{ actor.role }}
{{ endfor }}

**Success Criteria**:
{{ for criterion in success_criteria }}
- {{ criterion }}
{{ endfor }}

**Constraints**:
{{ for constraint in constraints }}
- {{ constraint }}
{{ endfor }}
```

### Tech Stack Decisions (from R6)

```markdown
## Tech Stack

| Category | Decision | Rationale |
|----------|----------|-----------|
{{ for decision in decisions where category == "tech_stack" }}
| {{ decision.title }} | {{ decision.selected }} | {{ decision.rationale_summary }} |
{{ endfor }}

### Architecture
- **Pattern**: {{ architecture_pattern }}
- **API Style**: {{ api_style }}
- **Authentication**: {{ auth_method }}
```

### Build Overview

```markdown
## Build Overview

| Metric | Value |
|--------|-------|
| Total Nodes | {{ total_nodes }} |
| Total Phases | {{ phase_count }} |
| Parallel Tracks | {{ track_count }} |
| Estimated Waves | {{ total_waves }} |
| Estimated Effort | {{ total_effort_points }} points |

### Phase Summary

| Phase | Name | Type | Waves | Nodes | Can Parallel |
|-------|------|------|-------|-------|--------------|
{{ for phase in phases }}
| {{ phase.number }} | {{ phase.name }} | {{ phase.type }} | {{ phase.wave_count }} | {{ phase.node_count }} | {{ phase.can_parallel_with or "—" }} |
{{ endfor }}
```

### Phase-by-Phase Breakdown

```markdown
## Phase Details

### Phase 0: Infrastructure

**Goal**: Set up foundational systems

**Waves**:

#### Wave 0.1
| Node ID | Name | Effort | Files Created |
|---------|------|--------|---------------|
{{ for node in phase_0_wave_1 }}
| {{ node.id }} | {{ node.name }} | {{ node.effort }} | {{ node.files.creates }} |
{{ endfor }}

**Dependencies**: None (first phase)

---

### Phase 1: Data Layer

**Goal**: Create all data models and migrations

**Waves**:

#### Wave 1.1
| Node ID | Name | Effort | Depends On |
|---------|------|--------|------------|
{{ for node in phase_1_wave_1 }}
| {{ node.id }} | {{ node.name }} | {{ node.effort }} | {{ node.requires or "—" }} |
{{ endfor }}

#### Wave 1.2
{{ ... }}

**Dependency Graph**:
```
User ─────────────────────┐
                          ├──→ Invoice
Client ──→ Matter ────────┤
                          └──→ TimeEntry
```

---

### Phase 2: {{ track_name }}

**Goal**: {{ track_description }}
**Track**: {{ track_id }}
**Can Run Parallel With**: Phase {{ parallel_phases }}

**Waves**:
{{ wave_details }}

---

### Phase N: Integration

**Goal**: Bring all tracks together, implement cross-cutting features

**Requires**: Phases {{ all_feature_phases }} complete

**Integration Points**:
{{ for point in integration_points }}
- **{{ point.name }}**: {{ point.description }}
  - Shared Entities: {{ point.shared_entities }}
  - Type: {{ point.integration_type }}
{{ endfor }}

**Waves**:
{{ wave_details }}
```

### Parallelization Map

```markdown
## Parallelization Map

### Track Overview

```
                    ┌─────────────────────┐
                    │    Phase 0:         │
                    │   Infrastructure    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Phase 1:         │
                    │    Data Layer       │
                    └──────────┬──────────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
┌─────────▼─────────┐ ┌────────▼────────┐ ┌────────▼────────┐
│    Phase 2:       │ │    Phase 3:     │ │    Phase 4:     │
│  Financial Track  │ │   Field Track   │ │  Customer Track │
│   (5 waves)       │ │   (4 waves)     │ │   (3 waves)     │
└─────────┬─────────┘ └────────┬────────┘ └────────┬────────┘
          │                    │                    │
          └────────────────────┼────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │    Phase N:         │
                    │   Integration       │
                    └─────────────────────┘
```

### Parallel Execution Windows

| Window | Phases Running | Combined Effort |
|--------|----------------|-----------------|
| 1 | Phase 0 | {{ effort }} |
| 2 | Phase 1 | {{ effort }} |
| 3 | Phases 2, 3, 4 | {{ max_effort }} (parallel) |
| 4 | Phase N | {{ effort }} |

**Total Sequential Time** (without parallelization): {{ sum_all_phases }}
**Estimated Parallel Time**: {{ with_parallelization }}
**Time Savings**: {{ percentage }}%
```

### Integration Points (where tracks converge)

```markdown
## Integration Points

### INT-001: {{ integration_name }}

**Tracks Involved**: {{ track_list }}

**Description**: {{ description }}

**Shared Entities**:
| Entity | Track A Role | Track B Role |
|--------|--------------|--------------|
{{ for entity in shared_entities }}
| {{ entity.name }} | {{ entity.track_a_role }} | {{ entity.track_b_role }} |
{{ endfor }}

**Integration Type**: {{ merge | handoff | sync | aggregate }}

**Timing**: After {{ prerequisite_phases }} complete

**Acceptance Criteria**:
{{ for criterion in acceptance_criteria }}
- [ ] {{ criterion }}
{{ endfor }}

**Risks**:
{{ for risk in risks }}
- {{ risk }}
{{ endfor }}
```

### Risk Summary (from R5/R6)

```markdown
## Risk Summary

### Accepted Risks

| ID | Category | Description | Likelihood | Impact | Mitigation |
|----|----------|-------------|------------|--------|------------|
{{ for risk in accepted_risks }}
| {{ risk.id }} | {{ risk.category }} | {{ risk.description }} | {{ risk.likelihood }} | {{ risk.impact }} | {{ risk.mitigation }} |
{{ endfor }}

### Edge Cases Requiring Monitoring

| ID | Scenario | Resolution | Phase |
|----|----------|------------|-------|
{{ for edge_case in critical_edge_cases }}
| {{ edge_case.id }} | {{ edge_case.scenario }} | {{ edge_case.resolution }} | {{ edge_case.affected_phase }} |
{{ endfor }}
```

### Go/No-Go Checklist

```markdown
## Go/No-Go Checklist

### Readiness Gates (All Must Pass)

- [x] All rounds complete (R1-R7)
- [x] No hard blockers remaining
- [x] Confidence threshold met (no "low" confidence core items)
- [x] Modules validated
- [x] Tech stack decided
- [x] Architecture locked
- [x] Hard-to-reverse decisions confirmed

### Pre-Build Verification

- [ ] Development environment ready
- [ ] Repository initialized
- [ ] Dependencies installable
- [ ] Database accessible
- [ ] External API credentials available

### User Confirmation

- [ ] Project summary accurate
- [ ] Tech stack acceptable
- [ ] Phase structure makes sense
- [ ] Parallelization opportunities captured
- [ ] Risk mitigations adequate

**Final Status**: READY FOR BUILD
```

---

## Node-to-Task Mapping

Each node becomes a task in `PHASE_N_PLAN.md` during `/go:kickoff`:

### Task Template

```markdown
### Task {{ phase }}.{{ wave }}.{{ index }}: {{ node.name }}

**Node ID**: `{{ node.id }}`
**Type**: {{ node.type }}
**Effort**: {{ node.build.estimated_effort }}

**Purpose**:
{{ node.spec.purpose }}

**Acceptance Criteria**:
{{ for ac in node.spec.acceptance_criteria }}
- [ ] {{ ac.description }} ({{ ac.verification_method }})
{{ endfor }}

**Files**:
- Creates: {{ node.build.files.creates }}
- Modifies: {{ node.build.files.modifies }}
- Reads: {{ node.build.files.reads }}

**Dependencies**:
- Requires: {{ node.requires }}
- Blocks: {{ node.blocks }}

**Testing**:
- Unit tests required: {{ node.build.testing.unit_tests_required }}
- Smoke commands:
{{ for cmd in node.build.testing.smoke_commands }}
  - `{{ cmd }}`
{{ endfor }}

**Implementation Notes**:
{{ node.spec.implementation_notes }}

**Open Questions**:
{{ for q in node.spec.questions }}
- {{ q }}
{{ endfor }}
```

### Reference: NODE_SPEC_SCHEMA.md Build Section

The `build` section of each node contains:

```json
{
  "build": {
    "estimated_effort": "xs | s | m | l | xl",
    "phase": 0-N,
    "wave": 1-M,
    "assigned_to": "worker_id (set during execution)",
    "started_at": "timestamp (set during execution)",
    "completed_at": "timestamp (set during execution)",
    "files": {
      "creates": ["paths to new files"],
      "modifies": ["paths to existing files"],
      "reads": ["paths to reference files"]
    },
    "testing": {
      "unit_tests_required": true/false,
      "integration_tests_required": true/false,
      "test_files": ["paths to test files"],
      "smoke_commands": ["commands to verify node works"]
    }
  }
}
```

---

## Visualization

### ASCII Dependency Graph

Generate for each phase:

```
PHASE 1: Data Layer Dependency Graph

infrastructure.core.database
           │
           ├──────────────────────────────────┐
           │                                   │
           ▼                                   ▼
    data.core.user                    data.core.config
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
  data.invoicing.client    data.invoicing.matter
           │                  │
           └────────┬─────────┘
                    │
                    ▼
        data.invoicing.invoice
                    │
                    ▼
       data.invoicing.time_entry
```

### Phase/Wave Table

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          BUILD PLAN OVERVIEW                                 │
├───────┬──────────────────┬────────┬───────┬─────────┬───────────────────────┤
│ Phase │ Name             │ Type   │ Waves │ Nodes   │ Parallel With         │
├───────┼──────────────────┼────────┼───────┼─────────┼───────────────────────┤
│   0   │ Infrastructure   │ infra  │   2   │    4    │ —                     │
│   1   │ Data Layer       │ data   │   3   │    8    │ —                     │
│   2   │ Financial Track  │ feature│   5   │   12    │ Phase 3, Phase 4      │
│   3   │ Field Track      │ feature│   4   │    9    │ Phase 2, Phase 4      │
│   4   │ Customer Track   │ feature│   3   │    6    │ Phase 2, Phase 3      │
│   5   │ Integration      │ integ  │   2   │    5    │ —                     │
├───────┴──────────────────┴────────┴───────┴─────────┴───────────────────────┤
│ TOTALS                             │  19   │   44    │                       │
└────────────────────────────────────┴───────┴─────────┴───────────────────────┘
```

### Parallelization Diagram

```
TIME ──────────────────────────────────────────────────────────────────────▶

PHASE 0: Infrastructure
  ████████

PHASE 1: Data Layer
          ████████████

PHASE 2: Financial     PHASE 3: Field       PHASE 4: Customer
          ╔═══════════════════╗ ╔═══════════════╗ ╔═══════════╗
          ║ ██████████████████║ ║ ██████████████║ ║ ██████████║
          ║ (5 waves)         ║ ║ (4 waves)     ║ ║ (3 waves) ║
          ╚═══════════════════╝ ╚═══════════════╝ ╚═══════════╝
                              │                │
                              └────────┬───────┘
                                       │
PHASE 5: Integration                   ▼
                              ████████████
```

---

## Validation of Generated Plan

Before finalizing DISCOVERY_COMPLETE.md, the Boss validates:

### Completeness Check

```yaml
validation:
  all_nodes_included:
    check: "Every node from discovery-state.json has a phase/wave assignment"
    query: |
      missing = [n for n in state.nodes if n.build.phase is None]
      return len(missing) == 0
    fix: "Assign orphan nodes to appropriate phase based on type"

  all_entities_have_nodes:
    check: "Every R2 entity has a corresponding data node"
    query: |
      entity_ids = set(state.entities.keys())
      node_ids = set(n.id for n in nodes if n.type == "data")
      return entity_ids.issubset(node_ids)
    fix: "Create missing data nodes from entities"

  all_screens_have_nodes:
    check: "Every R4 screen has a corresponding screen node"
    query: |
      screen_ids = set(state.screens.keys())
      node_ids = set(n.id for n in nodes if n.type == "screen")
      return screen_ids.issubset(node_ids)
    fix: "Create missing screen nodes from screens"
```

### Dependency Check

```yaml
validation:
  no_circular_dependencies:
    check: "Dependency graph is a DAG (no cycles)"
    query: "graph.is_acyclic()"
    fix: "Identify cycle, break by removing weakest dependency"

  all_requires_exist:
    check: "Every node.requires references an existing node"
    query: |
      all_ids = set(n.id for n in nodes)
      for node in nodes:
        for req in node.requires:
          if req not in all_ids:
            return False
      return True
    fix: "Remove invalid requires or create missing node"

  phase_order_respected:
    check: "Nodes don't require nodes from later phases"
    query: |
      for node in nodes:
        for req_id in node.requires:
          req_node = get_node(req_id)
          if req_node.build.phase > node.build.phase:
            return False
      return True
    fix: "Move dependent node to later phase or dependency to earlier"
```

### Parallelization Check

```yaml
validation:
  r3_tracks_mapped:
    check: "Every R3 track has a corresponding phase"
    query: |
      track_ids = set(state.parallelization.tracks.keys())
      phase_tracks = set(p.track for p in phases if p.track)
      return track_ids == phase_tracks
    fix: "Create phase for missing track"

  parallel_phases_valid:
    check: "Parallel phases don't have cross-dependencies"
    query: |
      for phase in phases:
        for parallel_phase_num in phase.can_parallel_with:
          parallel_phase = get_phase(parallel_phase_num)
          if has_cross_dependency(phase, parallel_phase):
            return False
      return True
    fix: "Remove parallel marking or resolve dependency"

  integration_points_covered:
    check: "All R3 integration points have corresponding integration nodes"
    query: |
      int_point_ids = set(state.parallelization.integration_points.keys())
      int_nodes = set(n.id for n in nodes if n.type == "integration")
      # At least one node per integration point
      return all(has_node_for(ip) for ip in int_point_ids)
    fix: "Create integration node for missing point"
```

### Effort Check

```yaml
validation:
  reasonable_wave_size:
    check: "No wave has more than 5 nodes (manageable for Workers)"
    query: |
      for phase in phases:
        for wave in phase.waves:
          if len(wave.nodes) > 5:
            return False, wave
      return True, None
    fix: "Split large wave into multiple waves"

  effort_distribution:
    check: "No single wave has more than 40 effort points"
    query: |
      effort_map = {"xs": 1, "s": 2, "m": 4, "l": 8, "xl": 16}
      for wave in all_waves:
        total = sum(effort_map[n.build.estimated_effort] for n in wave.nodes)
        if total > 40:
          return False, wave
      return True, None
    fix: "Move high-effort nodes to separate wave"
```

---

## State Update Instructions

When R7 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R7": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "phases_generated": {{ phase_count }},
      "waves_generated": {{ total_wave_count }},
      "nodes_assigned": {{ total_node_count }},
      "estimated_total_effort": {{ total_effort_points }}
    }
  },

  "current_round": "COMPLETE",
  "readiness": "BUILD_READY",

  "build_plan": {
    "phases": [
      {
        "number": 0,
        "name": "Infrastructure",
        "type": "infrastructure",
        "track": null,
        "can_parallel_with": [],
        "waves": [
          {
            "number": 1,
            "nodes": ["infrastructure.core.config", "infrastructure.core.database"],
            "effort_points": 6
          }
        ],
        "total_effort": 10
      }
      // ... more phases
    ],
    "parallelization": {
      "parallel_windows": [
        {
          "window": 1,
          "phases": [0],
          "wall_clock_effort": 10
        },
        {
          "window": 2,
          "phases": [1],
          "wall_clock_effort": 16
        },
        {
          "window": 3,
          "phases": [2, 3, 4],
          "wall_clock_effort": 24  // Max of parallel phases
        },
        {
          "window": 4,
          "phases": [5],
          "wall_clock_effort": 8
        }
      ],
      "total_sequential_effort": 82,
      "total_parallel_effort": 58,
      "parallelization_savings": "29%"
    }
  },

  // Update all nodes with phase/wave assignments
  "nodes": [
    {
      "id": "infrastructure.core.database",
      "status": "queued",  // Changed from "specified"
      "build": {
        "phase": 0,
        "wave": 1,
        "estimated_effort": "m"
      }
    }
    // ... all nodes
  ]
}
```

### Mark Discovery Complete

```json
{
  "discovery_complete": true,
  "discovery_completed_at": "{{ ISO_DATE }}",
  "ready_for_build": true
}
```

---

## Handoff to GO Build

### How DISCOVERY_COMPLETE.md Feeds /go:preflight

`/go:preflight` reads DISCOVERY_COMPLETE.md to:

1. **Validate Environment**
   - Check that tech stack tools are installed
   - Verify database connectivity
   - Confirm external API access

2. **Generate ROADMAP.md**
   - Convert phases to roadmap structure
   - Include parallelization information

3. **Pre-create Phase Plans**
   - Scaffold `PHASE_N_PLAN.md` files
   - Include wave structure from R7

```yaml
preflight_reads:
  from_discovery_complete:
    - tech_stack_decisions → environment_checks
    - phases → roadmap_structure
    - parallelization_map → parallel_execution_config
    - integration_points → checkpoint_definitions

  from_discovery_state:
    - nodes → task_scaffolding
    - modules.packages → dependency_verification
    - decisions → configuration_validation
```

### How Parallelization Info Feeds /go:kickoff

`/go:kickoff` uses parallelization data to:

1. **Determine Worker Dispatch**
   - Parallel phases can have Workers running simultaneously
   - Workers within a wave run in parallel

2. **Set Up Git Checkpoints**
   - Commit after each wave completes
   - Tag after each phase completes

3. **Configure Review Points**
   - Boss reviews after each wave
   - Extended review at phase boundaries
   - Mandatory review at integration phase

```yaml
kickoff_uses:
  from_build_plan:
    parallel_windows: "Determines concurrent Worker count"
    waves: "Structures task batches"
    integration_points: "Sets review checkpoints"

  execution_model:
    - "Phase N.Wave 1: Dispatch Workers for all Wave 1 nodes"
    - "Wait for all Wave 1 Workers to complete"
    - "Boss review"
    - "Phase N.Wave 2: Dispatch Workers for all Wave 2 nodes"
    - "Continue until phase complete"
    - "If phases can parallel: Start next parallel phase immediately"
```

### Files to Commit

After R7 completes, commit the following:

```bash
git add discovery/DISCOVERY_COMPLETE.md
git add discovery/discovery-state.json
git add discovery/R7_BUILD_PLAN.md  # If separate from DISCOVERY_COMPLETE.md

git commit -m "feat(discovery): complete 7-round discovery process

- Generated build plan with {{ phase_count }} phases
- Identified {{ track_count }} parallel tracks
- Assigned {{ node_count }} nodes to waves
- Estimated effort: {{ total_points }} points
- Parallelization savings: {{ savings }}%

Ready for /go:preflight"
```

---

## Boss Review Protocol

Although R7 is auto-generated, the Boss reviews before finalizing:

### Review Checklist

**Plan Structure**
- [ ] All discovered nodes are included
- [ ] Phase ordering makes sense (infra → data → features → integration)
- [ ] Parallelization tracks match R3 analysis
- [ ] Wave assignments respect dependencies

**Effort Estimates**
- [ ] Effort distribution is reasonable
- [ ] No single wave is overloaded
- [ ] Total effort is achievable

**Dependencies**
- [ ] No circular dependencies
- [ ] Cross-phase dependencies are minimal
- [ ] Integration points are well-defined

**Completeness**
- [ ] DISCOVERY_COMPLETE.md contains all required sections
- [ ] Go/No-Go checklist items are accurate
- [ ] Risk summary includes all accepted risks

### If Issues Found

1. **Minor Issues**: Fix in place, note in commit message
2. **Structural Issues**: Return to appropriate round (usually R3 for parallelization, R6 for decisions)
3. **Missing Information**: Do not proceed — discovery is incomplete

---

## Quick Reference

### Phase Type Priority

```
0: infrastructure → Always first, everything depends on it
1: data          → Second, features depend on data
2+: feature      → One per track, can parallelize
N: integration   → Always last, waits for all tracks
```

### Wave Assignment Quick Check

```
For each node in phase:
1. Get all requires within this phase
2. If no requires → Wave 1
3. If has requires → max(requires.wave) + 1
4. Check for file conflicts with same-wave nodes
5. If conflict → increment wave
```

### Parallelization Quick Check

```
For each pair of phases:
1. Do they share entity writes? → Cannot parallel
2. Does one require the other? → Cannot parallel
3. Different tracks and independent? → Can parallel
```

### Effort Estimation Quick Check

```
xs: Config, simple model, trivial change
s:  Basic CRUD, simple screen, standard endpoint
m:  Complex form, business logic, validation
l:  Integration, multi-step workflow, complex UI
xl: Major feature, cross-cutting concern, significant refactor
```

---

## After R7

```markdown
Discovery complete!

Summary:
- {{ entity_count }} entities
- {{ workflow_count }} workflows
- {{ screen_count }} screens
- {{ node_count }} total nodes
- {{ phase_count }} phases ({{ track_count }} parallel tracks)
- {{ wave_count }} total waves
- Estimated effort: {{ effort_points }} points
- Parallelization savings: {{ savings }}%

Files generated:
- discovery/DISCOVERY_COMPLETE.md
- discovery/discovery-state.json (updated)

Next steps:
1. Review DISCOVERY_COMPLETE.md
2. Run `/go:preflight` to validate your environment
3. Then `/go:kickoff 0` to begin building

Phases {{ parallel_phases }} can run in parallel after Phase 1 completes.
```
