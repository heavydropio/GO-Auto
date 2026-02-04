# Skill Decision Protocol

## Available Skills by Phase

| Phase | Recommended Skills | Purpose |
|-------|-------------------|---------|
| A (Review) | brainstorming | Explore requirements if fuzzy |
| B (Planning) | writing-plans | Ensure complete plans |
| D (Execution) | test-driven-development | Write tests before code |
| D (Failure) | systematic-debugging | Root cause investigation |
| F (Review) | verification-before-completion | Evidence before claims |
| F (Review) | requesting-code-review | Structured review output |

## Mandatory Skills (No Opt-Out)

These skills MUST be invoked — no justification can skip them:

- **verification-before-completion** (Phase F) — Always required
- **systematic-debugging** (Failure Protocol) — Always required when fixing issues

## Configurable Skills

When Boss decides NOT to use a recommended skill, document in PHASE_X_PLAN.md:

### When Skipping a Skill

```markdown
#### 📋 Skill Decision: [skill-name] SKIPPED
> **Phase**: [phase letter] ([phase name])
> **Task**: [task number] - [task name]
> **Decision**: SKIP
> **Justification**: [Substantive reason — see Valid Skip Justifications]
> **Approved by**: Boss
> **Timestamp**: YYYY-MM-DD HH:MM
```

### When Applying a Skill

```markdown
#### 📋 Skill Decision: [skill-name] APPLIED
> **Phase**: [phase letter] ([phase name])
> **Task**: [task number] - [task name]
> **Decision**: APPLY
> **Outcome**: [What the skill produced — e.g., "3 tests written, all pass"]
> **Timestamp**: YYYY-MM-DD HH:MM
```

## Skill Decision Log

At end of PHASE_X_PLAN.md, maintain summary table:

| Task | Skill | Decision | Justification | Outcome |
|------|-------|----------|---------------|---------|
| 2.1 | TDD | Applied | — | 5 tests, all pass |
| 2.2 | TDD | Applied | — | 3 tests, all pass |
| 2.3 | TDD | Skipped | Config-only, no runtime code | N/A |
| 2.4 | TDD | Applied | — | 3 tests, all pass |
| 2.5 | brainstorming | Skipped | Requirements clear from spec | N/A |

## Valid Skip Justifications

| Skill | Valid Skip | Invalid Skip |
|-------|------------|--------------|
| test-driven-development | "Config/docs only, no executable code" | "Simple change" |
| test-driven-development | "Refactor with 100% existing coverage" | "Tests take too long" |
| test-driven-development | "Migration script, tested manually" | "I know it works" |
| brainstorming | "Requirements explicit in spec" | "Already know what to build" |
| brainstorming | "Single approach possible" | "Don't need to explore" |
| writing-plans | "Single-task phase, plan is trivial" | "Planning slows us down" |

## Phase-End Analysis

In Phase H (Final Verification), Boss reviews Skill Decision Log:

### 1. Pattern Check
Are certain skills being skipped repeatedly?
- If >50% skip rate → Evaluate if skill should be:
  - Made optional for this project type
  - Removed from recommendations
  - OR enforced more strictly

### 2. Outcome Correlation
Do skipped-skill tasks have more issues later?
- Track: Issues found in Phase F that originated from skipped-TDD tasks
- If correlation exists → Tighten enforcement

### 3. Justification Quality
Are justifications substantive or hand-wavy?
- "Didn't seem necessary" = **REJECT** (require skill application)
- "Config-only change, no runtime code modified" = **ACCEPT**

## Escalation

If Boss writes skip justifications frequently for the same skill:

- **3+ skips in one phase** → Pause and ask:
  "Should this skill be optional for this project?"

- **Pattern across phases** → Update project config:
  ```json
  {
    "skills": {
      "test-driven-development": "optional",
      "verification-before-completion": "mandatory"
    }
  }
  ```

## The "Justification Test"

Before skipping a skill, Boss asks:

> "If I have to write down why I'm skipping this, is my reason actually good?"

If you struggle to write the justification → **Apply the skill instead.**

The act of documenting prevents lazy shortcuts.
