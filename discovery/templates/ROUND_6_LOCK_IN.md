# Round 6: Technical Lock-In

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 10-15 minutes

---

## Purpose

Round 6 is the **final validation checkpoint** before auto-generating the build plan. This is where "inference with transparency" becomes "explicit commitment" — every assumption, technical choice, and architectural decision gets surfaced, validated, and locked in.

**Why Lock-In Matters**:
- Prevents "we should have discussed this earlier" moments during build
- Converts implicit assumptions into explicit decisions with documented rationale
- Identifies decisions that are hard to reverse once implemented
- Ensures the build plan is based on validated requirements, not guesswork
- Creates accountability — every decision has a clear owner (user-confirmed or inferred-accepted)

**R6 is the "point of no return" for assumptions**:
- After R6, the system has high confidence on all critical decisions
- Low-confidence items either get validated or become documented risks
- Hard-to-reverse decisions get explicit user sign-off

**R6 Output**:
- Complete decision log with rationale
- Validated assumption register
- Readiness gate status (all gates should pass)
- Risk register for accepted risks

---

## Entry Requirements

**R6 cannot begin until**:

- [ ] R5 (Edge Cases) is complete
- [ ] No unresolved critical-risk edge cases
- [ ] No unresolved hard blockers from any round
- [ ] All entities, workflows, and screens are documented

**Prerequisite Files**:
- `discovery/R1_CONTEXT.md` — Constraints and environment
- `discovery/R2_ENTITIES.md` — Data model decisions
- `discovery/R3_WORKFLOWS.md` — Process and integration decisions
- `discovery/R4_SCREENS.md` — UI/UX decisions
- `discovery/R5_EDGE_CASES.md` — Edge case resolutions requiring technical choices
- `discovery/discovery-state.json` — Current state with confidence levels

---

## Instructions for Boss Agent

### Technical Lock-In Protocol

**Step 1: Confidence Audit (3-5 minutes)**

Scan all previous round outputs for medium and low confidence items:

```
For each round R1-R5:
  Extract items where confidence != "high"
  Group by decision category
  Prioritize by:
    1. Reversibility (hard-to-reverse first)
    2. Impact scope (affects many nodes first)
    3. Cost of wrong choice (expensive mistakes first)
```

**Step 2: Decision Surfacing (3-5 minutes)**

For each decision category, identify what needs explicit confirmation:

| Category | Look For |
|----------|----------|
| Tech Stack | Language, framework, database mentioned but not confirmed |
| Architecture | Patterns implied but not validated |
| Auth | Auth method assumed from context |
| Data | Schema decisions, caching strategy |
| Integration | Sync/async patterns, error handling |
| Deployment | Environment assumptions, CI/CD approach |
| Testing | Test strategy, coverage expectations |
| Non-Functional | Performance, scalability, security assumptions |

**Step 3: User Validation (5-7 minutes)**

Present decisions grouped by reversibility:

**Hard to Reverse** (present first, require explicit confirmation):
- "We're planning to use [X] for the database. This is hard to change later — can you confirm?"
- "The architecture will be [Y]. Changing this would require significant rework. Is this correct?"

**Moderate to Reverse** (present for awareness, confirm if uncertain):
- "We'll use [auth_method] for authentication. Want me to explain the alternatives?"
- "Integration with [system] will be async with retry. Does that match your expectations?"

**Easy to Reverse** (document decision, move on):
- "We'll start with [testing_approach] — this can be adjusted during build."

**Step 4: Assumption Resolution**

For each unvalidated assumption from R1-R5:

1. Present the assumption clearly
2. Explain risk if wrong
3. Get one of three responses:
   - **Validate**: "Yes, that's correct" → Mark as validated
   - **Correct**: "No, it should be X" → Update and mark as validated
   - **Accept Risk**: "I'm not sure, but proceed" → Mark as accepted_risk

**Step 5: Readiness Gate Verification**

Check all gates before proceeding to R7:

| Gate | Check |
|------|-------|
| all_rounds_complete | R1-R5 status = "complete" |
| no_hard_blockers | Zero blocking_issues with severity = "hard" |
| confidence_threshold_met | No core items at "low" confidence |
| modules_validated | modules.selected.length > 0 |

---

## Decision Categories

### 1. Tech Stack Decisions

```yaml
decision_category: tech_stack
items:
  - primary_language: "Language for backend logic"
  - secondary_languages: "Other languages used (frontend, scripts, etc.)"
  - framework: "Web/API framework"
  - database_primary: "Main persistent storage"
  - database_secondary: "Cache, search, or specialized storage"
  - hosting_provider: "Where the application runs"
  - package_manager: "Dependency management tool"
```

Questions to ask if not explicit:
- "What language/framework are you most comfortable with?"
- "Any requirements for the database (relational, document, graph)?"
- "Cloud provider preference or constraints?"

### 2. Architecture Decisions

```yaml
decision_category: architecture
items:
  - pattern: "monolith | modular_monolith | microservices"
  - api_style: "REST | GraphQL | gRPC | hybrid"
  - event_driven: "sync | async_queues | event_sourcing | none"
  - state_management: "server_sessions | jwt_stateless | hybrid"
  - file_structure: "layer_based | feature_based | domain_driven"
```

Questions to ask if not explicit:
- "Do you expect to scale specific parts independently?"
- "Are there real-time requirements that need event-driven patterns?"
- "How important is API flexibility for future clients?"

### 3. Authentication & Authorization Decisions

```yaml
decision_category: auth
items:
  - auth_method: "email_password | oauth | sso | api_key | none"
  - auth_provider: "self_hosted | auth0 | firebase | cognito | clerk"
  - session_handling: "jwt | server_session | cookie"
  - permission_model: "rbac | abac | acl | simple_roles"
  - multi_tenant: "single_tenant | multi_tenant_shared | multi_tenant_isolated"
```

Questions to ask if not explicit:
- "Who will manage user accounts?"
- "Do users need social login options?"
- "How complex are the permission requirements?"

### 4. Data Storage Decisions

```yaml
decision_category: data_storage
items:
  - schema_approach: "schema_first | code_first | schema_migration"
  - orm_strategy: "full_orm | query_builder | raw_sql | mixed"
  - caching_strategy: "none | local | distributed | cdn"
  - file_storage: "local | s3_compatible | database | none"
  - backup_strategy: "automated | manual | provider_managed"
```

Questions to ask if not explicit:
- "Any preference for how database migrations are handled?"
- "What needs caching and what latency is acceptable?"
- "Will users upload files? How large?"

### 5. Integration Decisions

```yaml
decision_category: integration
items:
  - api_calls: "sync | async_background | async_queue"
  - error_handling: "fail_fast | retry_with_backoff | circuit_breaker"
  - retry_policy: "none | simple_retry | exponential_backoff"
  - webhook_handling: "sync_process | queue_then_process | event_driven"
  - rate_limiting: "none | client_side | server_side | both"
```

Questions to ask if not explicit:
- "Can operations involving external systems happen in the background?"
- "How should the system behave when an external API is down?"
- "Are there rate limits we need to respect?"

### 6. Deployment Decisions

```yaml
decision_category: deployment
items:
  - ci_cd_approach: "github_actions | gitlab_ci | jenkins | manual"
  - environments: "dev_prod | dev_staging_prod | dev_qa_staging_prod"
  - infrastructure_as_code: "terraform | pulumi | cloudformation | manual"
  - containerization: "docker | none | serverless"
  - secrets_management: "env_vars | vault | provider_secrets | config_file"
```

Questions to ask if not explicit:
- "How do you want to deploy changes?"
- "How many environments do you need?"
- "Are there existing infrastructure patterns to follow?"

### 7. Testing Strategy Decisions

```yaml
decision_category: testing
items:
  - unit_testing: "test_framework | coverage_target | mocking_approach"
  - integration_testing: "database_strategy | external_api_strategy"
  - e2e_testing: "tool | scope | automation_level"
  - test_data: "fixtures | factories | production_copy | manual"
  - ci_testing: "all_tests | unit_only | staged_testing"
```

Questions to ask if not explicit:
- "What level of test coverage do you expect?"
- "How should we handle test data?"
- "Should tests run on every commit?"

### 8. Non-Functional Requirements

```yaml
decision_category: non_functional
items:
  - performance_targets:
      page_load: "< X seconds"
      api_response: "< Y ms"
      concurrent_users: "X users"
  - scalability:
      approach: "vertical | horizontal | auto_scaling"
      expected_growth: "description of growth expectations"
  - security:
      data_encryption: "at_rest | in_transit | both | none"
      compliance: "gdpr | hipaa | soc2 | pci | none"
      security_scanning: "sast | dast | dependency_scan | none"
  - reliability:
      uptime_target: "99% | 99.9% | 99.99%"
      disaster_recovery: "rpo_rto_targets"
```

Questions to ask if not explicit:
- "What response times would be unacceptable?"
- "How many users do you expect initially and in a year?"
- "Are there compliance requirements we haven't discussed?"

---

## Decision Specification Template

For each decision, document using this structure:

```yaml
decision:
  id: "DEC-{CATEGORY}-{NUMBER}"
  category: "tech_stack | architecture | auth | data_storage | integration | deployment | testing | non_functional"
  title: "Brief title of the decision"

  statement: |
    Clear, unambiguous statement of what was decided.

  options_considered:
    - option: "Option A"
      pros:
        - "Advantage 1"
        - "Advantage 2"
      cons:
        - "Disadvantage 1"
    - option: "Option B"
      pros:
        - "Advantage 1"
      cons:
        - "Disadvantage 1"
        - "Disadvantage 2"

  selected: "Option A"

  rationale: |
    Why this option was chosen over alternatives.
    Reference specific requirements or constraints.

  implications:
    enables:
      - "What this decision makes possible"
    constrains:
      - "What this decision limits or rules out"
    requires:
      - "What must also be true for this to work"

  confidence: "high"  # After R6, all should be high
  confirmed_by: "user | inferred_accepted"
  reversibility: "easy | moderate | hard"

  reversal_cost: |
    What it would take to change this decision later.
    Only required if reversibility = "hard"

  related_decisions: ["DEC-XXX-001", "DEC-XXX-002"]
  related_edge_cases: ["EC-XXX-001"]

  metadata:
    source_round: 6
    originally_inferred_in: "R1 | R2 | R3 | R4 | R5 | R6"
    locked_at: "{{ ISO_DATE }}"
```

---

## Assumption Audit

### Assumption Collection Protocol

Collect all assumptions from R1-R5:

```
For each round R1-R5:
  For each item with assumptions array:
    Extract assumption
    Note source_round, affected_nodes, original_confidence
    Categorize by validation status
```

### Assumption Categories

| Status | Meaning | Action Required |
|--------|---------|-----------------|
| validated | Explicitly confirmed by user | None — ready for build |
| needs_validation | Reasonable inference, not confirmed | Present to user for confirmation |
| accepted_risk | User acknowledged uncertainty, proceed anyway | Document in risk register |
| invalidated | Found to be incorrect | Update affected nodes |

### Assumption Resolution Table

| ID | Source | Assumption | Category | Risk If Wrong | Status | Resolution |
|----|--------|------------|----------|---------------|--------|------------|
| AS-001 | R1 | [Assumption text] | tech_stack | [Impact] | needs_validation | [Pending/Validated/Risk Accepted] |
| AS-002 | R2 | [Assumption text] | data_model | [Impact] | validated | User confirmed |
| AS-003 | R3 | [Assumption text] | workflow | [Impact] | accepted_risk | Proceed with monitoring |

### Assumption Audit Template

```yaml
assumption:
  id: "AS-{SOURCE_ROUND}-{NUMBER}"
  source_round: "R1 | R2 | R3 | R4 | R5"
  original_confidence: "high | medium | low"

  statement: |
    The assumption as originally documented.

  affected_nodes:
    - "node_id_1"
    - "node_id_2"

  risk_if_wrong: |
    What breaks or needs rework if this assumption is incorrect.

  evidence:
    supports:
      - "Evidence supporting the assumption"
    contradicts:
      - "Evidence against (if any)"

  validation_method: "user_confirmation | documentation | testing | none"

  status: "validated | needs_validation | accepted_risk | invalidated"

  resolution:
    final_status: "validated | accepted_risk"
    confirmed_by: "user | inferred"
    notes: "Any clarification or context"
    resolved_at: "{{ ISO_DATE }}"
```

---

## Readiness Gate Check

### Gate Verification Protocol

Before completing R6, verify all readiness gates:

```yaml
readiness_gates:
  all_rounds_complete:
    check: "R1-R5 status = 'complete'"
    current_status: pending | pass | fail
    blocking_rounds: []

  no_hard_blockers:
    check: "Zero blocking_issues with severity = 'hard'"
    current_status: pending | pass | fail
    hard_blockers: []

  confidence_threshold_met:
    check: "No core entities/workflows/screens at 'low' confidence"
    current_status: pending | pass | fail
    low_confidence_items: []

  modules_validated:
    check: "modules.selected.length > 0"
    current_status: pending | pass | fail
    selected_modules: []

  # New gates added by R6
  tech_stack_decided:
    check: "All tech stack decisions have high confidence"
    current_status: pending | pass | fail
    undecided_items: []

  architecture_locked:
    check: "Architecture pattern confirmed"
    current_status: pending | pass | fail
    pending_decisions: []

  hard_reversibility_confirmed:
    check: "All hard-to-reverse decisions have user confirmation"
    current_status: pending | pass | fail
    unconfirmed_decisions: []
```

### Gate Resolution

For each failing gate:

| Gate | Resolution Path |
|------|-----------------|
| all_rounds_complete | Return to incomplete round |
| no_hard_blockers | Present blockers to user, get resolution |
| confidence_threshold_met | Validate low-confidence items with user |
| modules_validated | Return to R1.5 or confirm module selections |
| tech_stack_decided | Ask clarifying questions, document decision |
| architecture_locked | Present options, get explicit choice |
| hard_reversibility_confirmed | Highlight implications, require confirmation |

---

## Output Template

### Decision Log

#### Tech Stack Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-TECH-001 | Primary Language | Python 3.11 | high | user | hard |
| DEC-TECH-002 | Web Framework | FastAPI | high | user | moderate |
| DEC-TECH-003 | Database | PostgreSQL | high | user | hard |
| DEC-TECH-004 | Hosting | AWS | high | inferred_accepted | moderate |

#### Architecture Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-ARCH-001 | Application Pattern | Modular Monolith | high | user | hard |
| DEC-ARCH-002 | API Style | REST | high | user | moderate |
| DEC-ARCH-003 | Event Pattern | Async with queues | high | inferred_accepted | moderate |

#### Authentication Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-AUTH-001 | Auth Method | OAuth + email/password | high | user | moderate |
| DEC-AUTH-002 | Permission Model | RBAC | high | user | moderate |

#### Data Storage Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-DATA-001 | Schema Approach | Alembic migrations | high | inferred_accepted | easy |
| DEC-DATA-002 | ORM Strategy | SQLAlchemy | high | user | moderate |
| DEC-DATA-003 | Caching | Redis | high | user | easy |

#### Integration Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-INT-001 | API Call Pattern | Async background jobs | high | user | moderate |
| DEC-INT-002 | Error Handling | Retry with exponential backoff | high | inferred_accepted | easy |

#### Deployment Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-DEP-001 | CI/CD | GitHub Actions | high | user | easy |
| DEC-DEP-002 | Environments | dev/staging/prod | high | inferred_accepted | easy |
| DEC-DEP-003 | Containerization | Docker | high | user | moderate |

#### Testing Decisions

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-TEST-001 | Unit Testing | pytest, 80% coverage target | high | user | easy |
| DEC-TEST-002 | Integration Testing | Testcontainers | high | inferred_accepted | easy |
| DEC-TEST-003 | E2E Testing | Playwright | high | user | easy |

#### Non-Functional Requirements

| ID | Decision | Selected | Confidence | Confirmed By | Reversibility |
|----|----------|----------|------------|--------------|---------------|
| DEC-NFR-001 | Performance | API < 200ms p95 | high | user | moderate |
| DEC-NFR-002 | Security | TLS, encryption at rest | high | user | moderate |

---

### Decision Details

For each hard-to-reverse decision, include full specification:

```yaml
decision:
  id: "DEC-TECH-001"
  category: "tech_stack"
  title: "Primary Programming Language"
  # ... full specification from template
```

---

### Assumption Register

#### Validated Assumptions

| ID | Source | Assumption | Validated By |
|----|--------|------------|--------------|
| AS-R1-001 | R1 | Solo developer building the system | User confirmed |
| AS-R2-003 | R2 | Client names are unique | User confirmed |

#### Accepted Risks

| ID | Source | Assumption | Risk If Wrong | Mitigation |
|----|--------|------------|---------------|------------|
| AS-R3-002 | R3 | External API has 99.9% uptime | Workflow failures | Circuit breaker, retry logic |

---

### Readiness Summary

```yaml
readiness:
  overall_status: "READY | NOT_READY"
  gates:
    all_rounds_complete: pass
    no_hard_blockers: pass
    confidence_threshold_met: pass
    modules_validated: pass
    tech_stack_decided: pass
    architecture_locked: pass
    hard_reversibility_confirmed: pass

  blocking_items: []  # Should be empty if READY

  proceed_to_r7: true | false
```

---

### Risk Register

Risks accepted during lock-in that should be monitored:

| ID | Category | Description | Likelihood | Impact | Mitigation | Owner |
|----|----------|-------------|------------|--------|------------|-------|
| RISK-001 | integration | External API availability | possible | moderate | Circuit breaker | Dev team |
| RISK-002 | scalability | Unknown growth rate | possible | major | Auto-scaling ready | Ops |

---

## Validation Checklist

R6 cannot be marked complete until all items are checked:

### Required (Blocks Completion)

- [ ] All medium/low confidence items from R1-R5 reviewed
- [ ] All tech stack decisions documented with high confidence
- [ ] Architecture pattern confirmed and locked
- [ ] Authentication method confirmed and locked
- [ ] All hard-to-reverse decisions have explicit user confirmation
- [ ] No unvalidated assumptions remain (all are validated or accepted_risk)
- [ ] All readiness gates pass
- [ ] No hard blockers remain unresolved

### Quality Checks

- [ ] Each decision has clear rationale
- [ ] Reversibility is accurately assessed
- [ ] Related decisions are cross-referenced
- [ ] Implications (enables/constrains) are documented
- [ ] Risk register includes all accepted risks

### Final Verification

- [ ] User has reviewed the decision log
- [ ] User confirms readiness to proceed to build planning
- [ ] Any concerns or reservations are documented

---

## State Update

When R6 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R6": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "decisions_count": {{ decisions_count }},
      "assumptions_validated": {{ validated_count }},
      "risks_accepted": {{ risks_count }}
    }
  },
  "current_round": "R7",
  "readiness": "READY",

  "decisions": [
    {
      "id": "DEC-TECH-001",
      "category": "tech_stack",
      "title": "Primary Language",
      "selected": "Python 3.11",
      "confidence": "high",
      "confirmed_by": "user",
      "reversibility": "hard",
      "locked_at": "{{ ISO_DATE }}"
    }
  ],

  "readiness_gates": {
    "all_rounds_complete": true,
    "no_hard_blockers": true,
    "confidence_threshold_met": true,
    "modules_validated": true,
    "tech_stack_decided": true,
    "architecture_locked": true,
    "hard_reversibility_confirmed": true
  }
}
```

---

## Next Steps

After R6 completes:

1. Save as `discovery/R6_DECISIONS.md`
2. Update `discovery-state.json` with:
   - All locked decisions
   - Updated readiness gates (all should be true)
   - readiness = "READY"
3. Verify no remaining concerns
4. Proceed to **R7: Build Plan Auto-Generation**

R7 will use:
- All locked decisions to structure the build
- Parallelization data from R3 to create waves
- Node specifications with confirmed confidence levels
- Accepted risks as monitoring points during build

---

## Quick Reference

### Reversibility Assessment

| Level | Definition | Examples |
|-------|------------|----------|
| **easy** | Can change with minimal effort, limited blast radius | Test framework, linting rules, code formatting |
| **moderate** | Requires meaningful refactoring but contained | ORM choice, caching layer, CI/CD provider |
| **hard** | Fundamental change affecting entire system | Primary language, database type, core architecture pattern |

### Confirmation Requirements by Reversibility

```
hard → MUST have explicit user confirmation ("Yes, proceed with X")
moderate → SHOULD confirm, can accept reasonable inference with documentation
easy → Document decision, proceed (user can adjust during build)
```

### Decision Category Priority

When time is limited, focus on these categories first:

1. **Tech Stack** — Affects everything downstream
2. **Architecture** — Hard to change, shapes all implementation
3. **Auth** — Security implications, affects many screens/workflows
4. **Data Storage** — Schema decisions cascade through system
5. **Non-Functional** — May require architectural changes if missed
6. **Integration** — Important but often more flexible
7. **Deployment** — Can often be adjusted during build
8. **Testing** — Most flexible, can evolve with codebase

### Red Flags That Block Completion

- Any decision with confidence = "low" after user discussion
- Hard-to-reverse decision without explicit user confirmation
- Conflicting decisions (e.g., "stateless JWT" + "server-side sessions")
- Unresolved hard blockers from any round
- User expresses uncertainty about a core decision
- Missing decisions in critical categories (tech stack, architecture)
