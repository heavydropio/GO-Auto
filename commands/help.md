---
description: Show GO-Auto commands and usage guide
---

# GO-Auto — Command Reference

## Overview

GO-Auto is an autonomous build orchestration system for multi-phase software development. It runs builds from start to finish without human checkpoints, with automatic architecture selection based on build complexity.

## Commands

### Core Commands
| Command | Description |
|---------|-------------|
| `/go:auto [phases] [--mode=auto\|simple\|swarm]` | **Auto-detect architecture** and run autonomous build |
| `/go:simple [phases]` | Force **simple mode** (Boss manages all workers directly) |
| `/go:swarm [phases] [--nesting=2\|3\|auto]` | Force **swarm mode** (hierarchical teams with coordinators) |

### Pre-Build
| Command | Description |
|---------|-------------|
| `/go:discover` | 7-round discovery to create ROADMAP.md |
| `/go:preflight` | Environment validation before build |

### Post-Build
| Command | Description |
|---------|-------------|
| `/go:verify` | Final E2E verification only |

### Utility
| Command | Description |
|---------|-------------|
| `/go:help` | Show this help |

## Architecture Modes

### 🤖 Auto Mode (Default)

**Command:** `/go:auto` or `/go:auto --mode=auto`

**How it works:**
Analyzes ROADMAP complexity and automatically chooses:
- **Simple architecture** for small builds (< 15 tasks, < 6 parallel)
- **Swarm architecture** for large builds (15+ tasks, 6+ parallel, 4+ phases)

**Complexity Analysis:**
```
Score = (total_tasks × 0.3) + (max_parallel × 2) + (phases × 1.5)

If score > 30 OR total_tasks > 15 OR max_parallel > 6:
  → Use Swarm
Else:
  → Use Simple
```

**Example:**
```bash
/go:auto           # Runs all phases, auto-detects architecture
/go:auto 3         # Runs first 3 phases, auto-detects architecture
```

### ⚡ Simple Mode

**Command:** `/go:simple [phases]`

**Architecture:**
- Boss manages all workers directly
- No persistent coordinators
- No teams or sub-swarms
- Single-level spawning (Boss → Workers)

**Best for:**
- Small builds (< 15 tasks)
- Low parallelism (< 6 tasks per wave)
- Quick prototypes
- Testing/debugging
- Learning GO-Auto

**Process tree:**
```
Boss (you in terminal)
├── prebuild-agent (ephemeral)
├── planner-agent (ephemeral)
├── builder-1 (ephemeral)
├── builder-2 (ephemeral)
├── builder-3 (ephemeral)
├── reviewer-1 (ephemeral)
└── verifier (ephemeral)
```

**Example:**
```bash
/go:simple         # Force simple mode for all phases
/go:simple 2       # Force simple mode for first 2 phases
```

### 🌊 Swarm Mode

**Command:** `/go:swarm [phases] [--nesting=2|3|auto]`

**Architecture:**
- Persistent core team (6 specialists)
- Dynamic sub-swarms per phase/wave
- Multi-level hierarchy
- Coordinators learn across phases

**Core Team:**
- `planner` (Phases A-B)
- `architect` (Phase C)
- `wave-coordinator` (Phase D)
- `quality-lead` (Phases E-F)
- `scribe` (Phase G)
- `verifier` (Phase H)

**Best for:**
- Large builds (15+ tasks)
- High parallelism (6+ tasks per wave)
- Complex coordination
- Multi-phase projects (4+ phases)
- Want persistent specialists

**Process tree:**
```
Boss (you in terminal)
└── Core Team (persistent)
    ├── planner
    │   └── [research sub-swarm if complex]
    ├── wave-coordinator
    │   ├── Wave 1 sub-team
    │   │   ├── builder-1
    │   │   │   └── [debug agent if error]
    │   │   ├── builder-2
    │   │   └── builder-3
    │   └── Wave 2 sub-team
    │       ├── builder-1
    │       └── builder-2
    ├── quality-lead
    │   ├── Refactor sub-team
    │   └── Review sub-team
    └── verifier
        └── Test sub-team
```

**Nesting options:**
- `--nesting=2` (standard): Boss → Coordinators → Workers
- `--nesting=3` (deep): Boss → Coordinators → Workers → Sub-agents
- `--nesting=auto`: Boss decides per task based on complexity

**Example:**
```bash
/go:swarm                    # Force swarm mode, standard nesting
/go:swarm --nesting=3        # Allow 3-level nesting
/go:swarm --nesting=auto     # Boss analyzes each task for nesting needs
/go:swarm 4                  # Swarm mode for first 4 phases
```

## Typical Workflow

### New Project
```bash
# 1. Discovery
/go:discover                 # 7-round conversation → ROADMAP.md

# 2. Validation
/go:preflight                # Validate environment

# 3. Autonomous Build
/go:auto                     # Auto-detects architecture, runs all phases
```

### Explicit Architecture Choice
```bash
# Small project - use simple mode
/go:simple

# Large project - use swarm mode
/go:swarm

# Let Boss decide
/go:auto
```

### Incremental Build
```bash
# Run first phase only
/go:auto 1

# Review results, then run next phase
/go:auto 2

# Or run multiple phases
/go:auto 3                   # Runs phases 1-3
```

## Phase Structure (A-H)

| Phase | Name | Simple Mode | Swarm Mode |
|-------|------|-------------|------------|
| A | Environment Review | Boss spawns prebuild planner | `planner` teammate handles |
| B | Build Planning | Boss spawns build planner | `planner` teammate handles |
| C | Plan Validation | Boss validates directly | `architect` teammate validates |
| D | Execution | Boss spawns builders per wave | `wave-coordinator` spawns builder sub-swarms |
| E | Code Shortening | Boss spawns refactor agents | `quality-lead` spawns refactor sub-swarm |
| F | Code Review | Boss spawns reviewers | `quality-lead` spawns review sub-swarm |
| G | Status Update | Boss updates directly | `scribe` teammate handles |
| H | Verification | Boss spawns verifier | `verifier` spawns test sub-swarm |

## Auto-Retry Logic

When a task fails:

1. Worker invokes `systematic-debugging` (mandatory)
2. Returns failure report with confidence level (0-100%)
3. Boss/Coordinator evaluates:
   - **Confidence ≥80% AND fix contained**: Auto-retry (max 2 attempts)
   - **Confidence <80% OR non-contained**: Abort with full context

## Key Documents

| Document | Created By | Purpose |
|----------|-----------|---------|
| `ROADMAP.md` | `/go:discover` | Phase definitions |
| `PREFLIGHT.md` | `/go:preflight` | Environment validation |
| `BUILD_GUIDE_PHASE_N.md` | Phase A | Codebase inventory |
| `PHASE_N_PLAN.md` | Phase B | Task breakdown with waves |
| `HANDOFF.md` | Phase G | Beads and git log |
| `FINAL_VERIFICATION.md` | Phase H | E2E test results |
| `PROJECT_REPORT.md` | Phase H | Build analysis |

## Beads (Decision Tracking)

| Type | Code | Meaning |
|------|------|---------|
| Decision | DD-NNN | Architectural choice made |
| Discovery | DS-NNN | Non-obvious learning |
| Assumption | AS-NNN | Unvalidated bet |
| Friction | FR-NNN | Harder than expected |
| Pivot | PV-NNN | Direction change |

Beads are captured during execution and stored in HANDOFF.md.

## Agent Note Emojis

| Emoji | Meaning |
|-------|---------|
| 🔨 | Worker notes (always required) |
| 📋 | Skill decision |
| ⚠️ | Issue found/fixed |
| 🔴 | Task failed |
| 🟢 | Auto-recovered |
| ✂️ | Code shortened |
| 🔍 | Review notes |

## Decision Matrix

**When to use each mode:**

| Build Size | Tasks | Parallel | Phases | Recommendation |
|------------|-------|----------|--------|----------------|
| Tiny | 1-5 | 1-2 | 1-2 | `/go:simple` |
| Small | 6-10 | 3-4 | 2-3 | `/go:simple` or `/go:auto` |
| Medium | 11-15 | 5-6 | 3-4 | `/go:auto` (likely simple) |
| Large | 16-25 | 7-10 | 4-6 | `/go:auto` (likely swarm) |
| Massive | 25+ | 10+ | 6+ | `/go:swarm` |

## Examples

### Auto-Detection Example
```bash
You: /go:auto

Boss: 📊 Build Analysis:
      - Total tasks: 23
      - Max parallel: 8
      - Phases: 4
      - Complexity score: 34.9

      🏗️ Selected architecture: SWARM
      (Using hierarchical teams with persistent coordinators)

Boss: Initializing swarm architecture...
      ✓ Spawned 6 core specialists

Boss: Starting Phase 1...
[continues...]
```

### Simple Mode Example
```bash
You: /go:simple

Boss: ⚡ Running in SIMPLE mode - Boss manages all workers directly

Boss: Starting Phase 1...
Boss: [Phase A: Environment Review]
Boss: ⏳ Spawning prebuild planner...
Boss: ✓ BUILD_GUIDE_PHASE_1.md created (2m 15s)
[continues...]
```

### Swarm Mode Example
```bash
You: /go:swarm --nesting=auto

Boss: 🌊 Running in SWARM mode - Hierarchical teams with dynamic sub-swarms

Boss: Initializing core team...
      ✓ Spawned planner
      ✓ Spawned architect
      ✓ Spawned wave-coordinator
      ✓ Spawned quality-lead
      ✓ Spawned scribe
      ✓ Spawned verifier

Boss: ✓ Core team assembled and ready (6 specialists)

Boss: Starting Phase 1...
Boss: [Phase A-B: Planning]
Boss: → Assigned to planner
      planner: Starting Phase A...
      planner: Phase A complete (2m 15s)
      planner: Phase B complete (3m 02s)
Boss: ✓ Planner completed Phase A-B
[continues...]
```

## Plugin Location

- **Commands:** `~/.claude/commands/go-auto/`
- **Agents:** `~/.claude/plugins/go-auto/agents/`
- **Templates:** `~/.claude/plugins/go-auto/templates/`
- **Protocols:** `~/.claude/plugins/go-auto/sections/`

## More Information

Read the skill file: `~/.claude/plugins/go-auto/SKILL.md`
Read the README: `~/.claude/plugins/go-auto/README.md`
