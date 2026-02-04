# Round 5: Edge Cases

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 15-20 minutes

---

## Purpose

Round 5 stress-tests the design by systematically identifying edge cases, error conditions, and unusual scenarios that could break the system. This is where assumptions get challenged and the design gets hardened.

**Why Edge Cases Matter**:
- Better to find edge cases in discovery than in production
- Each edge case resolution may require entity, workflow, or screen updates
- High-risk edge cases become blocking issues if unresolved
- Module edge case libraries accelerate this round

**R5 Output**:
- Complete edge case inventory organized by category and severity
- Resolution strategies for each case
- Updates to entities, workflows, or screens as needed
- Test scenarios for verification

---

## Entry Requirements

**R5 cannot begin until**:

- [ ] R4 (Screens) is complete
- [ ] All screens have defined states and error handling
- [ ] Entity relationships are finalized (from R2)
- [ ] Workflow steps are defined with decision points (from R3)

**Prerequisite Files**:
- `discovery/R2_ENTITIES.md` — Entity definitions to probe
- `discovery/R3_WORKFLOWS.md` — Workflows to stress-test
- `discovery/R4_SCREENS.md` — Screens to challenge with unexpected input
- `discovery/discovery-state.json` — Current state with module selections

---

## Instructions for Boss Agent

### Edge Case Discovery Protocol

**Step 1: Gather Seed Edge Cases (3-5 minutes)**

Load edge case libraries from selected modules:

```
For each module in discovery-state.modules.selected:
  Read module's Edge Case Library section
  Add relevant edge cases to inventory as seeds
  Mark source as "module_library: {module_id}"
```

**Step 2: Entity Walk-through (5-7 minutes)**

For each entity in R2_ENTITIES.md, ask these questions:

| Category | Question Pattern |
|----------|------------------|
| Null/Empty | "What if {field} is null, empty, or blank?" |
| Boundaries | "What if {field} exceeds max length or hits min/max values?" |
| Duplicates | "What if two {entities} have the same {unique_field}?" |
| Orphans | "What if referenced {related_entity} is deleted?" |
| Invalid State | "What if {entity} transitions from {state_A} to invalid {state_C}?" |
| Concurrent | "What if two users modify {entity} simultaneously?" |

**Step 3: Workflow Walk-through (5-7 minutes)**

For each workflow in R3_WORKFLOWS.md, ask these questions:

| Category | Question Pattern |
|----------|------------------|
| Timing | "What if step {N} times out or takes too long?" |
| Failure | "What if step {N} fails after step {N-1} succeeded?" |
| Retry | "What if step {N} is retried — is it idempotent?" |
| Permission | "What if user's permission is revoked mid-workflow?" |
| Interruption | "What if user abandons workflow at step {N}?" |
| External | "What if external system {API} is down or returns error?" |

**Step 4: Screen Walk-through (3-5 minutes)**

For each screen in R4_SCREENS.md, ask these questions:

| Category | Question Pattern |
|----------|------------------|
| Input | "What if user pastes {unexpected_content} into {field}?" |
| Navigation | "What if user hits back button after {action}?" |
| Session | "What if user opens same screen in multiple tabs?" |
| Deep Link | "What if user bookmarks or shares URL to {screen}?" |
| Timeout | "What if user's session expires during {form}?" |
| Validation | "What if validation passes client-side but fails server-side?" |

**Step 5: Domain-Specific Probing**

Ask the user about edge cases specific to their domain:

- "What unusual situations have come up in your current process?"
- "What complaints or workarounds do users have today?"
- "Are there regulatory or compliance edge cases we need to handle?"
- "What happens during peak usage or end-of-period processing?"

---

## Edge Case Categories

### Data Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| DATA-001 | Null or empty required field | User submits form with blank name | Server validation |
| DATA-002 | Value exceeds max length | Description pasted with 50,000 characters | Client + server validation |
| DATA-003 | Special characters in text | SQL injection, XSS, emoji, unicode | Input sanitization |
| DATA-004 | Duplicate unique values | Two users with same email | Unique constraint |
| DATA-005 | Orphaned records | Invoice line without parent invoice | Foreign key constraint |
| DATA-006 | Stale data | Editing record that another user modified | Optimistic locking |
| DATA-007 | Type coercion errors | "123abc" submitted as numeric field | Type validation |
| DATA-008 | Date/time edge cases | Midnight, leap year, DST transition, timezone | Date handling library |
| DATA-009 | Decimal precision | Currency calculation rounding ($10.00 / 3) | Decimal type, rounding rules |
| DATA-010 | Large file uploads | 500MB attachment, slow connection | Size limits, chunked upload |

### Timing Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| TIME-001 | Concurrent edits | Two users update same record | Version/timestamp conflict |
| TIME-002 | Race condition | Button clicked twice rapidly | Idempotency key |
| TIME-003 | Request timeout | External API takes > 30 seconds | Timeout handler |
| TIME-004 | Retry storm | Failed request retried by multiple clients | Backoff + jitter |
| TIME-005 | Clock drift | Server times out of sync | NTP, use UTC |
| TIME-006 | Scheduled job overlap | Previous job still running when next starts | Job locking |
| TIME-007 | End-of-period timing | Invoice created at 11:59:59 PM | Clear date boundaries |
| TIME-008 | Delayed message delivery | Webhook arrives out of order | Idempotency, ordering |
| TIME-009 | Session expiry mid-action | Token expires during long form fill | Refresh token, draft save |
| TIME-010 | Cache invalidation timing | Stale cache served after update | Cache versioning |

### State Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| STATE-001 | Invalid state transition | Draft → Paid (skipping Sent) | State machine validation |
| STATE-002 | Orphaned records | Payment without invoice | Integrity check |
| STATE-003 | Zombie process | Workflow stuck in "processing" | Health check, timeout |
| STATE-004 | Inconsistent state | Parent deleted, children remain | Cascade or restrict |
| STATE-005 | Recovery from failure | App crash mid-transaction | Transaction rollback |
| STATE-006 | Multi-step rollback | Step 3 fails, steps 1-2 need undo | Saga pattern |
| STATE-007 | Soft delete confusion | Deleted record still appears | Soft delete filter |
| STATE-008 | Archive resurrection | User needs access to archived data | Archive access policy |
| STATE-009 | Draft vs published | Edit published item while draft exists | Version tracking |
| STATE-010 | Status notification race | Email sent before status saved | Transaction ordering |

### User Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| USER-001 | Multiple tabs/windows | Same form open in two tabs | Tab sync, warning |
| USER-002 | Back button after submit | Re-submits completed form | Post/Redirect/Get |
| USER-003 | Bookmark deep link | Direct URL to step 3 of wizard | URL validation |
| USER-004 | Copy-paste URL with token | Sharing URL that includes auth token | Token in header, not URL |
| USER-005 | Session timeout | User returns after 30 minutes | Session restore |
| USER-006 | Device switch | Started on mobile, continue on desktop | Progress sync |
| USER-007 | Browser refresh during action | Refresh while payment processing | Idempotency |
| USER-008 | Autofill interference | Browser autofills wrong data | Field name clarity |
| USER-009 | Screen reader navigation | Tab order is illogical | A11y testing |
| USER-010 | Offline/online transition | Network drops mid-form submission | Offline queue |

### Permission Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| PERM-001 | Elevated permission | Admin action by regular user | Authorization check |
| PERM-002 | Revoked mid-session | Permission removed while user active | Auth refresh |
| PERM-003 | Role confusion | User has conflicting roles | Role precedence rules |
| PERM-004 | Delegation expiry | Temporary access expires | Time-bound check |
| PERM-005 | Resource ownership | User accesses another's private data | Resource-level auth |
| PERM-006 | Cross-tenant access | Multi-tenant data isolation breach | Tenant scoping |
| PERM-007 | API key reuse | Old API key used after rotation | Key versioning |
| PERM-008 | Impersonation | Admin impersonates user, forgets to exit | Impersonation timeout |
| PERM-009 | Audit trail attribution | Action logged to wrong user | Clear audit context |
| PERM-010 | Export authorization | User exports data they can view but not export | Action-level permission |

### Integration Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| INT-001 | External API down | Payment processor unavailable | Health check, circuit breaker |
| INT-002 | Partial failure | 3 of 5 items saved, 2 failed | Transaction or compensation |
| INT-003 | Rate limit exceeded | Too many API calls | Rate limit tracking |
| INT-004 | Data format change | External API changes response schema | Schema validation |
| INT-005 | Webhook missed | External system didn't receive callback | Retry with backoff |
| INT-006 | Duplicate webhook | Same event delivered twice | Idempotency key |
| INT-007 | Out-of-order events | Event B arrives before Event A | Event ordering, buffering |
| INT-008 | Credential expiry | OAuth token expired | Token refresh flow |
| INT-009 | Sandbox vs production | Test data sent to production API | Environment isolation |
| INT-010 | Version mismatch | Client expects v2 API, server has v3 | API versioning |

### Business Logic Edge Cases

| ID | Scenario | Example | Detection |
|----|----------|---------|-----------|
| BIZ-001 | Zero quantity/amount | Order with 0 items, $0.00 invoice | Minimum validation |
| BIZ-002 | Negative values | Negative quantity, refund > original | Sign validation |
| BIZ-003 | Circular reference | Entity references itself | Cycle detection |
| BIZ-004 | Division by zero | Calculate average with 0 items | Denominator check |
| BIZ-005 | Overflow | Total exceeds max decimal precision | Range validation |
| BIZ-006 | Historical data | Report on deleted/changed entities | Point-in-time data |
| BIZ-007 | Retroactive change | Policy change applied to past records | Effective dating |
| BIZ-008 | Partial fulfillment | Ship 8 of 10 ordered items | Partial status handling |
| BIZ-009 | Compound rules | Discount + tax + surcharge interaction | Calculation order |
| BIZ-010 | Edge date handling | Leap year, month-end, fiscal year | Date math library |

---

## Edge Case Specification Template

```yaml
edge_case:
  id: "EC-{CATEGORY}-{NUMBER}"
  category: "data | timing | state | user | permission | integration | business"
  title: "Brief description of the edge case"

  description: |
    Detailed explanation of the scenario, including:
    - What makes this an edge case
    - Why it matters
    - How often it might occur

  trigger_conditions:
    - "Specific condition 1 that causes this"
    - "Specific condition 2 that causes this"
    - "Combination of factors"

  affected:
    entities: ["Entity1", "Entity2"]
    screens: ["Screen1", "Screen2"]
    workflows: ["Workflow1"]

  risk_level: "critical | high | medium | low"

  risk_assessment:
    likelihood: "rare | unlikely | possible | likely | certain"
    impact: "negligible | minor | moderate | major | severe"
    reasoning: "Why this risk level"

  current_handling: |
    How the system currently handles this (or "none" if not addressed)

  proposed_resolution:
    strategy: "prevent | detect_recover | fail_gracefully | document_limitation"
    implementation: |
      Specific approach to resolve this edge case
    entity_updates: []
    workflow_updates: []
    screen_updates: []

  test_scenario:
    preconditions:
      - "System is in state X"
      - "User has role Y"
    steps:
      - "User performs action A"
      - "System responds with B"
      - "User observes C"
    expected_result: "What should happen"
    verification: "How to verify the fix works"

  metadata:
    source: "discovery | module_library | user_input"
    confidence: "high | medium | low"
    discovered_in_round: 5
    related_edge_cases: ["EC-XXX-001"]
```

---

## Question Patterns for Discovery

### Data Edge Cases

```
For each entity field:
- "What if [field_name] is null/empty/blank?"
- "What if [field_name] contains special characters or emojis?"
- "What if [field_name] is exactly at the maximum allowed length?"
- "What if [field_name] is submitted with leading/trailing whitespace?"

For unique fields:
- "What happens if a user tries to create a duplicate [unique_field]?"
- "How do we handle case sensitivity in [unique_field]?"

For relationships:
- "What if [parent_entity] is deleted while [child_entity] still references it?"
- "What if [related_entity] is soft-deleted — can we still see it?"
```

### Timing Edge Cases

```
For each workflow:
- "What if step [N] takes longer than expected?"
- "What if the user clicks [action_button] twice quickly?"
- "What if the external API times out during [integration_step]?"
- "What if this workflow runs at midnight across time zones?"

For concurrent operations:
- "What if two users edit the same [entity] at the same time?"
- "What if a scheduled job runs while a user is making changes?"
```

### State Edge Cases

```
For each entity with status:
- "What transitions are allowed from [status_A]?"
- "What if someone tries to go directly from [status_A] to [status_C]?"
- "What happens to related records when this transitions to [status]?"

For workflows:
- "What if the workflow fails at step [N]? What state is left behind?"
- "How do we recover if the system crashes mid-workflow?"
```

### User Behavior Edge Cases

```
For each screen:
- "What if the user opens this screen in multiple tabs?"
- "What if the user hits the back button after [action]?"
- "What if the user bookmarks this URL and returns later?"
- "What if the user's session expires while filling out this form?"

For forms:
- "What if the user pastes content from another application?"
- "What if autofill populates the wrong data?"
```

### Permission Edge Cases

```
For each protected action:
- "What if a user's permission is revoked while they're mid-[action]?"
- "What if a user gains elevated access temporarily — what cleanup is needed?"
- "What if an admin impersonates a user — how is the audit trail affected?"

For multi-tenant:
- "What if a user somehow accesses data from another [tenant]?"
- "How do we ensure [shared_resource] doesn't leak between tenants?"
```

### Integration Edge Cases

```
For each external integration:
- "What if [external_system] is completely unavailable?"
- "What if [external_system] returns an error after we've already committed locally?"
- "What if [external_system] rate-limits our requests?"
- "What if [external_system] changes their API response format?"

For webhooks:
- "What if we receive the same webhook twice?"
- "What if webhooks arrive out of chronological order?"
```

### Domain-Specific Probing

```
General questions for the user:
- "What's the weirdest thing that's happened in your current process?"
- "What do users complain about or work around?"
- "Are there any regulatory or compliance scenarios we need to handle?"
- "What happens during peak usage periods?"
- "What happens at end-of-month, end-of-quarter, or end-of-year?"
```

---

## Resolution Strategy Patterns

### Prevent (Validation)

**Use when**: The edge case can be stopped before it occurs.

```yaml
prevention_strategies:
  - client_side_validation:
      what: "Immediate feedback in UI"
      examples: ["Field length limits", "Required field markers", "Format masks"]

  - server_side_validation:
      what: "Authoritative check before persistence"
      examples: ["Unique constraint", "Business rule validation", "Permission check"]

  - database_constraints:
      what: "Database-level enforcement"
      examples: ["NOT NULL", "UNIQUE", "CHECK", "FOREIGN KEY"]

  - input_sanitization:
      what: "Clean or reject malicious input"
      examples: ["HTML escape", "SQL parameterization", "File type validation"]
```

### Detect and Recover (Error Handling)

**Use when**: The edge case can't be prevented but can be detected and fixed.

```yaml
detection_recovery_strategies:
  - optimistic_locking:
      what: "Detect concurrent modification, reject second write"
      examples: ["Version column", "Timestamp comparison", "ETag"]

  - idempotency:
      what: "Safe to retry without duplicate effect"
      examples: ["Idempotency key", "Check-then-act", "Upsert"]

  - circuit_breaker:
      what: "Stop calling failing service, fail fast"
      examples: ["External API failures", "Database overload"]

  - saga_pattern:
      what: "Compensating transactions for multi-step workflows"
      examples: ["Order → Payment → Shipping with rollback"]

  - dead_letter_queue:
      what: "Capture failed messages for manual review"
      examples: ["Failed webhook processing", "Invalid event format"]
```

### Fail Gracefully (Degraded Experience)

**Use when**: The edge case can't be prevented or recovered, but we can minimize impact.

```yaml
graceful_failure_strategies:
  - partial_success:
      what: "Complete what we can, report what failed"
      examples: ["Bulk import with error report", "Multi-item save with failures"]

  - fallback_value:
      what: "Use sensible default when data unavailable"
      examples: ["Cache hit when API down", "Default avatar when image missing"]

  - feature_toggle:
      what: "Disable feature rather than break experience"
      examples: ["Live search falls back to basic search", "Real-time becomes polling"]

  - user_notification:
      what: "Tell user what happened and what to do"
      examples: ["Error message with retry option", "Contact support link"]
```

### Document as Known Limitation

**Use when**: The edge case is too rare, expensive, or low-impact to fix now.

```yaml
documentation_strategies:
  - user_documentation:
      what: "Explain limitation in help docs or tooltips"
      examples: ["Max 100 items per import", "Timezone note on reports"]

  - admin_documentation:
      what: "Explain to system administrators"
      examples: ["Manual intervention procedure", "Data cleanup script"]

  - release_notes:
      what: "Known issues in release documentation"
      examples: ["Edge case to be fixed in next version"]

  - monitoring_alert:
      what: "Detect when limitation is hit, alert team"
      examples: ["Alert when edge case occurs > 5x/day"]
```

---

## Output Template

### Edge Case Inventory

#### Critical Risk Edge Cases

| ID | Category | Description | Affected | Resolution |
|----|----------|-------------|----------|------------|
| EC-XXX-001 | [category] | [Brief description] | [entities/screens] | [strategy] |

#### High Risk Edge Cases

| ID | Category | Description | Affected | Resolution |
|----|----------|-------------|----------|------------|
| EC-XXX-002 | [category] | [Brief description] | [entities/screens] | [strategy] |

#### Medium Risk Edge Cases

| ID | Category | Description | Affected | Resolution |
|----|----------|-------------|----------|------------|
| EC-XXX-003 | [category] | [Brief description] | [entities/screens] | [strategy] |

#### Low Risk Edge Cases

| ID | Category | Description | Affected | Resolution |
|----|----------|-------------|----------|------------|
| EC-XXX-004 | [category] | [Brief description] | [entities/screens] | [strategy] |

---

### Edge Case Details

For each edge case, document using the specification template:

```yaml
edge_case:
  id: "EC-DATA-001"
  category: "data"
  title: "Customer email contains unicode characters"
  # ... full specification
```

---

### Impact Summary

#### Entity Updates Required

| Entity | Update Type | Description | Edge Cases |
|--------|-------------|-------------|------------|
| [Entity] | [field/validation/relationship] | [What changes] | [EC-XXX-001, EC-XXX-002] |

#### Workflow Updates Required

| Workflow | Update Type | Description | Edge Cases |
|----------|-------------|-------------|------------|
| [Workflow] | [step/error handling/retry] | [What changes] | [EC-XXX-003] |

#### Screen Updates Required

| Screen | Update Type | Description | Edge Cases |
|--------|-------------|-------------|------------|
| [Screen] | [validation/state/error display] | [What changes] | [EC-XXX-004] |

---

### Unresolved Edge Cases

Edge cases that need user input or become blocking issues:

| ID | Description | Blocker Type | Question for User |
|----|-------------|--------------|-------------------|
| EC-XXX-005 | [Description] | [hard/soft] | [What we need to know] |

---

## Validation Checklist

R5 cannot be marked complete until all items are checked:

### Required (Blocks Completion)

- [ ] All entities from R2 have been reviewed for data edge cases
- [ ] All workflows from R3 have been reviewed for timing/state edge cases
- [ ] All screens from R4 have been reviewed for user behavior edge cases
- [ ] Module edge case libraries have been incorporated (if modules selected)
- [ ] All critical-risk edge cases have resolution strategies
- [ ] All high-risk edge cases have resolution strategies
- [ ] No unresolved hard blockers remain

### Quality Checks

- [ ] Edge cases are categorized correctly
- [ ] Risk levels are justified with likelihood + impact
- [ ] Resolution strategies are actionable
- [ ] Test scenarios are specific and verifiable
- [ ] Entity/workflow/screen updates are documented

### Coverage Verification

| Category | Minimum Cases | Discovered | Status |
|----------|---------------|------------|--------|
| Data | 3 | _ | _ |
| Timing | 2 | _ | _ |
| State | 2 | _ | _ |
| User | 2 | _ | _ |
| Permission | 1 | _ | _ |
| Integration | 1 (if integrations exist) | _ | _ |
| Business Logic | 2 | _ | _ |

---

## State Update

When R5 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R5": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "edge_case_count": {{ count }},
      "critical_count": {{ critical_count }},
      "high_count": {{ high_count }}
    }
  },
  "current_round": "R6",

  "edge_cases": [
    {
      "id": "EC-DATA-001",
      "category": "data",
      "title": "...",
      "risk_level": "high",
      "resolution_strategy": "prevent",
      "affects_entities": ["Invoice"],
      "affects_workflows": [],
      "affects_screens": ["InvoiceForm"],
      "status": "resolved",
      "test_scenario": "..."
    }
  ],

  "blocking_issues": [
    {
      "id": "BI-002",
      "round": "R5",
      "description": "Unclear how to handle multi-currency edge cases",
      "severity": "soft",
      "resolution": null,
      "source_edge_case": "EC-BIZ-007",
      "created": "{{ ISO_DATE }}"
    }
  ]
}
```

---

## Next Steps

After R5 completes:

1. Save as `discovery/R5_EDGE_CASES.md`
2. Update `discovery-state.json` with edge case inventory
3. If entity/workflow/screen updates are required:
   - Document updates in R5_EDGE_CASES.md
   - Note that R2/R3/R4 artifacts may need revision
4. Proceed to **R6: Technical Lock-in** — Now that we know what edge cases exist, we can make informed technical decisions about how to handle them.

---

## Quick Reference

### Risk Level Decision Matrix

```
                    IMPACT
                    Low    Medium    High    Severe
LIKELIHOOD
Certain             Med    High      Crit    Crit
Likely              Low    Med       High    Crit
Possible            Low    Med       High    High
Unlikely            Low    Low       Med     High
Rare                Low    Low       Low     Med
```

### Resolution Strategy Decision Tree

```
Can we prevent it with validation?
  ├─ Yes → PREVENT (validation, constraints)
  └─ No → Can we detect and recover?
           ├─ Yes → DETECT & RECOVER (retry, compensate)
           └─ No → Is the impact acceptable?
                    ├─ Yes → FAIL GRACEFULLY (degrade, notify)
                    └─ No → DOCUMENT as limitation, create blocking issue
```

### Category Quick Guide

| Category | Focus | Example Questions |
|----------|-------|-------------------|
| Data | Field values, relationships | "What if null/empty/too long?" |
| Timing | Concurrency, race conditions | "What if two users at once?" |
| State | Status transitions, consistency | "What if transition invalid?" |
| User | Browser behavior, navigation | "What if back button/multi-tab?" |
| Permission | Authorization, access control | "What if access revoked?" |
| Integration | External APIs, webhooks | "What if external system down?" |
| Business | Domain rules, calculations | "What if edge date/amount?" |
