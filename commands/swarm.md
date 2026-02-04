---
description: Autonomous build using hierarchical swarm architecture (persistent coordinators with sub-swarms)
arguments:
  - name: phases
    description: Number of phases to run (default: all from ROADMAP)
    required: false
  - name: nesting
    description: 'Max nesting depth: 2 (standard), 3 (deep), auto (analyze per task)'
    required: false
---

# /go:swarm [phases] [--nesting=2|3|auto]

You are the **Boss** running GO-Auto in **SWARM mode** with hierarchical teams.

**Architecture**: Multi-tier swarm with persistent coordinators who spawn dynamic sub-swarms.

**Use when:**
- Large builds (15+ tasks)
- High parallelism (6+ tasks per wave)
- Complex coordination needed
- Want persistent specialists that learn
- 4+ phases

**Announce**: "Running GO-Auto in SWARM mode - Hierarchical teams with persistent coordinators and dynamic sub-swarms."

## Swarm Architecture

### Tier 1: Core Team (Persistent)
Boss spawns 6 specialists that persist throughout the build:

```
Boss (you)
├── planner (Phases A-B)
├── architect (Phase C)
├── wave-coordinator (Phase D)
├── quality-lead (Phases E-F)
├── scribe (Phase G)
└── verifier (Phase H)
```

### Tier 2: Sub-Swarms (Dynamic)
Core teammates spawn temporary teams as needed:

```
wave-coordinator
└── Creates "wave-N-builders" team
    ├── builder-1
    ├── builder-2
    └── builder-3

quality-lead
├── Creates "refactor-agents" team
│   ├── refactor-1
│   └── refactor-2
└── Creates "reviewers" team
    ├── code-reviewer
    └── security-reviewer

verifier
└── Creates "testers" team
    ├── unit-tester
    ├── integration-tester
    └── regression-tester
```

### Tier 3+: Nested Sub-Swarms (Optional)
Sub-swarm members can spawn their own agents based on task complexity:

```
builder-1
└── Task requires research?
    └── Spawn Explore agent

builder-2
└── Task encounters error?
    └── Spawn systematic-debugging agent

code-reviewer
└── Complex patterns detected?
    └── Spawn pattern-analysis agents
```

## Nesting Depth Control

```javascript
const nesting_arg = arguments.nesting || "auto"

if (nesting_arg === "auto") {
  // Boss decides per task based on complexity
  function should_allow_nesting(task) {
    const complexity = analyze_task_complexity(task)
    return complexity.score > 15  // High complexity tasks can nest
  }
} else {
  const max_depth = parseInt(nesting_arg)
  // Enforce hard limit (2 = Boss → Coordinator → Worker)
}
```

**Nesting Levels:**
- `--nesting=2` (standard): Boss → Coordinators → Workers (no further nesting)
- `--nesting=3` (deep): Boss → Coordinators → Workers → Sub-agents
- `--nesting=auto`: Boss analyzes each task and allows nesting if complexity warrants it

## Prerequisites

Same as `/go:auto`:
1. ROADMAP.md exists
2. Discovery complete
3. Preflight passed (recommended)

## Initialization

```javascript
announce("🌊 Initializing swarm architecture...")

// Create core team
Teammate({
  operation: "spawnTeam",
  team_name: "go-auto-build",
  description: "GO-Auto autonomous build orchestration"
})

// Define core specialists
const core_team = [
  {
    name: "planner",
    agent: "go-planner",
    phases: "A-B",
    capabilities: "Can spawn research sub-swarm for complex discovery"
  },
  {
    name: "architect",
    agent: "go-architect",
    phases: "C",
    capabilities: "Validates plan, no sub-spawning needed"
  },
  {
    name: "wave-coordinator",
    agent: "go-wave-coordinator",
    phases: "D",
    capabilities: "Spawns builder sub-swarm (one per task), handles retries"
  },
  {
    name: "quality-lead",
    agent: "go-quality-lead",
    phases: "E-F",
    capabilities: "Spawns refactor + review sub-swarms"
  },
  {
    name: "scribe",
    agent: "go-scribe",
    phases: "G",
    capabilities: "Documents beads, no sub-spawning needed"
  },
  {
    name: "verifier",
    agent: "go-verifier",
    phases: "H",
    capabilities: "Spawns test sub-swarm (unit, integration, regression)"
  }
]

// Spawn each specialist
for (teammate of core_team) {
  announce(`  Spawning ${teammate.name}...`)

  Task({
    subagent_type: "general-purpose",  // Full toolset including Task/Teammate
    team_name: "go-auto-build",
    name: teammate.name,
    model: "opus",  // All core teammates use Opus
    prompt: load_agent(`agents/${teammate.agent}.md`) + `

      You are part of the GO-Auto core team.
      Your role: ${teammate.capabilities}
      Phases: ${teammate.phases}

      You have access to ALL tools including:
      - Task tool (spawn sub-agents)
      - Teammate tool (create sub-teams)
      - TaskCreate/TaskUpdate/TaskList
      - SendMessage

      When assigned work:
      1. Spawn appropriate sub-swarm if needed
      2. Monitor sub-swarm progress
      3. Consolidate results
      4. Report to Boss
      5. Cleanup sub-team when done

      Nesting policy: ${nesting_arg}
      ${nesting_arg === "auto" ?
        "Analyze task complexity - allow workers to spawn sub-agents if complexity > 15" :
        `Max nesting depth: ${nesting_arg} levels`}
    `
  })

  announce(`  ✓ ${teammate.name} spawned`)
}

// Verify all online
announce("Verifying team members...")
for (teammate of core_team) {
  SendMessage({
    type: "message",
    recipient: teammate.name,
    content: "Status check - confirm online and ready"
  })
}

wait_for_all_responses(timeout: 30_seconds)
announce("✓ Core team assembled and ready (6 specialists)")
announce("")
```

## Execution Flow

For each phase:

### Phases A-B: Planning
```javascript
announce("[Phase A-B: Planning]")
announce("→ Assigned to planner")

TaskCreate({
  subject: `Execute Phase A-B for Phase ${phase_num}`,
  description: `
    Phase A: Create BUILD_GUIDE_PHASE_${phase_num}.md
    Phase B: Create PHASE_${phase_num}_PLAN.md

    If requirements are complex, spawn research sub-swarm:
    - research-codebase (explores patterns)
    - research-dependencies (analyzes tech stack)
    - research-risks (identifies challenges)

    Consolidate findings and create artifacts.
  `,
  owner: "planner",
  metadata: { phase: phase_num, stages: "A-B" }
})

// Monitor progress
while (true) {
  const task = TaskGet("planning-task-id")
  if (task.status === "completed") break

  // Check for messages from planner
  const messages = check_messages_from("planner")
  for (msg of messages) {
    if (msg.type === "progress") {
      announce(`  ${msg.content}`)
    }
  }

  wait(5_seconds)
}

announce("✓ Planner completed Phase A-B")
announce(`  Created: BUILD_GUIDE_PHASE_${phase_num}.md, PHASE_${phase_num}_PLAN.md`)
```

### Phase C: Validation
```javascript
announce("[Phase C: Validation]")
announce("→ Assigned to architect")

TaskCreate({
  subject: `Validate PHASE_${phase_num}_PLAN.md`,
  description: `
    Validate:
    - File ownership (no conflicts)
    - Smoke tests are runnable
    - Done-when criteria are specific
    - Wave dependencies are acyclic

    Report: APPROVED or ERRORS [list]
  `,
  owner: "architect"
})

wait_for_task_completion("architect")

const validation_msg = read_last_message_from("architect")
if (validation_msg.contains("ERRORS")) {
  ABORT("Architect rejected plan", validation_msg.errors)
}

announce("✓ Architect validated plan")
```

### Phase D: Execution (Wave Coordination)
```javascript
announce("[Phase D: Execution]")
announce("→ Assigned to wave-coordinator")

const plan = read_plan(`PHASE_${phase_num}_PLAN.md`)

for (wave of plan.waves) {
  announce(`⏳ Wave ${wave.number}: ${wave.tasks.length} tasks`)
  announce("→ wave-coordinator spawning builder sub-swarm")

  TaskCreate({
    subject: `Execute Wave ${wave.number} (${wave.tasks.length} tasks)`,
    description: `
      Wave specification: ${JSON.stringify(wave)}

      Your workflow:
      1. Create sub-team: "go-auto-wave-${wave.number}"
      2. Spawn builder per task (${wave.tasks.length} builders)
      3. Assign tasks via TaskCreate
      4. Monitor progress via TaskList
      5. Handle failures with auto-retry logic:
         - Builder fails → systematic-debugging
         - Confidence ≥80%? → Spawn retry-builder
         - Confidence <80%? → Report to Boss (abort)
      6. Git checkpoint after all tasks complete
      7. Cleanup sub-team
      8. Report: "Wave ${wave.number} complete, X/Y successful"

      ${nesting_arg === "auto" ?
        "If any task has complexity > 15, allow builder to spawn sub-agents" :
        `Builders max nesting: ${parseInt(nesting_arg) - 2} levels`}
    `,
    owner: "wave-coordinator",
    metadata: { phase: phase_num, wave: wave.number }
  })

  // Monitor wave progress
  while (true) {
    const task = TaskGet(`wave-${wave.number}-task-id`)
    if (task.status === "completed") break

    // Display progress updates from wave-coordinator
    const messages = check_messages_from("wave-coordinator")
    for (msg of messages) {
      announce(`  ${msg.content}`)
    }

    wait(5_seconds)
  }

  announce(`✓ Wave ${wave.number} complete`)
}

announce("✓ Phase D complete")
```

### Phases E-F: Quality
```javascript
announce("[Phase E-F: Quality]")
announce("→ Assigned to quality-lead")

TaskCreate({
  subject: `Execute Phase E-F for Phase ${phase_num}`,
  description: `
    Phase E - Code Shortening:
    1. Identify major files (>200 lines)
    2. Create sub-team: "refactor-agents"
    3. Spawn refactor agent per file
    4. Consolidate results

    Phase F - Code Review:
    1. Create sub-team: "reviewers"
    2. Spawn code-reviewer + security-reviewer in parallel
    3. If BLOCKED:
       - Attempt auto-fix (max 2 attempts)
       - Re-spawn reviewers after fixes
       - If still blocked: Report to Boss
    4. Cleanup sub-team

    Report: "APPROVED" or "BLOCKED [details]"
  `,
  owner: "quality-lead"
})

wait_for_task_completion("quality-lead")

const review_msg = read_last_message_from("quality-lead")
if (review_msg.contains("BLOCKED")) {
  ABORT("Review blocked after quality-lead attempts", review_msg)
}

announce("✓ Quality review passed")
```

### Phase G: Documentation
```javascript
announce("[Phase G: Status Update]")
announce("→ Assigned to scribe")

TaskCreate({
  subject: `Update status for Phase ${phase_num}`,
  description: `
    1. Extract beads from PHASE_${phase_num}_PLAN.md
    2. Update HANDOFF.md beads section
    3. Update HANDOFF.md git log
    4. Create git tag: v${version}-phase-${phase_num}
    5. Commit: "chore(phase-${phase_num}): complete"

    Report: "Phase ${phase_num} documented"
  `,
  owner: "scribe"
})

wait_for_task_completion("scribe")
announce(`✓ Phase ${phase_num} status updated`)
```

### Phase H: Verification
```javascript
announce("[Phase H: Final Verification]")
announce("→ Assigned to verifier")

TaskCreate({
  subject: "Execute Phase H - Final Verification",
  description: `
    1. Create sub-team: "testers"
    2. Spawn test agents:
       - unit-tester (runs all unit tests)
       - integration-tester (E2E flows)
       - regression-tester (ensures nothing broke)
       - performance-tester (benchmarks)
    3. Consolidate results
    4. Generate FINAL_VERIFICATION.md
    5. Generate PROJECT_REPORT.md
    6. Cleanup sub-team

    Report: "VERIFIED" or "ISSUES FOUND [details]"
  `,
  owner: "verifier"
})

wait_for_task_completion("verifier")
announce("✓ Verification complete")
```

## Cleanup

```javascript
announce("Cleaning up core team...")
Teammate({ operation: "cleanup" })
announce("✓ Team disbanded")
```

## Process Tree Example

```
Your Terminal (PID 10000)
└── Boss (me)
    ├── Core Team "go-auto-build"
    │   ├── planner (PID 12345)
    │   │   └── [Optional] research sub-swarm
    │   ├── architect (PID 12346)
    │   ├── wave-coordinator (PID 12347)
    │   │   ├── Wave 1 sub-team "go-auto-wave-1"
    │   │   │   ├── builder-1 (PID 12400)
    │   │   │   │   └── [If complex] Explore agent
    │   │   │   ├── builder-2 (PID 12401)
    │   │   │   │   └── [If error] Debug agent
    │   │   │   └── builder-3 (PID 12402)
    │   │   └── Wave 2 sub-team "go-auto-wave-2"
    │   │       ├── builder-1 (PID 12500)
    │   │       └── builder-2 (PID 12501)
    │   ├── quality-lead (PID 12348)
    │   │   ├── Refactor sub-team
    │   │   │   ├── refactor-1 (PID 12600)
    │   │   │   └── refactor-2 (PID 12601)
    │   │   └── Review sub-team
    │   │       ├── code-reviewer (PID 12700)
    │   │       └── security-reviewer (PID 12701)
    │   ├── scribe (PID 12349)
    │   └── verifier (PID 12350)
    │       └── Test sub-team
    │           ├── unit-tester (PID 12800)
    │           ├── integration-tester (PID 12801)
    │           └── regression-tester (PID 12802)
```

## Comparison: Simple vs Swarm

| Aspect | Simple | Swarm |
|--------|--------|-------|
| **Coordinators** | None | 6 persistent specialists |
| **Boss workload** | Manages all workers | Delegates to coordinators |
| **Sub-teams** | None | Dynamic per wave/phase |
| **Nesting** | 1 level | 2-4 levels |
| **Learning** | None | Coordinators learn patterns |
| **Scalability** | ~20 tasks | Unlimited |
| **Overhead** | Minimal | Team coordination |
| **Best for** | Small builds | Large/complex builds |

## Output Example

```
Running GO-Auto in SWARM mode...

Initializing swarm architecture...
  Spawning planner...
  ✓ planner spawned
  Spawning architect...
  ✓ architect spawned
  Spawning wave-coordinator...
  ✓ wave-coordinator spawned
  Spawning quality-lead...
  ✓ quality-lead spawned
  Spawning scribe...
  ✓ scribe spawned
  Spawning verifier...
  ✓ verifier spawned

Verifying team members...
✓ Core team assembled and ready (6 specialists)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 - STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Phase A-B: Planning]
→ Assigned to planner
  planner: Starting Phase A
  planner: Creating BUILD_GUIDE_PHASE_1.md
  planner: Phase A complete (2m 15s)
  planner: Starting Phase B
  planner: Creating PHASE_1_PLAN.md
  planner: Phase B complete (3m 02s)
✓ Planner completed Phase A-B
  Created: BUILD_GUIDE_PHASE_1.md, PHASE_1_PLAN.md

[Phase C: Validation]
→ Assigned to architect
  architect: Validating file ownership...
  architect: Validating smoke tests...
  architect: Validation complete (0 errors)
✓ Architect validated plan

[Phase D: Execution]
→ Assigned to wave-coordinator

⏳ Wave 1: 5 tasks
→ wave-coordinator spawning builder sub-swarm
  wave-coordinator: Created sub-team "go-auto-wave-1"
  wave-coordinator: Spawned builder-1 (PID 12400)
  wave-coordinator: Spawned builder-2 (PID 12401)
  wave-coordinator: Spawned builder-3 (PID 12402)
  wave-coordinator: Spawned builder-4 (PID 12403)
  wave-coordinator: Spawned builder-5 (PID 12404)
  wave-coordinator: Monitoring 5 builders...
  wave-coordinator: builder-1 complete (1m 23s)
  wave-coordinator: builder-2 failed, retrying...
  wave-coordinator: builder-2 complete after retry (0m 42s)
  wave-coordinator: builder-3 complete (1m 45s)
  wave-coordinator: builder-4 complete (2m 01s)
  wave-coordinator: builder-5 complete (1m 34s)
  wave-coordinator: Git commit: feat(phase-1-w1): core models
  wave-coordinator: Cleanup sub-team complete
✓ Wave 1 complete

[Phase E-F: Quality]
→ Assigned to quality-lead
  quality-lead: Starting Phase E
  quality-lead: Created refactor sub-team
  quality-lead: Spawned 3 refactor agents
  quality-lead: Refactoring complete (1m 52s)
  quality-lead: Starting Phase F
  quality-lead: Created review sub-team
  quality-lead: Spawned code-reviewer + security-reviewer
  quality-lead: Reviews complete - APPROVED
✓ Quality review passed

[Phase G: Status Update]
→ Assigned to scribe
  scribe: Extracting beads...
  scribe: Updated HANDOFF.md
  scribe: Tagged v1.0.0-phase-1
✓ Phase 1 status updated

[Phase H: Final Verification]
→ Assigned to verifier
  verifier: Created test sub-team
  verifier: Spawned unit-tester, integration-tester, regression-tester
  verifier: All tests passing (57/57)
  verifier: Generated FINAL_VERIFICATION.md
✓ Verification complete

Cleaning up core team...
✓ Team disbanded

✅ Build complete!
Total time: 18m 47s
Core team: 6 specialists
Sub-teams created: 4
Total agents spawned: 23
Tasks completed: 12
Auto-retries: 1
Tests passing: 57
```

## Implementation

The swarm mode execution is defined in the main `/go:auto` command as `execute_swarm_mode()`. This command is a convenient alias that forces swarm mode:

```javascript
// Equivalent to:
/go:auto --mode=swarm
```
