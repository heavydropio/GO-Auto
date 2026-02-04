---
description: Fully autonomous build with automatic architecture detection (simple or swarm)
arguments:
  - name: phases
    description: Number of phases to run (default: all from ROADMAP)
    required: false
  - name: mode
    description: 'Architecture mode: auto (default), simple, or swarm'
    required: false
---

# /go:auto [phases] [--mode=auto|simple|swarm]

You are the **Boss** running a fully autonomous build using GO-Auto with automatic architecture detection.

## Architecture Decision

**Three execution modes:**
- `--mode=auto` (default) - Analyze build complexity, choose best architecture
- `--mode=simple` - Direct spawning, Boss manages all workers
- `--mode=swarm` - Hierarchical teams with persistent coordinators

**Auto-detection criteria:**
```javascript
function analyze_complexity(roadmap) {
  const total_tasks = count_all_tasks(roadmap)
  const max_parallel = max_tasks_in_any_wave(roadmap)
  const phase_count = count_phases(roadmap)
  const avg_tasks_per_wave = total_tasks / count_waves(roadmap)

  return {
    total_tasks,
    max_parallel,
    phase_count,
    avg_tasks_per_wave,
    complexity_score: (total_tasks * 0.3) + (max_parallel * 2) + (phase_count * 1.5)
  }
}

function choose_architecture(complexity) {
  // Use swarm if:
  // - Total tasks > 15
  // - Max parallel > 6
  // - Complexity score > 30
  // - 4+ phases

  if (complexity.total_tasks > 15 ||
      complexity.max_parallel > 6 ||
      complexity.complexity_score > 30 ||
      complexity.phase_count >= 4) {
    return "swarm"
  }

  return "simple"
}
```

## Prerequisites

Before running `/go:auto`:

1. **ROADMAP.md** must exist with phase definitions
2. **Discovery complete** — USE_CASE.yaml or DISCOVERY_COMPLETE.md exists
3. **Preflight passed** — Run `/go:preflight` first (recommended)

```bash
# Verify prerequisites
ls ROADMAP.md
ls discovery/USE_CASE.yaml || ls discovery/DISCOVERY_COMPLETE.md
ls PREFLIGHT.md  # Optional but recommended
```

If ROADMAP.md doesn't exist, abort with:
> "Cannot run autonomous build without ROADMAP.md. Run `/go:discover` first."

## Initialization

```javascript
// Parse arguments
const phases_arg = arguments.phases || null
const mode_arg = arguments.mode || "auto"

// Read ROADMAP
const roadmap = read("ROADMAP.md")
const total_phases = count_phases(roadmap)
const run_phases = phases_arg ? min(phases_arg, total_phases) : total_phases

// Decide architecture
let architecture = mode_arg

if (mode_arg === "auto") {
  const complexity = analyze_complexity(roadmap)
  architecture = choose_architecture(complexity)

  announce(`📊 Build Analysis:
  - Total tasks: ${complexity.total_tasks}
  - Max parallel: ${complexity.max_parallel}
  - Phases: ${complexity.phase_count}
  - Complexity score: ${complexity.complexity_score}

  🏗️ Selected architecture: ${architecture.toUpperCase()}
  ${architecture === "swarm" ?
    "(Using hierarchical teams with persistent coordinators)" :
    "(Using direct spawning, Boss manages all workers)"}`)
} else {
  announce(`🏗️ Architecture: ${architecture.toUpperCase()} (user-specified)`)
}

// Route to appropriate execution mode
if (architecture === "swarm") {
  execute_swarm_mode(run_phases)
} else {
  execute_simple_mode(run_phases)
}
```

## Initialize HANDOFF.md

If HANDOFF.md doesn't exist, create it:

```markdown
# HANDOFF.md

## Build Info
- **Started**: [timestamp]
- **Mode**: Autonomous (GO-Auto)
- **Architecture**: [simple|swarm]
- **Phases Planned**: [N]

## Beads Log
| ID | Type | Summary | Phase | Status |
|----|------|---------|-------|--------|

## Deferred Issues
| Issue | Assigned Phase | What Breaks |
|-------|----------------|-------------|

## Git Log
| Phase | Commit | Tag |
|-------|--------|-----|
```

## Simple Mode Execution

```javascript
function execute_simple_mode(run_phases) {
  announce("⚡ Running in SIMPLE mode - Boss manages all workers directly")

  for (phase_num = 1; phase_num <= run_phases; phase_num++) {
    announce(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE ${phase_num} - STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`)

    // PHASE A: Environment Review
    announce("[Phase A: Environment Review]")
    const prebuild_agent = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-prebuild-planner.md") + `
        Phase: ${phase_num}
        ROADMAP context: ${read_phase_goals(roadmap, phase_num)}
        HANDOFF context: ${read("HANDOFF.md")}`
    })
    wait(prebuild_agent)
    announce(`✓ BUILD_GUIDE_PHASE_${phase_num}.md created`)

    // PHASE B: Build Planning
    announce("[Phase B: Build Planning]")
    const planner_agent = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-build-planner.md") + `
        Phase: ${phase_num}
        BUILD_GUIDE: ${read(`BUILD_GUIDE_PHASE_${phase_num}.md`)}`
    })
    wait(planner_agent)
    announce(`✓ PHASE_${phase_num}_PLAN.md created`)

    // PHASE C: Auto-Validation
    announce("[Phase C: Auto-Validation]")
    const validation = auto_validate_plan(`PHASE_${phase_num}_PLAN.md`)
    if (validation.errors.length > 0) {
      ABORT("Plan validation failed", validation.errors)
    }
    if (validation.warnings.length > 0) {
      announce(`⚠️ Warnings: ${validation.warnings.join(", ")}`)
    }
    announce("✓ Plan validated")

    // PHASE D: Execution (Boss manages directly)
    announce("[Phase D: Execution]")
    const plan = read_plan(`PHASE_${phase_num}_PLAN.md`)

    for (wave of plan.waves) {
      announce(`⏳ Wave ${wave.number}: ${wave.tasks.length} tasks in parallel`)

      // Spawn all workers for this wave
      const workers = []
      for (task of wave.tasks) {
        const worker = Task({
          subagent_type: "general-purpose",
          prompt: load_agent("agents/go-builder.md") + `
            Task: ${task.id} - ${task.name}
            Description: ${task.description}
            Files: ${task.files}
            Smoke tests: ${task.smoke_tests}
            Done when: ${task.done_when}`
        })
        workers.push({ worker, task })
      }

      // Wait and collect results
      const results = wait_all(workers)

      // Handle failures with auto-retry
      for (result of results) {
        if (result.status === "failed") {
          announce(`⚠️ Task ${result.task.id} failed, attempting auto-retry...`)
          const retry_result = auto_retry_task(result, max_attempts=2)
          if (retry_result.status === "failed") {
            ABORT(`Task ${result.task.id} failed after retries`, retry_result)
          }
          announce(`✓ Task ${result.task.id} recovered after retry`)
        }
      }

      // Git checkpoint
      git_add(wave.files)
      git_commit(`feat(phase-${phase_num}-w${wave.number}): ${wave.description}`)
      announce(`✓ Wave ${wave.number} complete, committed`)
    }

    // PHASE E: Code Shortening
    announce("[Phase E: Code Shortening]")
    const major_files = identify_major_files(phase_num)
    const refactor_agents = []
    for (file of major_files) {
      refactor_agents.push(Task({
        subagent_type: "general-purpose",
        prompt: load_agent("agents/go-refactor.md") + `
          File: ${file}
          Reduce complexity without changing behavior`
      }))
    }
    wait_all(refactor_agents)
    announce(`✓ Refactored ${major_files.length} files`)

    // PHASE F: Code Review
    announce("[Phase F: Code Review]")
    const code_review = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-code-reviewer.md")
    })
    const security_review = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-security-reviewer.md")
    })

    const reviews = wait_all([code_review, security_review])

    if (any_blocked(reviews)) {
      const fixed = auto_fix_review_issues(reviews, max_attempts=2)
      if (!fixed) {
        ABORT("Review blocked after fix attempts")
      }
    }
    announce("✓ Code review passed")

    // PHASE G: Status Update
    announce("[Phase G: Status Update]")
    update_handoff_beads(phase_num)
    git_tag(`v${version}-phase-${phase_num}`)
    announce(`✓ Tagged v${version}-phase-${phase_num}`)

    announce(`✓ Phase ${phase_num} complete`)
  }

  // PHASE H: Final Verification
  announce("[Phase H: Final Verification]")
  const verifier = Task({
    subagent_type: "general-purpose",
    prompt: load_agent("agents/go-verifier.md")
  })
  wait(verifier)
  announce("✓ Verification complete")

  announce("✅ Build complete!")
}
```

## Swarm Mode Execution

```javascript
function execute_swarm_mode(run_phases) {
  announce("🌊 Running in SWARM mode - Hierarchical teams with persistent coordinators")

  // Initialize core team
  announce("Initializing core team...")
  Teammate({
    operation: "spawnTeam",
    team_name: "go-auto-build",
    description: "GO-Auto autonomous build orchestration"
  })

  // Spawn core specialists
  const core_team = [
    { name: "planner", agent: "go-planner", phases: "A-B" },
    { name: "architect", agent: "go-architect", phases: "C" },
    { name: "wave-coordinator", agent: "go-wave-coordinator", phases: "D" },
    { name: "quality-lead", agent: "go-quality-lead", phases: "E-F" },
    { name: "scribe", agent: "go-scribe", phases: "G" },
    { name: "verifier", agent: "go-verifier", phases: "H" }
  ]

  for (teammate of core_team) {
    Task({
      subagent_type: "general-purpose",
      team_name: "go-auto-build",
      name: teammate.name,
      prompt: load_agent(`agents/${teammate.agent}.md`) + `
        You are part of the GO-Auto core team.
        You handle phases: ${teammate.phases}
        You have access to ALL tools including Task and Teammate.
        Spawn sub-swarms as needed for your work.`
    })
    announce(`  ✓ Spawned ${teammate.name}`)
  }

  // Verify team is online
  announce("Verifying team members...")
  for (teammate of core_team) {
    SendMessage({
      type: "message",
      recipient: teammate.name,
      content: "Status check - are you online?"
    })
  }

  // Wait for responses
  wait_for_team_ready()
  announce("✓ Core team assembled and ready")

  // Execute phases via delegation
  for (phase_num = 1; phase_num <= run_phases; phase_num++) {
    announce(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE ${phase_num} - STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`)

    // PHASE A-B: Delegate to planner
    announce("[Phase A-B: Planning]")
    TaskCreate({
      subject: `Execute Phase A-B for Phase ${phase_num}`,
      description: `Phase: ${phase_num}
        ROADMAP goals: ${read_phase_goals(roadmap, phase_num)}
        HANDOFF context: ${read("HANDOFF.md")}

        Create BUILD_GUIDE_PHASE_${phase_num}.md and PHASE_${phase_num}_PLAN.md`,
      owner: "planner"
    })

    wait_for_task_completion("planner")
    announce(`✓ Planner completed Phase A-B`)

    // PHASE C: Delegate to architect
    announce("[Phase C: Validation]")
    TaskCreate({
      subject: `Validate PHASE_${phase_num}_PLAN.md`,
      description: `Validate plan structure, file ownership, smoke tests.
        Report errors or approve.`,
      owner: "architect"
    })

    wait_for_task_completion("architect")
    const validation_msg = read_last_message_from("architect")
    if (validation_msg.contains("ERRORS")) {
      ABORT("Architect rejected plan", validation_msg)
    }
    announce("✓ Architect validated plan")

    // PHASE D: Delegate to wave-coordinator
    announce("[Phase D: Execution]")
    const plan = read_plan(`PHASE_${phase_num}_PLAN.md`)

    for (wave of plan.waves) {
      TaskCreate({
        subject: `Execute Wave ${wave.number} (${wave.tasks.length} tasks)`,
        description: `Wave spec: ${JSON.stringify(wave)}

          Spawn builder sub-swarm (one per task).
          Monitor execution, handle retries.
          Git checkpoint after wave.
          Report completion.`,
        owner: "wave-coordinator"
      })

      wait_for_task_completion("wave-coordinator")
      announce(`✓ Wave ${wave.number} complete`)
    }

    // PHASE E-F: Delegate to quality-lead
    announce("[Phase E-F: Quality]")
    TaskCreate({
      subject: `Execute Phase E-F for Phase ${phase_num}`,
      description: `Phase E: Spawn refactor sub-swarm
        Phase F: Spawn review sub-swarm (code + security)
        Handle auto-retry on BLOCKED reviews.
        Report APPROVED or BLOCKED.`,
      owner: "quality-lead"
    })

    wait_for_task_completion("quality-lead")
    const review_msg = read_last_message_from("quality-lead")
    if (review_msg.contains("BLOCKED")) {
      ABORT("Quality-lead reported blocked review", review_msg)
    }
    announce("✓ Quality review passed")

    // PHASE G: Delegate to scribe
    announce("[Phase G: Status Update]")
    TaskCreate({
      subject: `Update status for Phase ${phase_num}`,
      description: `Extract beads from PHASE_${phase_num}_PLAN.md
        Update HANDOFF.md
        Create git tag v${version}-phase-${phase_num}`,
      owner: "scribe"
    })

    wait_for_task_completion("scribe")
    announce(`✓ Phase ${phase_num} complete`)
  }

  // PHASE H: Delegate to verifier
  announce("[Phase H: Final Verification]")
  TaskCreate({
    subject: "Execute Phase H - Final Verification",
    description: `Spawn test sub-swarm (unit, integration, regression)
      Generate FINAL_VERIFICATION.md and PROJECT_REPORT.md
      Report VERIFIED or ISSUES FOUND`,
    owner: "verifier"
  })

  wait_for_task_completion("verifier")
  announce("✓ Verification complete")

  // Cleanup
  announce("Cleaning up team...")
  Teammate({ operation: "cleanup" })
  announce("✓ Team disbanded")

  announce("✅ Build complete!")
}
```

## Helper Functions

```javascript
function auto_validate_plan(plan_path) {
  const plan = read_plan(plan_path)
  const errors = []
  const warnings = []

  // Structure checks (must pass)
  for (task of plan.tasks) {
    if (!task.done_when || !is_numbered_list(task.done_when)) {
      errors.push(`Task ${task.id}: Missing numbered Done When criteria`)
    }
    if (!task.smoke_tests || !all_runnable(task.smoke_tests)) {
      errors.push(`Task ${task.id}: Smoke tests must be runnable commands`)
    }
  }

  if (!plan.file_ownership_table) {
    errors.push("Missing File Ownership Guarantee table")
  } else {
    const conflicts = find_parallel_write_conflicts(plan.file_ownership_table)
    if (conflicts.length > 0) {
      errors.push(`Parallel write conflicts: ${conflicts}`)
    }
  }

  // Quality checks (warnings)
  if (!plan.risk_assessment) {
    warnings.push("No risk assessment provided")
  }

  return { errors, warnings }
}

function auto_retry_task(failure, max_attempts) {
  for (attempt = 1; attempt <= max_attempts; attempt++) {
    if (failure.confidence < 80) {
      return { status: "failed", reason: "Low confidence fix" }
    }

    const retry_worker = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-builder.md") + `
        RETRY CONTEXT:
        - Previous error: ${failure.error}
        - Root cause: ${failure.root_cause}
        - Suggested fix: ${failure.suggested_fix}
        - Attempt: ${attempt} of ${max_attempts}

        Apply the fix and re-run smoke tests.`
    })

    const result = wait(retry_worker)
    if (result.status === "success") {
      return { status: "success", attempts: attempt }
    }
  }

  return { status: "failed", reason: "Max retries exceeded" }
}

function wait_for_task_completion(owner) {
  while (true) {
    const tasks = TaskList()
    const owner_task = tasks.find(t => t.owner === owner && t.status === "in_progress")

    if (!owner_task) {
      // Check for completed task
      const completed = tasks.find(t => t.owner === owner && t.status === "completed")
      if (completed) return
    }

    wait(5_seconds)
  }
}
```

## Abort Protocol

On any ABORT:

```markdown
## 🔴 Autonomous Build Aborted

**Phase**: {phase_num}
**Stage**: {A|B|C|D|E|F|G|H}
**Architecture**: {simple|swarm}
**Reason**: {reason}

### Context
{full error context}

### Recovery Options
1. Fix the issue manually and re-run `/go:auto`
2. Switch to `/go:simple` or `/go:swarm` to force architecture
3. Review {relevant files} for details

### Git State
Last commit: {commit_hash}
Tag: v{version}-phase-{phase_num}-aborted
```

Create abort tag: `git tag v{version}-phase-{phase_num}-aborted`
