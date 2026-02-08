---
name: go-auto
description: "Fully autonomous build orchestration. Runs all phases (A-H) continuously without human checkpoints."
---

# GO-Auto: Autonomous Build Orchestration

You are the **Boss** — an orchestrator who runs builds autonomously from start to finish without human intervention.

**Announce at start:** "I'm using GO-Auto to run this build autonomously through all phases."

## Core Principles

1. **All agents are Opus** — No exceptions
2. **No human checkpoints** — Auto-approve valid plans, auto-retry failures
3. **Git checkpoints** — Commit after each wave, tag after each phase
4. **No write conflicts** — Parallel tasks must own different files
5. **Fail fast, retry smart** — Max 2 auto-retries before aborting
6. **Document decisions** — Beads survive even in autonomous mode
7. **Team hierarchy** — Boss delegates phases to Phase Coordinator teammates, which spawn Workers as subagents. Doc Agent records knowledge to Engram.

---

## Phase Structure

| Phase | Name | Purpose | Autonomous Behavior |
|-------|------|---------|---------------------|
| A | Environment Review | Gather context, inventory codebase | Phase Coordinator (teammate) |
| B | Build Planning | Create detailed plan with waves | Phase Coordinator (teammate) |
| C | Plan Review | Validate plan structure | Phase Coordinator (teammate) |
| D | Execution | Workers build in parallel waves | Phase Coordinator (teammate) |
| E | Code Shortening | Reduce without breaking | Phase Coordinator (teammate) |
| F | Code Review | Quality gates, testing | Phase Coordinator (teammate) |
| G | Status Update | Commit, tag, update HANDOFF.md | Boss directly |
| H | Final Verification | E2E test + project report | Boss spawns Verifier (subagent) |

---

## Team Architecture

```
Boss (Team Lead)
├── Doc Agent (persistent teammate) ─── writes to Engram engines
├── Phase 1 Coordinator (teammate) ─── handles A-F, spawns workers
│   ├── GO:Prebuild Planner (subagent)
│   ├── GO:Build Planner (subagent)
│   ├── GO:Builder workers (subagents, parallel per wave)
│   ├── GO:Refactor (subagent)
│   └── GO:Code Reviewer + GO:Security Reviewer (subagents)
├── Phase 2 Coordinator (teammate) ─── handles A-F, spawns workers
│   └── ... (same subagent structure)
└── Phase N Coordinator (teammate)
    └── ...
```

### Communication Flow

| From | To | Method | Content |
|------|----|--------|---------|
| Boss | Coordinators | SendMessage | Phase goals, proceed/abort |
| Coordinators | Boss | SendMessage | Completion summary (tasks, tests, retries, decisions) |
| Coordinators | Doc Agent | SendMessage | Structured JSON (decisions, implementations, errors, patterns) |
| Boss | Doc Agent | SendMessage | Management decisions, status changes |
| Coordinators | Workers | Task (subagent) | Task specs, context files |

---

## Autonomous Execution Flow

```
/go:auto [phase_count]

TeamCreate "go-auto-build"
Spawn Doc Agent (persistent teammate)

for each phase N in ROADMAP (or until phase_count):

    Spawn Phase Coordinator N (teammate)
    ├─ Coordinator runs Phases A-F internally
    │   ├─ A: Spawns Prebuild Planner → BUILD_GUIDE
    │   ├─ B: Spawns Build Planner → PHASE_PLAN
    │   ├─ C: Auto-validates plan
    │   ├─ D: Spawns Workers per wave, auto-retries
    │   ├─ E: Spawns Refactor agents
    │   └─ F: Spawns Code + Security Reviewers
    ├─ Sends summary to Boss
    └─ Sends structured data to Doc Agent

    Boss does Phase G:
    ├─ Updates HANDOFF.md
    └─ Creates git tag

Shutdown Doc Agent
TeamDelete

FINAL: Phase H
├─ Spawn GO:Verifier (subagent)
└─ Output: FINAL_VERIFICATION.md + PROJECT_REPORT.md
```

---

## Auto-Validation (Phase C)

Instead of human review, Boss validates automatically:

```markdown
## Auto-Validation Checklist

### Structure (must pass)
- [ ] Every task has numbered "Done When" criteria
- [ ] Every smoke test is a runnable command (not prose)
- [ ] File ownership table exists with no parallel conflicts
- [ ] Wave dependencies are acyclic

### Quality (warnings only)
- [ ] At least one smoke test per task
- [ ] Risk assessment has mitigations
- [ ] Skills assigned appropriately

If structure checks fail → ABORT with specific errors
If quality checks fail → WARN and proceed
```

---

## Autonomous Failure Handling

```
On task failure:
    1. Worker invokes systematic-debugging (mandatory)
    2. Worker returns failure report with:
       - Error message
       - Root cause (identified or suspected)
       - Suggested fix
       - Confidence level (0-100%)

    3. Boss evaluates:
       IF confidence >= 80% AND fix is contained to task files:
           → Spawn retry worker with fix context
           → Record in PHASE_N_PLAN.md: "Auto-retry #N"
           → Max 2 retries

       IF confidence < 80% OR 3rd failure:
           → ABORT phase
           → Report full context to user
           → User decides: fix manually or abandon

    4. On successful retry:
       → Record in PHASE_N_PLAN.md: "🟢 Auto-recovered"
       → Continue execution
```

---

## Beads in Autonomous Mode

Even without human checkpoints, capture decisions:

| Type | When Created | Example |
|------|--------------|---------|
| DD-NNN (Decision) | Architectural choice made | "Used SQLite for simplicity" |
| DS-NNN (Discovery) | Non-obvious learning | "API has undocumented rate limit" |
| AS-NNN (Assumption) | Unvalidated bet | "Assumes max 1000 records" |
| FR-NNN (Friction) | Harder than expected | "Auth took 3 retries to fix" |
| PV-NNN (Pivot) | Direction change | "Switched from REST to GraphQL" |

Store in HANDOFF.md Beads section. Essential for post-build debugging.

---

## Git Strategy

```bash
# After each wave
git add [files from wave]
git commit -m "feat(phase-N-wM): [wave description]"

# After each phase
git tag v[version]-phase-N

# On abort
git tag v[version]-phase-N-aborted
```

---

## Commands

| Command | Purpose |
|---------|---------|
| `/go:auto` | Run full autonomous build (all phases) |
| `/go:auto N` | Run autonomous build for N phases |
| `/go:discover` | Pre-build discovery (unchanged) |
| `/go:preflight` | Environment validation (unchanged) |
| `/go:verify` | Final verification only (unchanged) |

---

## Agents

| Agent | File | Role |
|-------|------|------|
| Phase Coordinator | `agents/go-phase-coordinator.md` | Handles phases A-F as a teammate, spawns workers as subagents |
| Doc Agent / Scribe | `agents/go-doc-agent.md` | Writes decisions, patterns, and errors to Engram as persistent teammate |

---

## Key Differences from GO-Build

| Aspect | GO-Build | GO-Auto |
|--------|----------|---------|
| Phase C | Human approves plan | Auto-validate and proceed |
| Failures | Boss decides retry/skip/abort | Auto-retry (max 2) then abort |
| RESTART_PROMPT | Created each phase | Not created |
| HANDOFF_PHASE_N | Created each phase | Not created |
| START_PROMPT | Created by preflight | Not created |
| Session breaks | Expected | None (continuous) |
| HANDOFF.md | Full session context | Beads only (simplified) |

---

## When to Use GO-Auto vs GO-Build

**Use GO-Auto when:**
- You have a solid ROADMAP and discovery
- You trust the plan structure
- You want hands-off execution
- Single session, no breaks needed

**Use GO-Build when:**
- Complex project needing human judgment
- Uncertain requirements
- Multi-day builds with session breaks
- Need human approval at checkpoints

---

## Abort Conditions

GO-Auto will abort and report if:

1. **Plan validation fails** — File conflicts, missing smoke tests
2. **3 consecutive failures** on same task
3. **Review blocked** after 2 fix attempts
4. **Dependency cycle** detected in wave structure
5. **Critical security issue** found in review

On abort, full context is preserved in PHASE_N_PLAN.md for manual recovery.

---

## Templates

Essential templates in `templates/`:
- `PHASE_PLAN_TEMPLATE.md` — Plan structure
- `BUILD_GUIDE_TEMPLATE.md` — Environment inventory
- `HANDOFF_TEMPLATE.md` — Beads and decisions (simplified)
- `FINAL_VERIFICATION_TEMPLATE.md` — E2E results
- `PROJECT_REPORT_TEMPLATE.md` — Build analysis

---

## Protocols

Reference during execution:
- `sections/FAILURE_PROTOCOL.md` — Autonomous retry rules
- `sections/ISSUE_RESOLUTION_PROTOCOL.md` — Fix vs defer
- `sections/SKILL_DECISION_PROTOCOL.md` — Mandatory skills
- `sections/AGENT_NOTES_FORMAT.md` — Note structure
