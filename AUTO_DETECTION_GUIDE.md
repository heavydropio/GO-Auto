# Auto-Detection Guide

## Overview

GO-Auto's auto-detection operates at **THREE levels**, allowing both you and Claude (Boss) to make intelligent decisions about architecture complexity.

## Level 1: User Choice (Explicit Commands)

**You control the top level:**

```bash
/go:auto            # I (Boss) decide everything
/go:simple          # You force simple mode
/go:swarm           # You force swarm mode
/go:swarm --nesting=3  # You force swarm with 3-level nesting
```

## Level 2: Boss Architecture Detection (Build-Level)

**When you run `/go:auto`, I analyze ROADMAP complexity:**

```javascript
function analyze_build(roadmap) {
  const total_tasks = count_all_tasks(roadmap)           // e.g., 23
  const max_parallel = max_tasks_in_any_wave(roadmap)    // e.g., 8
  const phase_count = count_phases(roadmap)              // e.g., 4

  // Complexity scoring
  const score = (total_tasks × 0.3) + (max_parallel × 2) + (phase_count × 1.5)
  // Example: (23 × 0.3) + (8 × 2) + (4 × 1.5) = 6.9 + 16 + 6 = 28.9

  // Decision
  if (score > 30 || total_tasks > 15 || max_parallel > 6 || phase_count >= 4) {
    return "swarm"  // Use hierarchical teams
  } else {
    return "simple"  // Direct spawning
  }
}
```

**I announce my decision:**
```
📊 Build Analysis:
- Total tasks: 23
- Max parallel: 8
- Phases: 4
- Complexity score: 28.9

🏗️ Selected architecture: SWARM
(Using hierarchical teams with persistent coordinators)
```

## Level 3: Coordinator Task Detection (Task-Level)

**This is what you're asking about!**

When in swarm mode with `--nesting=auto`, **my coordinators dynamically decide PER TASK whether to allow deeper nesting.**

### How Wave-Coordinator Analyzes Each Task

```javascript
function analyze_task(task) {
  let complexity_score = 0

  // Files to create/modify
  complexity_score += task.files.creates.length × 2     // e.g., 3 files = 6 points
  complexity_score += task.files.modifies.length × 1    // e.g., 2 files = 2 points

  // Dependencies
  complexity_score += task.dependencies.length × 1.5    // e.g., 2 deps = 3 points

  // Context files needed
  complexity_score += task.context_needed.length × 0.5  // e.g., 4 files = 2 points

  // Done-when criteria
  complexity_score += task.done_when.length × 1         // e.g., 5 criteria = 5 points

  // Smoke tests
  complexity_score += task.smoke_tests.length × 0.5     // e.g., 3 tests = 1.5 points

  // Description length
  complexity_score += (task.description.length / 100) × 0.5  // Long desc = more complex

  // Skills required
  complexity_score += task.skills.length × 2            // e.g., 2 skills = 4 points

  // Decision threshold
  return {
    score: complexity_score,
    allow_builder_to_spawn: complexity_score > 15  // Threshold
  }
}
```

### Task Complexity Examples

#### Task A: Simple CRUD Endpoint
```
Files: 1 create, 0 modify
Dependencies: 0
Context: 1 file
Done-when: 2 criteria
Smoke tests: 1
Description: 50 chars
Skills: 1

Score: (1×2) + (0×1) + (0×1.5) + (1×0.5) + (2×1) + (1×0.5) + (0.25) + (1×2)
     = 2 + 0 + 0 + 0.5 + 2 + 0.5 + 0.25 + 2
     = 7.25

Decision: NO NESTING (score < 15)
→ Builder works independently, cannot spawn sub-agents
```

#### Task B: Complex Authentication System
```
Files: 3 create, 2 modify
Dependencies: 2
Context: 4 files
Done-when: 5 criteria
Smoke tests: 3
Description: 217 chars
Skills: 2

Score: (3×2) + (2×1) + (2×1.5) + (4×0.5) + (5×1) + (3×0.5) + (1.085) + (2×2)
     = 6 + 2 + 3 + 2 + 5 + 1.5 + 1.085 + 4
     = 24.585

Decision: YES, ALLOW NESTING (score > 15)
→ Builder can spawn Explore, systematic-debugging, or other sub-agents
```

## Full Hierarchy with Auto-Detection

```
┌─────────────────────────────────────────────────────────────┐
│ YOU RUN: /go:auto                                           │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ LEVEL 1: Boss (Me) Analyzes ROADMAP                        │
│ ├─ 23 tasks, 8 max parallel, 4 phases                      │
│ ├─ Complexity score: 28.9                                  │
│ └─ DECISION: Use SWARM architecture                        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ LEVEL 2: Boss Spawns Core Team                             │
│ ├─ planner (persistent)                                    │
│ ├─ architect (persistent)                                  │
│ ├─ wave-coordinator (persistent)                           │
│ ├─ quality-lead (persistent)                               │
│ ├─ scribe (persistent)                                     │
│ └─ verifier (persistent)                                   │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ LEVEL 3: Wave-Coordinator Analyzes Each Task               │
│                                                             │
│ Wave 1:                                                     │
│ ├─ Task 1.1 (complexity: 7.3)  → NO NESTING               │
│ ├─ Task 1.2 (complexity: 24.6) → ALLOW NESTING ✓          │
│ ├─ Task 1.3 (complexity: 9.1)  → NO NESTING               │
│ ├─ Task 1.4 (complexity: 18.2) → ALLOW NESTING ✓          │
│ └─ Task 1.5 (complexity: 11.4) → NO NESTING               │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│ LEVEL 4: Builders Spawn Sub-Agents (If Allowed)            │
│                                                             │
│ builder-1 (complexity: 7.3)                                │
│ └─ Works independently (no sub-agents)                     │
│                                                             │
│ builder-2 (complexity: 24.6, NESTING ALLOWED)              │
│ ├─ Analyzes task, realizes needs research                  │
│ ├─ Spawns: Explore agent → finds patterns                  │
│ ├─ Writes code using findings                              │
│ ├─ Test fails                                              │
│ ├─ Spawns: systematic-debugging → finds root cause         │
│ ├─ Applies fix                                             │
│ └─ Reports: "Success, used 2 sub-agents"                   │
│                                                             │
│ builder-3 (complexity: 9.1)                                │
│ └─ Works independently (no sub-agents)                     │
│                                                             │
│ builder-4 (complexity: 18.2, NESTING ALLOWED)              │
│ ├─ Encounters complex integration                          │
│ ├─ Spawns: research-agent → analyzes API patterns          │
│ ├─ Spawns: test-generator → creates test suite             │
│ └─ Reports: "Success, used 2 sub-agents"                   │
│                                                             │
│ builder-5 (complexity: 11.4)                               │
│ └─ Works independently (no sub-agents)                     │
└─────────────────────────────────────────────────────────────┘
```

## The Three Auto-Detection Levels in Practice

### Level 1: Build Architecture (You → Boss)

**You decide:**
- `/go:simple` - Force simple (no coordinators)
- `/go:swarm` - Force swarm (with coordinators)
- `/go:auto` - Let Boss analyze and decide

**Boss analyzes:**
- If build is small/simple → Choose simple architecture
- If build is large/complex → Choose swarm architecture

### Level 2: Nesting Policy (Boss → Coordinator)

**You decide:**
- `/go:swarm --nesting=2` - Force 2-level (Boss → Coordinator → Worker, no deeper)
- `/go:swarm --nesting=3` - Force 3-level (Boss → Coordinator → Worker → Sub-agent)
- `/go:swarm --nesting=auto` - Let wave-coordinator analyze per task

**Wave-coordinator analyzes each task:**
- If task is simple (score < 15) → Builder cannot spawn sub-agents
- If task is complex (score > 15) → Builder can spawn sub-agents

### Level 3: Sub-Agent Spawning (Coordinator → Builder → Sub-Agent)

**Builder decides (if allowed by coordinator):**
- Needs codebase research? → Spawn Explore agent
- Encountered complex error? → Spawn systematic-debugging agent
- Needs pattern analysis? → Spawn pattern-analysis agent
- Needs comprehensive tests? → Spawn test-generator agent

**Builder's judgment:**
Only spawns sub-agents when genuinely needed, even if authorized.

## What You See in Terminal

### Auto-Detection Announcements

```bash
You: /go:auto

Boss: 📊 Build Analysis:
      - Total tasks: 23
      - Max parallel: 8
      - Phases: 4
      - Complexity score: 28.9

      🏗️ Selected architecture: SWARM
      (Using hierarchical teams with persistent coordinators)

Boss: Initializing swarm architecture...
      ✓ Spawned 6 core specialists

Boss: [Phase D: Execution]
Boss: → Assigned to wave-coordinator

Boss: ⏳ Wave 1: 5 tasks
Boss: → wave-coordinator analyzing task complexity...
      wave-coordinator: Task 1.1 (complexity: 7.3) - standard, no nesting
      wave-coordinator: Task 1.2 (complexity: 24.6) - HIGH, allowing sub-agents ✓
      wave-coordinator: Task 1.3 (complexity: 9.1) - standard, no nesting
      wave-coordinator: Task 1.4 (complexity: 18.2) - HIGH, allowing sub-agents ✓
      wave-coordinator: Task 1.5 (complexity: 11.4) - standard, no nesting

Boss: → wave-coordinator spawning builder sub-swarm
      wave-coordinator: Created sub-team "go-auto-wave-1"
      wave-coordinator: ✓ Spawned builder-1
      wave-coordinator: ✓ Spawned builder-2 (nesting allowed)
      wave-coordinator: ✓ Spawned builder-3
      wave-coordinator: ✓ Spawned builder-4 (nesting allowed)
      wave-coordinator: ✓ Spawned builder-5

Boss: ⏳ Wave 1 executing (5 tasks in parallel)...
      wave-coordinator: builder-1 working...
      wave-coordinator: builder-2 working...
      wave-coordinator: builder-2 spawned Explore agent (needs pattern research)
      wave-coordinator: builder-3 working...
      wave-coordinator: builder-4 working...
      wave-coordinator: builder-4 spawned systematic-debugging (error encountered)
      wave-coordinator: builder-5 working...
      wave-coordinator: builder-1 complete (1m 23s)
      wave-coordinator: builder-3 complete (1m 45s)
      wave-coordinator: builder-5 complete (2m 01s)
      wave-coordinator: builder-2 complete (2m 34s) - used 1 sub-agent
      wave-coordinator: builder-4 complete (2m 12s) - used 1 sub-agent

Boss: ✓ Wave 1 complete
      Tasks: 5/5 successful
      High-complexity tasks: 2 (allowed nesting)
      Sub-agents spawned: 2
```

## Summary: Who Decides What?

| Decision Level | Who Decides | What They Decide | Based On |
|----------------|-------------|------------------|----------|
| **1. Architecture** | You or Boss | Simple vs Swarm | Build size, parallelism, phase count |
| **2. Nesting Policy** | You or Wave-Coordinator | Can builders spawn sub-agents? | Task complexity score |
| **3. Sub-Agent Spawning** | Builder | Actually spawn sub-agents? | Real-time need during execution |

## The Power of Full Auto

```bash
You: /go:auto
```

**One command triggers:**
1. Boss analyzes → Chooses swarm (28.9 complexity)
2. Boss spawns 6 core specialists
3. Wave-coordinator analyzes 23 tasks individually
4. Wave-coordinator allows nesting for 8 high-complexity tasks
5. Builders spawn 12 sub-agents across those 8 tasks
6. **Total agents in swarm: 1 (Boss) + 6 (Core) + 23 (Builders) + 12 (Sub) = 42 agents**
7. All coordinated automatically
8. You just see progress updates

**Your experience:** Type one command, watch an intelligent swarm of 42 agents build your project autonomously, with each level making smart decisions about when to spawn the next level.

That's the full auto-detection system - **swarms within swarms within swarms**, all decided dynamically based on actual complexity at each level.
