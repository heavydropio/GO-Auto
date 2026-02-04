---
description: Autonomous build using simple architecture (Boss manages all workers directly)
arguments:
  - name: phases
    description: Number of phases to run (default: all from ROADMAP)
    required: false
---

# /go:simple [phases] — Simple Architecture Build

You are the **Boss** running GO-Auto in **SIMPLE mode**.

**Architecture**: Direct spawning - you manage all workers directly without persistent coordinators or teams.

**Use when:**
- Small builds (< 15 tasks total)
- Low parallelism (< 6 tasks per wave)
- Testing/debugging GO-Auto
- Want minimal overhead

**Announce**: "Running GO-Auto in SIMPLE mode - Boss manages all workers directly."

## Prerequisites

Same as `/go:auto`:
1. ROADMAP.md exists
2. Discovery complete
3. Preflight passed (recommended)

## Execution Flow

For each phase:

### Phase A: Environment Review
- Spawn single prebuild planner agent
- Wait for BUILD_GUIDE_PHASE_N.md
- No team coordination

### Phase B: Build Planning
- Spawn single build planner agent
- Wait for PHASE_N_PLAN.md
- No team coordination

### Phase C: Auto-Validation
- Boss validates plan directly (no architect teammate)
- Check file ownership, smoke tests, done-when criteria
- Abort on errors, warn on quality issues

### Phase D: Execution
Boss manages all waves directly:

```javascript
for (wave of plan.waves) {
  announce(`⏳ Wave ${wave.number}: ${wave.tasks.length} tasks in parallel`)

  // Spawn all workers for this wave (Boss manages directly)
  const workers = []
  for (task of wave.tasks) {
    const worker = Task({
      subagent_type: "general-purpose",
      prompt: load_agent("agents/go-builder.md") + task_spec
    })
    workers.push(worker)
  }

  // Wait for all workers
  const results = wait_all(workers)

  // Boss handles failures directly
  for (result of results) {
    if (result.failed) {
      auto_retry_task(result)  // Boss retries directly
    }
  }

  // Boss creates git checkpoint
  git_commit(`feat(phase-${phase_num}-w${wave.number}): ${wave.description}`)
}
```

### Phase E: Code Shortening
- Boss spawns refactor agents directly
- No quality-lead coordinator
- Boss collects results

### Phase F: Code Review
- Boss spawns code + security reviewers directly
- No quality-lead coordinator
- Boss handles retry logic

### Phase G: Status Update
- Boss updates HANDOFF.md directly
- No scribe teammate
- Boss creates git tag

### Phase H: Final Verification
- Boss spawns verifier agent directly
- Boss generates reports

## Key Differences from Swarm Mode

| Aspect | Simple Mode | Swarm Mode |
|--------|-------------|------------|
| Team creation | None | Core team + sub-teams |
| Coordinators | None | Persistent specialists |
| Boss workload | Manages everything | Delegates to coordinators |
| Nesting depth | 1 level (Boss → Workers) | 3+ levels (Boss → Coordinators → Workers → Sub-agents) |
| Overhead | Minimal | Higher (team coordination) |
| Scalability | < 20 tasks | Unlimited |
| Learning | None (ephemeral agents) | Coordinators learn across phases |

## Process Architecture

```
Terminal (You)
└── Boss (me)
    ├── prebuild-agent (ephemeral)
    ├── planner-agent (ephemeral)
    ├── builder-1 (ephemeral)
    ├── builder-2 (ephemeral)
    ├── builder-3 (ephemeral)
    ├── refactor-1 (ephemeral)
    ├── refactor-2 (ephemeral)
    ├── code-reviewer (ephemeral)
    ├── security-reviewer (ephemeral)
    └── verifier (ephemeral)

All agents spawned and managed directly by Boss.
No teams, no delegation, no nesting.
```

## When Simple Mode is Better

✅ **Use Simple when:**
- Total tasks < 15
- Max 3-5 tasks per wave
- Single or dual phase builds
- Quick prototypes
- Learning GO-Auto
- Debugging issues

❌ **Don't use Simple when:**
- Total tasks > 20
- High parallelism (8+ tasks per wave)
- 4+ phases
- Complex coordination needed
- Want persistent specialists that learn

## Output Example

```
Starting GO-Auto in SIMPLE mode...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 - STARTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Phase A: Environment Review]
⏳ Spawning prebuild planner...
✓ BUILD_GUIDE_PHASE_1.md created (2m 15s)

[Phase B: Build Planning]
⏳ Spawning build planner...
✓ PHASE_1_PLAN.md created (3m 02s)

[Phase C: Auto-Validation]
⏳ Validating plan...
✓ Plan validated (0 errors, 1 warning)

[Phase D: Execution - Wave 1]
⏳ Spawning 4 builders...
  ✓ builder-1 spawned (PID 12345)
  ✓ builder-2 spawned (PID 12346)
  ✓ builder-3 spawned (PID 12347)
  ✓ builder-4 spawned (PID 12348)

⏳ Wave 1 executing (4 tasks in parallel)...
  Task 1.1: ✓ Complete (1m 23s)
  Task 1.2: ✓ Complete (1m 45s)
  Task 1.3: ⚠ Failed, retrying...
  Task 1.3: ✓ Complete after retry (0m 52s)
  Task 1.4: ✓ Complete (2m 01s)

✓ Wave 1 complete
  Git commit: feat(phase-1-w1): core models

[Phase E: Code Shortening]
⏳ Spawning 3 refactor agents...
✓ Refactored 3 files (1m 34s)

[Phase F: Code Review]
⏳ Spawning reviewers...
  ✓ code-reviewer spawned
  ✓ security-reviewer spawned
✓ Code review passed (2m 12s)

[Phase G: Status Update]
✓ HANDOFF.md updated
✓ Tagged v1.0.0-phase-1

[Phase H: Verification]
⏳ Spawning verifier...
✓ All tests passing (3m 45s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 - COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Build complete!
Total time: 15m 32s
Tasks: 8
Auto-retries: 1
```

## Implementation

The simple mode execution is defined in the main `/go:auto` command as `execute_simple_mode()`. This command is a convenient alias that forces simple mode:

```javascript
// Equivalent to:
/go:auto --mode=simple
```
