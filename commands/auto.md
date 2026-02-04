---
description: Fully autonomous build execution. Runs all phases (A-H) continuously without human checkpoints.
arguments:
  - name: phases
    description: Number of phases to run (default: all from ROADMAP)
    required: false
---

# /go:auto [phases] — Autonomous Full Build

You are the **Boss** running a fully autonomous build using GO-Auto.

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

## Main Execution Loop

```
for phase_num in 1..run_phases:

    announce("Starting Phase {phase_num}")

    ## PHASE A: Environment Review
    spawn GO:Prebuild Planner with:
        - phase_num
        - ROADMAP.md context
        - HANDOFF.md (if exists)

    wait for BUILD_GUIDE_PHASE_{phase_num}.md

    ## PHASE B: Build Planning
    spawn GO:Build Planner with:
        - phase_num
        - BUILD_GUIDE_PHASE_{phase_num}.md
        - ROADMAP.md phase goals

    wait for PHASE_{phase_num}_PLAN.md

    ## PHASE C: Auto-Validation
    validate_result = auto_validate_plan(PHASE_{phase_num}_PLAN.md)

    if validate_result.errors:
        ABORT("Plan validation failed", validate_result.errors)

    if validate_result.warnings:
        log_warnings(validate_result.warnings)

    ## PHASE D: Execution
    execute_plan_with_auto_retry(PHASE_{phase_num}_PLAN.md)

    ## PHASE E: Code Shortening
    spawn GO:Refactor agents for major files
    collect shortening notes

    ## PHASE F: Code Review
    review_result = execute_review_with_auto_retry()

    if review_result == BLOCKED_AFTER_RETRIES:
        ABORT("Review blocked after max retries", review_context)

    ## PHASE G: Status Update (Lite)
    update_handoff_beads(phase_num)
    git_tag("v{version}-phase-{phase_num}")

    announce("Phase {phase_num} complete")

## PHASE H: Final Verification
spawn GO:Verifier
wait for FINAL_VERIFICATION.md and PROJECT_REPORT.md

announce("Autonomous build complete")
```

## Phase A: Environment Review

Spawn a Task agent:
```
subagent_type: "general-purpose"
prompt: [Content of agents/go-prebuild-planner.md]
         + "Phase: {phase_num}"
         + "ROADMAP goals for this phase: {goals}"
         + "HANDOFF.md context: {handoff_beads}"
```

Wait for `BUILD_GUIDE_PHASE_{phase_num}.md` to be created.

## Phase B: Build Planning

Spawn a Task agent:
```
subagent_type: "general-purpose"
prompt: [Content of agents/go-build-planner.md]
         + "Phase: {phase_num}"
         + "BUILD_GUIDE: {build_guide_content}"
```

Wait for `PHASE_{phase_num}_PLAN.md` to be created.

## Phase C: Auto-Validation

**NO HUMAN CHECKPOINT.** Instead, validate programmatically:

```python
def auto_validate_plan(plan_path):
    errors = []
    warnings = []

    plan = read_plan(plan_path)

    # MUST PASS: Structure checks
    for task in plan.tasks:
        if not task.done_when or not is_numbered_list(task.done_when):
            errors.append(f"Task {task.id}: Missing numbered Done When criteria")

        if not task.smoke_tests or not all(is_runnable_command(t) for t in task.smoke_tests):
            errors.append(f"Task {task.id}: Smoke tests must be runnable commands")

    if not plan.file_ownership_table:
        errors.append("Missing File Ownership Guarantee table")
    else:
        conflicts = find_parallel_write_conflicts(plan.file_ownership_table)
        if conflicts:
            errors.append(f"Parallel write conflicts: {conflicts}")

    # WARNINGS: Quality checks
    if not plan.risk_assessment:
        warnings.append("No risk assessment provided")

    if not plan.skills_per_task:
        warnings.append("Skills not assigned to tasks")

    return ValidationResult(errors=errors, warnings=warnings)
```

If errors exist → ABORT with specific error messages.
If only warnings → Log warnings and PROCEED.

Add validation note to plan:
```markdown
> ✅ **Auto-validated [timestamp]**
> Errors: 0 | Warnings: [N]
> Proceeding to execution
```

## Phase D: Execution with Auto-Retry

For each wave in the plan:

```
for wave in plan.waves:
    # Spawn all tasks in parallel
    workers = []
    for task in wave.tasks:
        worker = spawn GO:Builder with:
            - task spec from plan
            - context files
            - skill requirements
        workers.append(worker)

    # Collect results
    results = wait_all(workers)

    # Handle failures
    for result in results:
        if result.status == FAILED:
            retry_result = auto_retry_task(result, max_attempts=2)
            if retry_result.status == FAILED:
                ABORT("Task failed after max retries", retry_result)

    # Git checkpoint
    git_add(wave.files)
    git_commit(wave.commit_message)

    # Update plan with notes
    append_agent_notes(plan, results)
```

### Auto-Retry Logic

```python
def auto_retry_task(failure, max_attempts):
    for attempt in range(1, max_attempts + 1):
        if failure.confidence < 80:
            return ABORT("Low confidence fix, needs human review")

        # Spawn retry worker with fix context
        retry_worker = spawn GO:Builder with:
            - original task spec
            - failure.suggested_fix
            - failure.root_cause
            - "This is retry attempt {attempt}"

        result = wait(retry_worker)

        if result.status == SUCCESS:
            log(f"🟢 Auto-recovered on attempt {attempt}")
            return result

        failure = result  # Update for next iteration

    return FAILED_AFTER_RETRIES
```

## Phase E: Code Shortening

```
major_files = identify_major_files(phase_num)

for file in major_files:
    spawn GO:Refactor with:
        - file path
        - current tests
        - "Reduce code without changing behavior"

collect shortening notes
append to PHASE_{phase_num}_PLAN.md
```

## Phase F: Code Review with Auto-Retry

```
# Spawn reviewers in parallel
code_reviewer = spawn GO:Code Reviewer
security_reviewer = spawn GO:Security Reviewer

code_result = wait(code_reviewer)
security_result = wait(security_reviewer)

if both APPROVED:
    proceed to Phase G

if any BLOCKED:
    for issue in blocked_issues:
        fix_result = auto_fix_issue(issue, max_attempts=2)
        if fix_result == STILL_BLOCKED:
            ABORT("Review issue unfixable", issue)

    # Re-run review
    repeat Phase F (max 2 full cycles)
```

## Phase G: Status Update (Lite)

**Simplified for autonomous mode** — no RESTART_PROMPT needed.

```
1. Extract beads from PHASE_{phase_num}_PLAN.md
2. Append to HANDOFF.md Beads Log
3. Update HANDOFF.md Git Log
4. Create git tag: v{version}-phase-{phase_num}
5. Commit: "chore(phase-{phase_num}): complete"
```

**NOT created** (unlike GO-Build):
- ~~RESTART_PROMPT_PHASE_{N+1}.md~~
- ~~HANDOFF_PHASE_{N}.md~~

## Phase H: Final Verification

After all phases complete:

```
spawn GO:Verifier with:
    - All PHASE_*_PLAN.md files
    - REQUIREMENTS.md (if exists)
    - Full test suite

wait for:
    - FINAL_VERIFICATION.md
    - PROJECT_REPORT.md

if verification.status == VERIFIED:
    announce("✅ Autonomous build complete. All verifications passed.")
else:
    announce("⚠️ Build complete with issues. See FINAL_VERIFICATION.md")
```

## Abort Protocol

On any ABORT:

```markdown
## 🔴 Autonomous Build Aborted

**Phase**: {phase_num}
**Stage**: {A|B|C|D|E|F|G}
**Reason**: {reason}

### Context
{full error context}

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

Create abort tag: `git tag v{version}-phase-{phase_num}-aborted`

## Output Summary

On successful completion:

```markdown
## ✅ Autonomous Build Complete

**Phases**: {N} completed
**Duration**: {time}
**Mode**: Fully autonomous

### Per-Phase Summary
| Phase | Tasks | Tests | Auto-Retries | Status |
|-------|-------|-------|--------------|--------|
| 1 | 5 | 23 | 0 | ✅ |
| 2 | 8 | 41 | 1 | ✅ |
| 3 | 4 | 18 | 0 | ✅ |

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
