# Agent Notes Format

All agents document their work directly in PHASE_X_PLAN.md under the relevant task section.

## Note Types

### 🔨 Worker Notes
Used by: Worker agents in Phase D

```markdown
#### 🔨 Worker Notes (agent-id, YYYY-MM-DD HH:MM)
> **Created**:
> - `src/module/file.py` — Main implementation (145 lines)
> - `tests/test_file.py` — Unit tests (12 tests)
>
> **Modified**:
> - `src/module/__init__.py` — Added exports
>
> **Decisions Made**:
> - Used composition over inheritance for adapter pattern
>   - Reason: Allows runtime swapping of backends
>   - Alternative considered: Abstract base class
>
> **Smoke Test**: PASSED
> ```
> $ uv run pytest tests/test_file.py -v
> 12 passed in 0.34s
> ```
```

### ✂️ Shortening Notes
Used by: Shortening agents in Phase E

```markdown
#### ✂️ Shortening Notes (agent-id, YYYY-MM-DD HH:MM)
> **Changes**:
> - `src/module/file.py`: 145 → 98 lines (-32%)
>   - Combined `_validate()` and `_transform()` into single method
>   - Removed redundant type checks (handled by pydantic)
>   - Simplified error handling with early returns
>
> **Tests After Shortening**: PASSED
> ```
> $ uv run pytest tests/ -v
> 736 passed in 12.4s
> ```
>
> **No Functional Changes**: Behavior identical, only structure improved
```

### 🔍 Review Notes
Used by: Code review agents in Phase F

```markdown
#### 🔍 Review Notes (agent-id, YYYY-MM-DD HH:MM)
> **Files Reviewed**:
> - `src/module/file.py` — Implementation
> - `tests/test_file.py` — Tests
>
> **Tests Run**:
> - Unit tests: 12 passed
> - Integration tests: 5 passed
> - Regression suite: 736 passed
>
> **Coverage**: 94% (target: 80%)
>
> **Security Review**:
> - [ ] No hardcoded credentials
> - [ ] User input sanitized
> - [ ] No SQL injection vectors
>
> **Issues Found**: None
>
> **Result**: ✅ APPROVED
```

### ⚠️ Issue Found
Used by: Any agent discovering a problem

```markdown
#### ⚠️ Issue Found (agent-id, YYYY-MM-DD HH:MM)
> **Issue**: Empty input causes crash in adapter.process()
> **Severity**: Medium (crashes but doesn't corrupt data)
> **Discovered During**: Smoke test for task 2.3
> **Reproduction**:
> ```python
> adapter.process(None)  # Raises TypeError
> ```
```

### ⚠️ Issue Fixed
Used by: Agent that resolved an issue

```markdown
#### ⚠️ Issue Fixed (agent-id, YYYY-MM-DD HH:MM)
> **Issue**: Empty input causes crash in adapter.process()
> **Root Cause**: No null check before calling .strip()
> **Fix**: Added guard clause at line 42
> ```python
> if not input_data:
>     return EmptyResult()
> ```
> **Test Added**: `test_adapter_empty_input()` in test_adapter.py
> **Verified**: Test passes, no regression
```

### ⚠️ Issue Deferred
Used by: Boss when deferring an issue

```markdown
#### ⚠️ Issue Deferred (Boss, YYYY-MM-DD HH:MM)
> **Issue**: Rate limiting not implemented
> **Why Can't Fix Now**: Requires Redis infrastructure (Phase 7)
> **Assigned Phase**: Phase 7
> **What Breaks If Never Fixed**: API vulnerable to abuse
> **Test To Write**: `test_rate_limit_exceeded()`
> **Bead Created**: bd-a3f8
```

### 📋 Skill Decision
Used by: Worker or Boss documenting skill usage

```markdown
#### 📋 Skill Decision: test-driven-development APPLIED
> **Task**: 2.4 - Add user validation
> **Decision**: APPLY
> **Outcome**: 3 tests written before implementation, all pass
> **Timestamp**: YYYY-MM-DD HH:MM
```

```markdown
#### 📋 Skill Decision: test-driven-development SKIPPED
> **Task**: 2.3 - Update config schema
> **Decision**: SKIP
> **Justification**: Config-only change (YAML schema). No runtime code modified.
> **Approved by**: Boss
> **Timestamp**: YYYY-MM-DD HH:MM
```

### ✅ Boss Approved
Used by: Boss after reviewing work

```markdown
#### ✅ Boss Approved (YYYY-MM-DD HH:MM)
> **Wave**: 2
> **Tasks Reviewed**: 2.1, 2.2, 2.3, 2.4
> **Status**: All smoke tests pass
> **Git Commit**: `feat(phase-1-w2): implement adapter and validation`
> **Proceeding to**: Wave 3
```

### 🔴 Task Failed
Used by: Worker reporting failure

```markdown
#### 🔴 Task Failed (agent-id, YYYY-MM-DD HH:MM)
> **Failed**: TypeError in process() — None has no attribute 'strip'
> **Investigation**: Used systematic-debugging skill
> **Root Cause**: Missing null check on input
> **Suggested Fix**: Add guard clause
> **Returning to Boss for decision**
```

### 🟢 Failure Resolved
Used by: Agent after fixing a failure

```markdown
#### 🔴 Failure → 🟢 Resolved (agent-id, YYYY-MM-DD HH:MM)
> **Original Failure**: TypeError in process()
> **Resolution**: Added guard clause at line 42
> **Test Added**: test_adapter_null_input()
> **Retry Attempt**: 1
> **Status**: RESOLVED — all tests pass
```

## Placement Rules

1. Notes go **under the task they relate to** in PHASE_X_PLAN.md
2. Notes are **appended** (never overwrite previous notes)
3. Multiple agents can add notes to same task (chronological order)
4. All notes include **agent-id and timestamp**

## Example Task Section After Execution

```markdown
### Task 2.3: Implement storage adapter

- **Description**: Create adapter connecting to SQLite backend
- **Files**: src/storage/adapter.py, tests/test_adapter.py
- **Done When**:
  1. Adapter connects to database
  2. CRUD operations work
  3. All tests pass

#### 🔨 Worker Notes (worker-2a, 2026-01-25 14:30)
> Created adapter.py (145 lines), test_adapter.py (12 tests)
> Smoke test: PASSED

#### 📋 Skill Decision: test-driven-development APPLIED
> 3 tests written before implementation, all pass

#### ⚠️ Issue Found (worker-2a, 2026-01-25 14:45)
> Empty input causes crash

#### ⚠️ Issue Fixed (worker-2a, 2026-01-25 14:52)
> Added guard clause, test added

#### ✂️ Shortening Notes (shortener-2a, 2026-01-25 15:10)
> Reduced 145 → 98 lines, tests still pass

#### 🔍 Review Notes (reviewer-2a, 2026-01-25 15:30)
> 12 tests pass, 94% coverage, no security issues
> Result: ✅ APPROVED
```
