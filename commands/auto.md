---
description: Fully autonomous build execution. Runs all phases (A-H) continuously without human checkpoints.
arguments:
  - name: phases
    description: Number of phases to run (default: all from ROADMAP)
    required: false
---

# /go:auto [phases] — Autonomous Full Build

You are the **Boss** running a fully autonomous build using GO-Auto with a Teams-based architecture.

**Announce**: "I'm running an autonomous build using GO-Auto. All phases will execute continuously without human checkpoints."

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

## Determine Phase Count

```
if phases argument provided:
    run_phases = min(phases, total_phases_in_roadmap)
else:
    run_phases = total_phases_in_roadmap
```

## Initialize HANDOFF.md

If HANDOFF.md doesn't exist, create it:

```markdown
# HANDOFF.md

## Build Info
- **Started**: [timestamp]
- **Mode**: Autonomous (GO-Auto)
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

## Team Setup

Create the team and spawn the persistent Doc Agent before entering the build loop.

```
1. TeamCreate "go-auto-build"

2. Spawn Doc Agent as teammate:
   Task tool:
     subagent_type: "general-purpose"
     team_name: "go-auto-build"
     name: "doc-agent"
     prompt: [Content of agents/go-doc-agent.md]
             + "Project root: {project_root}"
             + "Project ID: {project_id}"
             + "Team name: go-auto-build"

3. Send initialization message to doc-agent:
   SendMessage:
     type: "message"
     recipient: "doc-agent"
     content: '{"type": "status_change", "status": "Build started", "reason": "Autonomous build initiated", "phase": 0, "health": "green"}'
     summary: "Build initialization"
```

Wait for acknowledgment from doc-agent before proceeding.

## Main Execution Loop

```
for phase_num in 1..run_phases:

    announce("Starting Phase {phase_num}")

    ## Send status update to Doc Agent
    SendMessage to "doc-agent":
        content: '{"type": "status_change", "status": "Phase {phase_num} starting", "reason": "Previous phase complete", "phase": {phase_num}, "health": "green"}'
        summary: "Phase {phase_num} starting"

    ## Spawn Phase Coordinator as teammate
    Task tool:
      subagent_type: "general-purpose"
      team_name: "go-auto-build"
      name: "phase-{phase_num}-coordinator"
      prompt: [Content of agents/go-phase-coordinator.md]
              + "Phase: {phase_num}"
              + "ROADMAP goals for this phase: {goals}"
              + "HANDOFF.md context: {handoff_content}"
              + "Doc Agent teammate name: doc-agent"
              + "Boss teammate name: [your name in team]"
              + "Team name: go-auto-build"

    ## Wait for completion message from coordinator
    The coordinator handles Phases A-F internally by spawning subagents.
    Wait for a SendMessage from "phase-{phase_num}-coordinator" with the
    phase completion or abort summary.

    ## If coordinator reports ABORT:
    if coordinator_message contains abort:
        execute Abort Protocol (see below)

    ## PHASE G: Status Update (Boss does this directly)
    1. Parse the coordinator's summary for beads, decisions, metrics
    2. Extract beads and append to HANDOFF.md Beads Log
    3. Update HANDOFF.md Git Log with commits from this phase
    4. Create git tag:
       git tag v{version}-phase-{phase_num}
    5. Commit status update:
       git add HANDOFF.md
       git commit -m "chore(phase-{phase_num}): complete"

    ## Send management decision to Doc Agent
    SendMessage to "doc-agent":
        content: '{"type": "management_decision", "decision": "Phase {phase_num} accepted, proceeding to next phase", "context": "{summary_from_coordinator}", "phase": {phase_num}}'
        summary: "Phase {phase_num} accepted"

    ## Record coordinator state
    SendMessage to "doc-agent":
        content: '{"type": "agent_state", "agent_name": "phase-{phase_num}-coordinator", "state": "done", "phase": {phase_num}}'
        summary: "Coordinator {phase_num} done"

    ## Send shutdown to coordinator (it is single-phase, no longer needed)
    SendMessage:
        type: "shutdown_request"
        recipient: "phase-{phase_num}-coordinator"
        content: "Phase {phase_num} complete, shutting down coordinator"

    announce("Phase {phase_num} complete")

## PHASE H: Final Verification (Boss does this directly)
spawn GO:Verifier as a subagent (NOT a teammate):
    Task tool:
      subagent_type: "general-purpose"
      prompt: [Content of agents/go-verifier.md]
              + "All PHASE_*_PLAN.md files"
              + "REQUIREMENTS.md (if exists)"
              + "Full test suite"

wait for FINAL_VERIFICATION.md and PROJECT_REPORT.md

if verification.status == VERIFIED:
    announce("Autonomous build complete. All verifications passed.")
else:
    announce("Build complete with issues. See FINAL_VERIFICATION.md")

## Teardown
1. Send final status to Doc Agent:
   SendMessage to "doc-agent":
       content: '{"type": "status_change", "status": "Build complete", "reason": "All phases and verification finished", "phase": {run_phases}, "health": "green|yellow"}'
       summary: "Build complete"

2. Wait for Doc Agent acknowledgment

3. Shut down Doc Agent:
   SendMessage:
       type: "shutdown_request"
       recipient: "doc-agent"
       content: "Build complete, shutting down doc agent"

4. Wait for shutdown_response from doc-agent

5. TeamDelete "go-auto-build"

announce("Autonomous build complete")
```

## Phase G: Status Update (Boss-Owned)

The Boss performs Phase G directly after each Phase Coordinator reports completion. No subagent is spawned.

```
1. Parse coordinator's completion message for:
   - Tasks completed / failed counts
   - Test counts
   - Auto-retry counts
   - Key decisions made
   - Issues found / fixed / escalated

2. Extract beads from PHASE_{phase_num}_PLAN.md:
   - Each completed task becomes a bead entry in HANDOFF.md

3. Append beads to HANDOFF.md Beads Log table

4. Update HANDOFF.md Git Log table with:
   - Phase number
   - Latest commit hash
   - Tag name

5. Create git tag: v{version}-phase-{phase_num}

6. Commit: "chore(phase-{phase_num}): complete"
```

**NOT created** (unlike GO-Build):
- ~~RESTART_PROMPT_PHASE_{N+1}.md~~
- ~~HANDOFF_PHASE_{N}.md~~

## Phase H: Final Verification (Boss-Owned)

After all phases complete, the Boss spawns GO:Verifier as a **subagent** (not a teammate) to run end-to-end validation.

```
spawn GO:Verifier as subagent:
    Task tool:
      subagent_type: "general-purpose"
      prompt: [Content of agents/go-verifier.md]
              + "All PHASE_*_PLAN.md files"
              + "REQUIREMENTS.md (if exists)"
              + "Full test suite"

wait for:
    - FINAL_VERIFICATION.md
    - PROJECT_REPORT.md

if verification.status == VERIFIED:
    announce("Autonomous build complete. All verifications passed.")
else:
    announce("Build complete with issues. See FINAL_VERIFICATION.md")
```

The Verifier does not join the team. It runs, produces its reports, and exits.

## Auto-Validation

Plan validation (Phase C) is handled internally by the Phase Coordinator. The coordinator checks:

- Every task has numbered Done When criteria
- Smoke tests are runnable bash commands
- No parallel write conflicts in the File Ownership Guarantee table
- Wave dependencies are acyclic (Wave N+1 depends only on Wave N or earlier)
- Every task has all required sections (Description, Files, Dependencies, Context, Smoke Tests, Done When)

If validation fails, the coordinator attempts replanning (max 2 attempts). If replanning fails, the coordinator aborts and reports to the Boss with the specific validation failures. The Boss then executes the Abort Protocol.

## Abort Protocol

On any ABORT (whether from a Phase Coordinator report or a Boss-level failure):

```markdown
## Autonomous Build Aborted

**Phase**: {phase_num}
**Stage**: {A|B|C|D|E|F|G}
**Reason**: {reason}
**Source**: {coordinator report | boss detection}

### Context
{full error context from coordinator's abort message}

### Files Created
{list of files created before abort}

### Recovery Options
1. Fix the issue manually and run `/go:auto` from Phase {phase_num}
2. Switch to `/go:kickoff {phase_num}` for human-guided execution
3. Review PHASE_{phase_num}_PLAN.md for details

### Git State
Last commit: {commit_hash}
Tag: v{version}-phase-{phase_num}-aborted
```

On abort:
1. Create abort tag: `git tag v{version}-phase-{phase_num}-aborted`
2. Send abort status to Doc Agent
3. Shut down Doc Agent (shutdown_request)
4. Shut down any active Phase Coordinator (shutdown_request)
5. TeamDelete "go-auto-build"
6. Report to user

## Git Strategy

- **Wave commits**: Created by Phase Coordinators during Phase D (one commit per wave)
- **Shortening commits**: Created by Phase Coordinators during Phase E
- **Review fix commits**: Created by Phase Coordinators during Phase F
- **Phase tags**: Created by Boss during Phase G (`v{version}-phase-{phase_num}`)
- **Status commits**: Created by Boss during Phase G (`chore(phase-N): complete`)
- **Abort tags**: Created by Boss on abort (`v{version}-phase-{phase_num}-aborted`)
- **Final tag**: Created by Boss after Phase H (`v{version}-final`)

The Boss never commits code. Coordinators never create tags.

## Output Summary

On successful completion:

```markdown
## Autonomous Build Complete

**Phases**: {N} completed
**Duration**: {time}
**Mode**: Fully autonomous (Teams-based)
**Team**: go-auto-build

### Architecture
- Boss: orchestrated {N} phases
- Doc Agent: recorded build knowledge to Engram
- Phase Coordinators: {N} spawned (one per phase)
- Workers: spawned as subagents by coordinators

### Per-Phase Summary
| Phase | Tasks | Tests | Auto-Retries | Status |
|-------|-------|-------|--------------|--------|
| 1 | 5 | 23 | 0 | PASS |
| 2 | 8 | 41 | 1 | PASS |
| 3 | 4 | 18 | 0 | PASS |

### Artifacts Created
- PHASE_1_PLAN.md ... PHASE_{N}_PLAN.md
- BUILD_GUIDE_PHASE_1.md ... BUILD_GUIDE_PHASE_{N}.md
- HANDOFF.md (updated with all beads)
- FINAL_VERIFICATION.md
- PROJECT_REPORT.md

### Git Tags
- v{version}-phase-1
- v{version}-phase-2
- ...
- v{version}-final

### Next Steps
1. Review FINAL_VERIFICATION.md for any issues
2. Review PROJECT_REPORT.md for build analysis
3. Run `/go:verify` if additional verification needed
```
