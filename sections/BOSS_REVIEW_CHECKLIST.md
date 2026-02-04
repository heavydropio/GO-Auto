# Boss Review Checklist

Use this checklist in Phase C (Plan Review) before approving execution.

## Plan Completeness

### Task Specification
- [ ] Every task has a clear **Description** (what to build)
- [ ] Every task lists **Files** (creates/modifies)
- [ ] Every task has **Dependencies** (wave requirements)
- [ ] Every task specifies **Context Needed** (what to read)
- [ ] Every task has **Smoke Tests** (runnable commands)
- [ ] Every task has numbered **"Done When"** criteria

### Wave Structure
- [ ] Tasks grouped into waves with clear boundaries
- [ ] Wave dependencies are accurate (no hidden dependencies)
- [ ] Estimated parallelization is realistic

### File Ownership Guarantee
- [ ] No two parallel tasks write to the same file
- [ ] File ownership table is complete
- [ ] Shared reads are acceptable (only writes conflict)

## Quality Gates

### Smoke Tests
- [ ] Smoke tests are actual runnable commands (not descriptions)
- [ ] Each smoke test verifies at least one "Done When" criterion
- [ ] Test commands use correct paths and syntax

### Skill Assignments
- [ ] Tasks specify which skills to apply
- [ ] Mandatory skills (verification, debugging) are not marked optional
- [ ] Justification provided for any pre-planned skill skips

## Risk Assessment

### Dependencies
- [ ] External dependencies identified (APIs, packages)
- [ ] pyproject.toml additions specified
- [ ] No undeclared dependencies between tasks

### Blockers
- [ ] Potential blockers identified
- [ ] Mitigation strategies documented
- [ ] Fallback approaches for high-risk tasks

## Verification

### Test Plan
- [ ] New test files listed with expected counts
- [ ] Regression test strategy specified
- [ ] Target test count is reasonable (not inflated)

### Git Strategy
- [ ] Commit messages specified per wave
- [ ] Messages use conventional format
- [ ] No "git add ." (explicit file staging)

## Common Issues to Catch

### Parallel Task Problems
- [ ] Are there implicit dependencies between "parallel" tasks?
- [ ] Do parallel tasks share any data structures?
- [ ] Could race conditions occur?

### Specification Gaps
- [ ] Are "Done When" criteria actually verifiable?
- [ ] Do smoke tests match the criteria?
- [ ] Is there ambiguity in task descriptions?

### Missing Elements
- [ ] Is there a rollback path if Wave N fails?
- [ ] Are error handling requirements specified?
- [ ] Are edge cases identified?

## Approval Decision

### Approve
- [ ] All checklist items pass
- [ ] Plan is ready for execution
- [ ] Proceed to Phase D

### Revise
- [ ] Document specific issues found
- [ ] Return to Planning Agent with revision requests
- [ ] Re-review after revisions

### Escalate
- [ ] Fundamental issues require human input
- [ ] Document concerns for human review
- [ ] Wait for human decision before proceeding

## Human Checkpoint

**Before Phase D**: Present plan summary to human

```markdown
## Plan Ready for Approval

**Phase**: [N] - [Name]
**Tasks**: [count]
**Waves**: [count]
**Estimated Tests**: [count]
**Key Decisions**: [list any significant choices]

**Risks Identified**:
- [risk 1]
- [risk 2]

**Ready to execute?**
```

Wait for human confirmation before proceeding to Phase D.
