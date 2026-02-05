# Bead Types for Key Moments

## Purpose

Track items that answer "Why?" questions future developers will ask. When Agent B arrives, they shouldn't have to re-discover rationale, friction, or assumptions. Beads capture the reasoning that gets lost between context windows.

**Target audience**: The next agent (or human) who needs to understand not just what was built, but why it was built this way.

---

## When to Create Beads

### Decisions (type=decision)

**When to create**: Any choice between alternatives that affects architecture, API design, or implementation approach.

**What to include**:
- What was decided
- What alternatives were considered
- Why this choice over others
- What it impacts

**Example**:
```bash
bd create "DD-001: Use dataclasses over Pydantic" \
  -t decision \
  -p 1 \
  --body "Decision: Use standard dataclasses with __post_init__ validation instead of Pydantic.

Alternatives considered:
1. Pydantic - more validation features but adds dependency
2. attrs - lightweight but different pattern from existing code
3. TypedDict - no runtime validation

Rationale: Matches existing Engram patterns in core/types.py. No new dependencies. __post_init__ provides sufficient validation.

Impact: All content structures use dataclasses. Validation happens at construction time."
```

---

### Discoveries (type=discovery)

**When to create**: Learning something non-obvious about the codebase, tools, or domain that affects future work.

**What to include**:
- What was discovered
- How it was discovered
- Why it matters
- What to do differently

**Example**:
```bash
bd create "DS-001: Episode.content stores dual format" \
  -t discovery \
  -p 2 \
  --body "Discovery: Episode.content field stores both JSON string and dict together.

Format: {'full': json_str, 'handoff': dict}

How discovered: Reading existing episode creation code in engram/core/episode.py

Impact: Handoff content helpers must maintain this dual format. Cannot store just dict or just string."
```

---

### Friction (type=friction)

**When to create**: Something took significantly longer than expected, or required multiple attempts to get right.

**What to include**:
- What was difficult
- Why it was difficult (root cause if known)
- How it was resolved (or current status)
- What would have helped

**Example**:
```bash
bd create "FR-001: Test isolation with SqliteStore" \
  -t friction \
  -p 2 \
  --body "Friction: Tests were interfering with each other via shared database state.

Root cause: SqliteStore uses singleton pattern. Each test wasn't getting clean state.

Resolution: Added fixture that creates fresh in-memory store per test.

What would have helped: Documentation on SqliteStore lifecycle. Flag in existing test patterns.

Time impact: ~2 hours debugging test flakiness."
```

---

### Pivots (type=pivot)

**When to create**: Original plan changed direction based on new information or constraints.

**What to include**:
- Original plan
- What changed
- Why (the trigger)
- New direction

**Example**:
```bash
bd create "PV-001: Manual handoffs instead of automatic" \
  -t pivot \
  -p 1 \
  --body "Pivot: Originally planned automatic context threshold monitoring.

Original plan: Monitor context usage, trigger handoff at 70%, complete at 85%.

Trigger: No existing infrastructure for context percentage tracking. Would require custom model wrapper.

New direction: Manual handoffs via CLI for MVP. Automatic triggering deferred to future milestone.

Impact: Simpler implementation, but requires user awareness of context limits."
```

---

### Assumptions (type=assumption)

**When to create**: Making a bet on something unvalidated that could break if wrong.

**What to include**:
- The assumption
- Why you're making it
- What breaks if wrong
- How to validate (if applicable)

**Example**:
```bash
bd create "AS-001: 200 tokens sufficient for tacit message" \
  -t assumption \
  -p 2 \
  --body "Assumption: ~200 tokens is enough for tacit messages.

Basis: Based on handoff template examples showing 2-3 sentences typically sufficient.

Risk if wrong: Critical context lost in handoff. Agent B misses important intuitions.

How to validate: Track actual tacit message lengths in Phase 6 real-world testing.

Status: Validated in Phase 6 - 200 tokens proved sufficient for all test handoffs."
```

---

### UI Design Specification (type=ui-design-spec)

**When to create**: Entity, API, or workflow changes that impact existing UI screens.

**What to include**:
- What changed (entity field, API endpoint, workflow step)
- Impact type (entity_change, new_endpoint, api_shape_change, enum_change, workflow_change)
- Which screens are affected
- What the UI needs to accommodate

**Example**:
```bash
bd create "UI-DS-001: Filing.archived field added" \
  -t ui-design-spec \
  -p 2 \
  --body "Impact: New boolean field 'archived' added to Filing entity.

Type: entity_change
Entity: Filing
Field: archived (boolean)

Screens Affected:
- filing_list: Needs filter toggle and column display
- filing_detail: Needs archived status badge

Source: Phase 2 - Core Data Layer"
```

---

### UI Design Decision (type=ui-design-decision)

**When to create**: Design choices for UI that affect user experience or component architecture.

**What to include**:
- What was decided
- Alternatives considered
- Why this choice over others
- Which screens/components affected

**Example**:
```bash
bd create "UI-DD-001: Use modal for filing archive confirmation" \
  -t ui-design-decision \
  -p 2 \
  --body "Decision: Archive action uses confirmation modal instead of inline.

Alternatives:
1. Inline confirmation (simpler, but easy to miss)
2. Page navigation (too disruptive for single action)
3. Modal dialog (chosen - clear, reversible, matches delete pattern)

Rationale: Matches existing delete workflow. Clear destructive action pattern.

Screens: filing_list, filing_detail"
```

---

### GO Feedback (type=go-friction)

**When to create**: The GO framework itself caused friction (not project-specific issues).

**What to include**:
- What didn't work well
- How it affected the project
- Suggested improvement

**Example**:
```bash
bd create "GF-001: Final report missing TD aggregation" \
  -t go-friction \
  -p 2 \
  --body "GO Feedback: /go:verify doesn't aggregate technical debt items from phase handoffs.

Impact: Had to manually compile TD-001 and TD-002 for final report.

Suggestion: GO plugin should scan HANDOFF_PHASE_*.md files for TD items and include summary in final report."
```

---

## What NOT to Track

Avoid noise - not every observation needs a bead.

**Do NOT create beads for**:

- **Routine implementation details**: "Used for loop instead of list comprehension" - not meaningful to future agents
- **Obvious choices**: "Used pytest for testing" - standard tooling doesn't need justification
- **Temporary issues**: "Fixed typo in variable name" - no future impact
- **Personal preferences**: "Preferred camelCase" - unless it affected team decision
- **Already documented**: If it's in CLAUDE.md or README, don't duplicate as bead

**Rule of thumb**: Would the next agent ask "why?" about this? If no, skip the bead.

---

## Bead Naming Convention

Use consistent prefixes for queryability:

| Type | Prefix | Example |
|------|--------|---------|
| Decision | DD-NNN | DD-001: Use dataclasses over Pydantic |
| Discovery | DS-NNN | DS-001: Episode.content dual format |
| Friction | FR-NNN | FR-001: Test isolation with SqliteStore |
| Pivot | PV-NNN | PV-001: Manual handoffs for MVP |
| Assumption | AS-NNN | AS-001: 200 tokens for tacit message |
| GO Feedback | GF-NNN | GF-001: Missing TD aggregation |
| UI Design Spec | UI-DS-NNN | UI-DS-001: Filing.archived field added |
| UI Design Decision | UI-DD-NNN | UI-DD-001: Use modal for archive confirmation |

Numbers are sequential per type within the project.

---

## Querying Beads

Find beads by type:
```bash
bd list -t decision          # All decisions
bd list -t friction          # All friction points
bd list -t assumption        # All assumptions
```

Find open assumptions to validate:
```bash
bd list -t assumption --status open
```

Find high-priority items:
```bash
bd list -p 1                 # P1 priority
bd list -p 1 -p 2            # P1 and P2
```

Search across beads:
```bash
bd list | grep "handoff"     # Find handoff-related beads
```

---

## Integration with Project Report

The PROJECT_REPORT_TEMPLATE.md has a "Key Moments Index" section that pulls from beads:

```markdown
## Key Moments Index

### Decisions (type=decision)
| ID | Summary | Source | Impact |
|----|---------|--------|--------|
| DD-001 | Use dataclasses over Pydantic | Phase 1 | All content structures |
| DD-002 | Sequential commits for MVP | Phase 4 | TD-001 created |
```

**Workflow**:
1. Create beads during development as you encounter key moments
2. At report generation, query beads: `bd list -t decision --json`
3. Populate Key Moments Index from bead data

---

## Quick Reference Card

```bash
# Decision: Choice between alternatives
bd create "DD-NNN: [Brief title]" -t decision -p [1-4]

# Discovery: Non-obvious learning
bd create "DS-NNN: [Brief title]" -t discovery -p [1-4]

# Friction: Harder than expected
bd create "FR-NNN: [Brief title]" -t friction -p [1-4]

# Pivot: Direction changed
bd create "PV-NNN: [Brief title]" -t pivot -p [1-4]

# Assumption: Unvalidated bet
bd create "AS-NNN: [Brief title]" -t assumption -p [1-4]

# GO Feedback: Framework friction
bd create "GF-NNN: [Brief title]" -t go-friction -p [1-4]

# UI Design Spec: Backend change affecting UI
bd create "UI-DS-NNN: [Brief title]" -t ui-design-spec -p [1-4]

# UI Design Decision: UI/UX choice
bd create "UI-DD-NNN: [Brief title]" -t ui-design-decision -p [1-4]
```

Priority levels:
- P1: Blocking / critical
- P2: High / should address soon
- P3: Medium / track for later
- P4: Low / nice to have

---

## Integration with Handoff Documents

Beads are created during phase execution and aggregated through handoff documents.

### Where Beads Live

| Bead Type | Created In | Aggregated To |
|-----------|------------|---------------|
| Decisions (DD-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | HANDOFF.md "Design Decisions" section |
| Discoveries (DS-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | HANDOFF.md "Discoveries" section |
| Assumptions (AS-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | HANDOFF.md "Assumptions" section |
| Pivots (PV-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | HANDOFF.md "Pivots" section |
| Friction (FR-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | HANDOFF.md "Technical Debt" (if actionable) |
| GO Feedback (GF-NNN) | HANDOFF_PHASE_N.md "Beads Created This Phase" | PROJECT_REPORT.md "Framework Feedback" section |

### Lifecycle

1. **Create**: During phase execution, add beads to HANDOFF_PHASE_N.md "Beads Created This Phase" table
2. **Carry**: At phase end, copy new beads to main HANDOFF.md in appropriate sections
3. **Close**: Later phases can mark beads as Validated/Resolved/Falsified by updating HANDOFF.md
4. **Report**: Final PROJECT_REPORT.md summarizes all beads with links back to HANDOFF.md

### Example Workflow

**During Phase 3 execution:**
```markdown
## Beads Created This Phase (in HANDOFF_PHASE_3.md)

| ID | Type | Summary | Status |
|----|------|---------|--------|
| AS-002 | Assumption | Users will always have write access | Open |
| DS-003 | Discovery | SqliteStore uses singleton pattern | Confirmed |
```

**At Phase 3 completion - update HANDOFF.md:**
```markdown
## Assumptions (in HANDOFF.md)

| ID | Assumption | Phase | Risk if Wrong | Status | Validated By |
|----|------------|-------|---------------|--------|--------------|
| AS-001 | 200 tokens sufficient | 2 | Lost context | Validated | Phase 6 |
| AS-002 | Users have write access | 3 | Permission errors | Open | N/A |

## Discoveries (in HANDOFF.md)

| ID | Discovery | Phase | Impact | Source |
|----|-----------|-------|--------|--------|
| DS-003 | SqliteStore singleton | 3 | Test isolation issues | FR-001 resolution |
```

**Later in Phase 5 - validate assumption:**
```markdown
## Assumptions (in HANDOFF.md)

| ID | Assumption | Phase | Risk if Wrong | Status | Validated By |
|----|------------|-------|---------------|--------|--------------|
| AS-002 | Users have write access | 3 | Permission errors | Validated | Phase 5 testing |
```

### Querying Beads Across Documents

To find all beads of a type across the project:

```bash
# Find all decisions
rg "DD-[0-9]+" HANDOFF*.md

# Find open assumptions
rg "AS-[0-9]+" HANDOFF.md | grep "Open"

# Find all pivots
rg "PV-[0-9]+" --glob "*.md"
```

### What Goes Where

| If you discover... | Create this bead | In this document |
|-------------------|------------------|------------------|
| A choice between alternatives | DD-NNN (Decision) | HANDOFF_PHASE_N.md, then HANDOFF.md |
| Something non-obvious about the system | DS-NNN (Discovery) | HANDOFF_PHASE_N.md, then HANDOFF.md |
| A bet without evidence | AS-NNN (Assumption) | HANDOFF_PHASE_N.md, then HANDOFF.md |
| Direction changed from plan | PV-NNN (Pivot) | HANDOFF_PHASE_N.md, then HANDOFF.md |
| Something harder than expected | FR-NNN (Friction) | HANDOFF_PHASE_N.md, then beads tracker |
| GO framework issue | GF-NNN (GO Feedback) | HANDOFF_PHASE_N.md, then PROJECT_REPORT.md |
| Work to do later | TD-NNN (Tech Debt) | HANDOFF.md "Technical Debt" directly |
