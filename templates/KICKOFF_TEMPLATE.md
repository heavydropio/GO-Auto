# Kick-Off Plan: Phase [N] — [Phase Name]

**Date**: YYYY-MM-DD
**Phase**: [N] - [Phase Name]
**Status**: Kick-Off

---

## Build Rules

1. **All agents are Opus** — No exceptions
2. **Boss delegates everything** — Spin up subagents for all work, no matter how small
3. **Git checkpoints** — Commit after each wave with conventional format
4. **Source of truth** — PHASE_[N]_PLAN.md accumulates all notes, decisions, issues

---

## Phase A: Environment Review

Spin up a **Review Agent** to:
- Review Phase [N] scope from HANDOFF.md and HANDOFF_PHASE_[N].md
- **Surface existing beads from HANDOFF.md**:
  - Report any **Open Assumptions (AS-NNN)** that Phase [N] should validate
  - Report any **Unresolved Friction (FR-NNN)** that may affect this phase
  - Report any **Technical Debt (TD-NNN)** assigned to Phase [N]
- **If `.beads/` exists**: run `bd list`, review tracked issues and dependencies
- Inventory existing code, tests, and dependencies
- Review any reference implementations
- Verify Phase [N-1] tests pass ([expected count] expected)
- Identify blockers or missing prerequisites
- **Output**: Updated `BUILD_GUIDE_PHASE_[N].md` OR confirmation existing guide is ready

---

## Phase B: Build Planning

Spin up a **Build Planning Agent**:
- Use **Sequential Thinking** MCP for structured planning
- Reference `templates/PHASE_PLAN_TEMPLATE.md` for format
- **Output**: `PHASE_[N]_PLAN.md` containing:

### Required Plan Sections

| Section | Description |
|---------|-------------|
| Wave Structure | ASCII dependency graph showing task relationships |
| Task Breakdown | Each task with: description, files, dependencies, context, smoke tests, "Done When" |
| Parallelization Map | Table showing which tasks can run in parallel with justification |
| File Ownership Guarantee | Table proving no parallel tasks write to same files |
| Database Schema | Migration DDL if needed (may be empty) |
| Dependencies | pyproject.toml additions |
| Test Plan | New test files table with expected counts |
| Risk Assessment | Probability/impact/mitigation table |
| Verification Commands | Commands to run after each wave |
| Git Checkpoint Messages | Commit message for each wave |
| Skill Decision Log | Table for tracking skill usage (populated during execution) |
| Issues Log | Table for tracking issues (populated during execution) |

---

## Phase C: Plan Review (Boss)

Boss reviews plan using `sections/BOSS_REVIEW_CHECKLIST.md`:
- Approve, OR send back for revisions → then approve
- Validate parallel tasks truly have no dependencies
- Validate file ownership guarantees
- Validate skill assignments
- **Check in with [Human Name] before proceeding to Phase D**

---

## Phase D: Execution

Spin up **Worker Subagents** (by wave):
- Execute tasks according to the plan
- Parallelize all work within a wave
- Each agent must:
  - Apply assigned skills OR document skip with justification
  - Run smoke tests from the plan
  - Add notes to their task section in PHASE_[N]_PLAN.md
  - **Create beads for key moments** (see `templates/BEAD_TYPES_GUIDE.md`):
    - **DD-NNN (Decision)**: When choosing between alternatives
    - **DS-NNN (Discovery)**: When learning something non-obvious about the codebase
    - **FR-NNN (Friction)**: When something takes longer than expected
    - **AS-NNN (Assumption)**: When making a bet without evidence
    - **PV-NNN (Pivot)**: When changing direction from the plan
  - Document beads in the "Beads Created This Phase" section of PHASE_[N]_PLAN.md
  - Report failure if smoke tests fail (follow `sections/FAILURE_PROTOCOL.md`)
- **Git commit after each wave** with specified message

---

## Phase E: Code Shortening

Spin up **Shortening Agents**:
- Reduce code WITHOUT breaking functionality
- Must re-run smoke tests after changes
- Document changes in PHASE_[N]_PLAN.md
- Goal: Minimal lines, maximal clarity

---

## Phase F: Code Review

Spin up **Code Review Agents**:
- **Must invoke**: `verification-before-completion` skill
- Review code quality
- Security review (API keys, credentials, user input)
- Debug any issues found (using `systematic-debugging`)
- Run full test suite: `uv run pytest tests/ -v -m "not integration"`
- Document what/how/results in PHASE_[N]_PLAN.md
- Verify [existing count] + [target new] tests pass

---

## Phase G: Status Update

Report to [Human Name] with:
- What was built (components, files, test counts)
- Test results (total passing, any failures)
- Issues resolved vs deferred
- **Version bump to [new version]** in `src/[module]/__init__.py`
- **Git tag**: `v[new version]-phase[N]`
- HANDOFF.md updated with Phase [N] completion details:
  - Copy beads from PHASE_[N]_PLAN.md "Beads Created This Phase" to HANDOFF.md sections:
    - DD-NNN → "Decisions Made" section
    - AS-NNN → "Assumptions Made" section
    - DS-NNN → "Discoveries" section
    - PV-NNN → "Pivots" section
    - FR-NNN → "Issues Deferred" (if unresolved) or log in phase summary
- **If using Beads CLI**: `bd sync --flush-only` executed

---

## Phase H: Final Verification & Report

Spin up **Verification Agent**:

### Part 1: End-to-End Validation
- Run integration tests across all phases
- Test primary user journey end-to-end
- Document edge cases tested

### Part 2: Build Plan Analysis
- Generate skill usage report from all PHASE_X_PLAN.md files
- Generate issue tracking report
- Generate decision audit trail

### Part 3: Metrics & Lessons
- Compile completion metrics
- Document lessons learned

**Output**: `FINAL_VERIFICATION.md` + `PROJECT_REPORT.md`

---

## Final Checklist

- [ ] All tests pass ([existing] existing + [new] new)
- [ ] Version bumped to [version] in `src/[module]/__init__.py`
- [ ] HANDOFF.md updated with Phase [N] completion details
- [ ] **Beads aggregated**: All DD/DS/AS/PV/FR beads from PHASE_[N]_PLAN.md copied to HANDOFF.md
- [ ] Git tag `v[version]-phase[N]` created
- [ ] `bd sync --flush-only` run (if using Beads CLI)
- [ ] pyproject.toml updated with new dependencies (if any)
- [ ] PHASE_[N]_PLAN.md contains all agent notes, decisions, issues
- [ ] FINAL_VERIFICATION.md created
- [ ] PROJECT_REPORT.md created

---

## Artifacts to Produce

| Phase | Output |
|-------|--------|
| A | Validated BUILD_GUIDE_PHASE_[N].md (or confirmation) |
| B | `PHASE_[N]_PLAN.md` |
| C | Approved plan (or revision cycle) |
| D | Implementation + agent notes in plan |
| E | Shortened code + notes in plan |
| F | Reviewed code + notes in plan |
| G | Updated HANDOFF.md, git tag |
| H | `FINAL_VERIFICATION.md`, `PROJECT_REPORT.md` |

---

## Phase [N] Scope Reminder

### What We're Building

1. **[Component 1]** — [Purpose]
2. **[Component 2]** — [Purpose]
3. **[Component 3]** — [Purpose]

### Success Criteria

1. [Criterion 1]
2. [Criterion 2]
3. [Criterion 3]
4. All [existing] tests pass
5. [new]+ new tests

### Key Design Questions (for Review Agent)

1. [Question about approach]
2. [Question about integration]
3. [Question about edge cases]

---

## Notes

- Python [version], managed with [uv/pip]
- Use `uv run` for all Python commands
- Human contact: [Name] ([email])

---

**Ready to begin Phase A: Review Agent**
