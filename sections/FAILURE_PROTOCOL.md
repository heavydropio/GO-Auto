# Failure Protocol (Autonomous Mode)

This protocol defines how GO-Auto handles failures during autonomous execution.

## Core Principle

**Never guess at fixes.** Always use systematic-debugging skill first, then decide based on confidence.

---

## When a Task Fails

### Step 1: STOP

Do not proceed to next task. Do not attempt quick fixes.

### Step 2: Invoke Systematic Debugging (Mandatory)

```
invoke systematic-debugging skill:
    - Gather error output
    - Check logs
    - Verify preconditions
    - Form hypotheses
    - Test hypotheses
    - Identify root cause
```

### Step 3: Generate Failure Report

Worker must return structured failure report:

```markdown
🔴 Task Failed (agent-id, timestamp)
> **Task**: [number] - [name]
> **Error**: [exact error message]
> **Investigation**:
>   - Hypothesis 1: [tested, result]
>   - Hypothesis 2: [tested, result]
> **Root Cause**: [identified cause]
> **Suggested Fix**: [specific fix]
> **Confidence**: [0-100%]
> **Fix Scope**: [contained to task files | requires other files]
```

### Step 4: Autonomous Retry Decision

Boss evaluates the failure report:

```
IF confidence >= 80% AND fix_scope == "contained to task files":
    → Proceed to auto-retry

IF confidence >= 80% AND fix_scope == "requires other files":
    → ABORT: "Fix requires files outside task scope"

IF confidence < 80%:
    → ABORT: "Low confidence fix needs human review"
```

---

## Auto-Retry Protocol

### Retry Limits

| Scenario | Max Retries | After Max |
|----------|-------------|-----------|
| Task failure | 2 | Abort phase |
| Review BLOCKED | 2 | Abort phase |
| Same error repeated | 1 | Abort immediately |

### Retry Execution

```python
def auto_retry(failure_report, attempt_number):
    # Spawn new worker with fix context
    worker = spawn GO:Builder with:
        - original task spec
        - "RETRY CONTEXT":
            - Previous error: {failure_report.error}
            - Root cause: {failure_report.root_cause}
            - Suggested fix: {failure_report.suggested_fix}
            - Attempt: {attempt_number} of 2
        - "Apply the suggested fix, then run all smoke tests"

    result = wait(worker)

    if result.status == SUCCESS:
        record_in_plan("🟢 Auto-recovered (attempt {attempt_number})")
        return SUCCESS

    if result.status == FAILED:
        if attempt_number < 2:
            return auto_retry(result.failure_report, attempt_number + 1)
        else:
            return ABORT
```

### Retry Documentation

Record all retry attempts in PHASE_N_PLAN.md:

```markdown
#### Auto-Retry Log

| Task | Attempt | Error | Fix Applied | Result |
|------|---------|-------|-------------|--------|
| 2.3 | 1 | TypeError | Added null check | ❌ Still failing |
| 2.3 | 2 | TypeError | Refactored input validation | ✅ Recovered |
```

---

## Abort Conditions

GO-Auto aborts immediately (no retry) when:

1. **Confidence < 80%** — Fix is uncertain, needs human judgment
2. **Fix requires other files** — Would violate file ownership
3. **Same error 3 times** — Pattern indicates deeper issue
4. **Security issue found** — Cannot auto-fix security problems
5. **Dependency missing** — Prerequisite from earlier phase not met
6. **Circular dependency** — Wave structure is broken

---

## Abort Protocol

When aborting:

```markdown
## 🔴 Autonomous Build Aborted

**Phase**: {N}
**Task**: {task_id} - {task_name}
**Reason**: {abort_reason}

### Failure Details
```
{full error output}
```

### Investigation Results
{systematic-debugging findings}

### Suggested Fix
{suggested_fix with confidence level}

### Why Auto-Retry Failed/Skipped
{explanation}

### Recovery Options
1. **Manual fix**: Apply the suggested fix, then run `/go:auto {N}` to resume
2. **Human-guided**: Switch to `/go:kickoff {N}` for human checkpoint
3. **Skip task**: Remove task from plan and re-run (if non-critical)

### Files to Review
- PHASE_{N}_PLAN.md (execution log)
- {list of files touched before failure}

### Git State
- Last successful commit: {hash}
- Abort tag: v{version}-phase-{N}-aborted
```

Create git tag: `git tag v{version}-phase-{N}-aborted -m "Aborted: {reason}"`

---

## Failure Categories

### Category A: Recoverable (Auto-Retry)

- Null pointer / undefined access → Add guard clause
- Missing import → Add import
- Type mismatch → Fix type annotation
- Test assertion wrong → Fix expected value
- File not found → Create file or fix path

**Confidence typically 80-95%**

### Category B: Investigate (May Retry)

- Logic error → Depends on complexity
- Integration failure → Check dependencies
- Race condition → Needs careful fix
- Performance issue → May need redesign

**Confidence typically 50-80%**

### Category C: Human Required (No Retry)

- Architecture problem → Needs design decision
- Security vulnerability → Needs security review
- External API issue → May need vendor contact
- Requirement ambiguity → Needs clarification
- Dependency conflict → Needs resolution strategy

**Confidence typically < 50%**

---

## Parallel Failure Handling

When multiple tasks fail in the same wave:

```
failures = collect_all_failures(wave)

# Check for common cause
common_causes = find_common_causes(failures)

if common_causes:
    # Single underlying issue
    ABORT("Multiple failures with common cause: {cause}")

else:
    # Independent failures
    for failure in failures:
        retry_result = auto_retry(failure)
        if retry_result == ABORT:
            ABORT("Task {failure.task_id} unrecoverable")

    # If all recovered, continue
    continue_to_next_wave()
```

---

## Escalation Thresholds

| Metric | Threshold | Action |
|--------|-----------|--------|
| Total retries in phase | > 5 | Warn, continue |
| Total retries in phase | > 10 | Abort phase |
| Consecutive task failures | > 2 | Abort wave |
| Same file failing | > 2 | Abort, suggest redesign |
| Review cycles | > 2 | Abort phase |

---

## Documentation Requirements

### Minimum (Always Required)

- Error message (exact)
- Root cause (identified or suspected)
- Fix applied (if retry succeeded)
- Confidence level

### Full (For Abort)

- All hypotheses tested
- All retry attempts with results
- Suggested manual fix
- Files touched before failure
- Git state (last good commit)

---

## Recovery After Abort

After manual fix, user can resume:

```bash
# Option 1: Resume autonomous from current phase
/go:auto --from-phase {N}

# Option 2: Run single phase with human checkpoint
/go:kickoff {N}

# Option 3: Skip to next phase (if current is non-critical)
/go:auto --from-phase {N+1}
```

---

## Friction Beads

When auto-retry succeeds, create a Friction bead:

```markdown
FR-{NNN}: Auto-retry required for {task}
- Phase: {N}
- Attempts: {count}
- Root cause: {cause}
- Resolution: {what fixed it}
- Pattern: {if this suggests larger issue}
```

These help identify recurring problems for future builds.
