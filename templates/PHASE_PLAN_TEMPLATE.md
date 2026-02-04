# PHASE [N]: [Phase Name]

**Date**: YYYY-MM-DD
**Status**: Planning | In Progress | Complete
**Version Target**: [version]

---

## Overview

[2-3 sentences describing what this phase accomplishes]

**Goal**: [Single sentence phase goal]

**Requirements Addressed**: [REQ-IDs if using traceability, or checklist items]

**Success Criteria**:
1. [Criterion 1]
2. [Criterion 2]
3. [Criterion 3]

---

## Dependency Graph

```
Wave 1: [description]
   ├── Task 1.1 ──┐
   ├── Task 1.2 ──┼──→ Wave 2
   └── Task 1.3 ──┘
                      ├── Task 2.1 ──┐
                      └── Task 2.2 ──┴──→ Wave 3
                                            └── Task 3.1
```

---

## Wave Structure

### Wave 1: [Wave Name]

#### Task 1.1: [Task Name]

- **Description**: [What to build, 2-3 sentences]
- **Files**:
  - Creates: `path/to/new_file.py`
  - Modifies: `path/to/existing.py`
- **Dependencies**: None (first wave)
- **Context Needed**: [Files to read for context]
- **Skills**:
  - [ ] test-driven-development
  - [ ] Other skills as needed
- **Smoke Tests**:
  ```bash
  uv run pytest tests/test_file.py -v
  uv run python -c "from module import Class; print('OK')"
  ```
- **Done When**:
  1. [Specific, verifiable criterion]
  2. [Specific, verifiable criterion]
  3. All tests pass

<!-- Agent notes will be added below during execution -->

---

#### Task 1.2: [Task Name]

- **Description**: [What to build]
- **Files**:
  - Creates: `path/to/file.py`
- **Dependencies**: None (parallel with 1.1)
- **Context Needed**: [Files to read]
- **Skills**:
  - [ ] test-driven-development
- **Smoke Tests**:
  ```bash
  [commands]
  ```
- **Done When**:
  1. [Criterion]
  2. [Criterion]

---

### Wave 2: [Wave Name]

#### Task 2.1: [Task Name]

- **Description**: [What to build]
- **Files**:
  - Creates: `path/to/file.py`
  - Modifies: `path/from/wave1.py`
- **Dependencies**: Wave 1 complete (uses outputs from 1.1, 1.2)
- **Context Needed**: [Files]
- **Skills**:
  - [ ] test-driven-development
- **Smoke Tests**:
  ```bash
  [commands]
  ```
- **Done When**:
  1. [Criterion]

---

## Parallelization Map

| Wave | Tasks | Parallel? | Justification |
|------|-------|-----------|---------------|
| 1 | 1.1, 1.2, 1.3 | Yes | Each creates independent files |
| 2 | 2.1, 2.2 | Yes | No shared writes |
| 3 | 3.1 | N/A | Single task |

---

## File Ownership Guarantee

| File | Owner Task | Access |
|------|-----------|--------|
| `src/module/file1.py` | 1.1 | Write |
| `src/module/file2.py` | 1.2 | Write |
| `src/module/__init__.py` | 1.3 | Write |
| `tests/test_file1.py` | 1.1 | Write |
| `src/core/types.py` | All | Read only |

**Conflict check**: No two parallel tasks write to the same file. ✅

---

## Test Plan

| Test File | Tasks Covered | Expected Tests |
|-----------|---------------|----------------|
| `tests/test_file1.py` | 1.1 | 10 |
| `tests/test_file2.py` | 1.2 | 8 |
| `tests/test_integration.py` | 2.1 | 5 |

**Target**: [N] new tests
**Existing**: [M] tests
**Total after phase**: [N+M] tests

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [Mitigation strategy] |
| [Risk 2] | Low/Med/High | Low/Med/High | [Mitigation strategy] |

---

## Git Checkpoints

| Wave | Commit Message |
|------|----------------|
| 1 | `feat(phase-N-w1): [description]` |
| 2 | `feat(phase-N-w2): [description]` |
| 3 | `feat(phase-N-w3): [description]` |
| Metadata | `docs(phase-N): update ROADMAP and STATE` |

---

## Verification Commands

After each wave, run:

```bash
# Wave 1 verification
uv run pytest tests/test_file1.py tests/test_file2.py -v

# Wave 2 verification
uv run pytest tests/test_integration.py -v

# Full regression
uv run pytest tests/ -v -m "not integration"
```

---

## Skill Decision Log

| Task | Skill | Decision | Justification | Outcome |
|------|-------|----------|---------------|---------|
| | | | | |

*(Populated during execution)*

---

## Issues Log

| ID | Description | Blocking? | Owner | Bead | Status |
|----|-------------|-----------|-------|------|--------|
| | | | | | |

*(Populated during execution)*

---

## Beads Created This Phase

Key moments that answer "Why?" for future agents. These aggregate to main HANDOFF.md at phase completion.

| ID | Type | Summary | Status |
|----|------|---------|--------|
| DD-NNN | Decision | [What was decided and why] | Active |
| AS-NNN | Assumption | [Bet made that could be wrong] | Open |
| DS-NNN | Discovery | [Non-obvious learning] | Confirmed |
| FR-NNN | Friction | [What was harder than expected] | Resolved/Open |
| PV-NNN | Pivot | [Direction change from plan] | Implemented |

*(Populated during execution. See BEAD_TYPES_GUIDE.md for guidance.)*

---

## Phase Completion Checklist

- [ ] All tasks complete with "Done When" verified
- [ ] All smoke tests pass
- [ ] All agent notes documented
- [ ] Skill decisions logged
- [ ] Issues resolved or tracked in Beads
- [ ] Git commits per wave complete
- [ ] Regression tests pass
- [ ] Ready for Phase G (Status Update)
