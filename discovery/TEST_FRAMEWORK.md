# Discovery System Test Framework

**Version**: 1.0
**Purpose**: Stress-test the 7-round discovery system with complex scenarios
**Target**: Validate template completeness, information flow, and quality metrics

---

## 1. Test Execution Model

### 1.1 Agent Configuration

Each test run uses a **Test Boss Agent** that executes discovery rounds against a predefined scenario.

```yaml
test_execution:
  agent_type: "test_boss"
  context_window: "fresh per run"

  inputs:
    scenario_brief: "High-level description of what to build"
    user_persona: "Simulated user responses (scripted or adaptive)"
    module_hints: "Optional - suggest which modules to expect"

  outputs:
    round_artifacts: "R1_CONTEXT.md through DISCOVERY_COMPLETE.md"
    discovery_state: "discovery-state.json"
    test_report: "TEST_REPORT_<scenario>.md"
    self_report: "AGENT_SELF_REPORT.md"
```

### 1.2 Execution Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Full Run** | R1 through R7 sequentially | End-to-end validation |
| **Isolated Round** | Single round with mocked prerequisites | Round-specific debugging |
| **Parallel Stress** | R2 and R3 running simultaneously | Parallelization validation |
| **Resume Test** | Start from mid-discovery state | Resume functionality |
| **Adversarial** | User provides contradictory/minimal input | Edge case handling |

### 1.3 Agent Instructions (Per Round)

The Test Boss receives round-specific instructions:

```yaml
round_execution:
  pre_round:
    - Load prerequisite artifacts
    - Initialize round timer
    - Create round_start checkpoint

  during_round:
    - Execute round template protocol
    - Log all decisions to self_report
    - Track confidence assignments
    - Note any template gaps encountered

  post_round:
    - Save round artifact
    - Update discovery-state.json
    - Log round metrics to test_report
    - Create round_complete checkpoint
```

---

## 2. Data Collection Points

### 2.1 Self-Reporting (Agent-Generated)

Each round produces an `AGENT_NOTES_<ROUND>.md` with:

```markdown
## Agent Self-Report: Round {{ round_number }}

### Decisions Made
| Decision ID | Description | Confidence | Basis |
|-------------|-------------|------------|-------|
| DEC-R2-001 | Added audit timestamps to all entities | high | Module template pattern |
| DEC-R2-002 | Made client_id required on Application | medium | Implied from R1 actor goals |

### Information Used from Previous Rounds
| Source Round | Artifact | Section Used | How Applied |
|--------------|----------|--------------|-------------|
| R1 | R1_CONTEXT.md | Actors table | Mapped to entity ownership |
| R1.5 | discovery-state.json | modules.selected | Seeded entity templates |

### Template Gaps Encountered
| Gap ID | Template Section | Issue | Suggested Fix |
|--------|------------------|-------|---------------|
| GAP-001 | R2 Entity spec | No guidance for enum field values | Add enum value prompt |

### Open Questions Generated
| Question ID | Question | Blocking? | Deferred To |
|-------------|----------|-----------|-------------|
| OQ-001 | How does USPTO API return status? | No | R5 Edge Cases |

### Beads Created This Round
| Bead ID | Type | Summary |
|---------|------|---------|
| AS-R2-001 | Assumption | Application status follows USPTO workflow |
| DD-R2-001 | Decision | Use USPTO classifications for IP type |
```

### 2.2 Hard Data Collection (System-Measured)

```yaml
hard_metrics:
  timing:
    round_start_timestamp: ISO_DATE
    round_end_timestamp: ISO_DATE
    duration_seconds: int
    pauses_for_user_input: int

  artifact_stats:
    entities_discovered: int
    workflows_mapped: int
    screens_defined: int
    edge_cases_identified: int
    decisions_locked: int

  confidence_distribution:
    high: int
    medium: int
    low: int

  cross_references:
    r1_to_r2_references: int  # How many R2 items cite R1
    r1_to_r3_references: int
    r2_to_r4_references: int
    r3_to_r4_references: int
    r3_to_r7_parallelization_used: bool

  blocking_issues:
    hard_blockers_created: int
    soft_blockers_created: int
    blockers_resolved: int
```

### 2.3 Information Transfer Tracking

Track explicit references between rounds:

```yaml
information_flow_tracking:
  # R1 -> R2 Flow
  r1_actors_used_in_r2:
    expected: "All actors from R1 should map to entity permissions"
    measurement: "Count actors referenced in R2 entity specs"
    threshold: "100% actor coverage"

  # R1 -> R3 Flow
  r1_goals_to_r3_workflows:
    expected: "Each actor goal has corresponding workflow"
    measurement: "Map R1.actors[].goal to R3.workflows[].actor_goal"
    threshold: "100% goal coverage"

  # R2 <-> R3 Cross-validation
  r2_r3_entity_consistency:
    expected: "All entities in R3 workflows exist in R2"
    measurement: "Compare R3.workflows[].data_read/write against R2 entities"
    threshold: "0 orphan entity references"

  # R3 -> R4 Flow
  r3_steps_to_r4_screens:
    expected: "Each workflow step maps to screen or component"
    measurement: "Count workflow steps with screen assignments"
    threshold: ">95% step coverage"

  # R3 -> R7 Parallelization
  r3_tracks_in_r7:
    expected: "All R3 tracks appear as R7 phases"
    measurement: "Compare R3.parallelization.tracks to R7.phases"
    threshold: "100% track->phase mapping"
```

### 2.4 Bead Tracking Collection

```yaml
bead_tracking:
  per_round:
    decisions: "DD-RN-XXX"
    discoveries: "DS-RN-XXX"
    assumptions: "AS-RN-XXX"
    pivots: "PV-RN-XXX"
    friction: "FR-RN-XXX"

  aggregation:
    total_decisions: int
    total_assumptions: int
    assumptions_validated: int
    assumptions_accepted_risk: int
    pivots_from_original_plan: int

  assumption_lifecycle:
    - created_in_round: R2
      assumption: "USPTO API supports batch queries"
      initial_confidence: medium
      validated_in_round: R5  # or null
      final_status: "validated | accepted_risk | invalidated"
```

---

## 3. Quality Metrics

### 3.1 Completeness Metrics

```yaml
completeness:
  round_completeness:
    definition: "Did the round produce all required outputs?"
    measurement:
      R1:
        - problem_statement.one_liner: required
        - actors_table: "minimum 1 primary actor"
        - environment_table: required
        - constraints_table: required
      R1_5:
        - modules.selected: "minimum 1 module"
        - modules.packages: "minimum 1 package per module"
        - selection_rationale: required
      R2:
        - entity_summary_table: required
        - entity_specifications: "minimum 1 entity"
        - relationships: "if multiple entities"
        - erd_diagram: recommended
      R3:
        - workflows_summary: required
        - workflow_details: "minimum 1 per actor"
        - parallelization_analysis: required
        - tracks: "minimum 1"
      R4:
        - screen_inventory: required
        - entity_screen_coverage: required
        - navigation_map: required
        - routes: "for web applications"
      R5:
        - edge_case_inventory: "minimum 5 categories"
        - resolution_strategies: "for high/critical"
      R6:
        - decision_log: required
        - assumption_register: required
        - readiness_gates: "all pass"
      R7:
        - build_overview: required
        - phase_details: required
        - parallelization_map: required

  validation_checklist_pass_rate:
    definition: "Percentage of validation checklist items passed"
    threshold: "100% for Required, >80% for Recommended"
```

### 3.2 Consistency Metrics

```yaml
consistency:
  naming_consistency:
    definition: "Same entity/actor/workflow uses same name throughout"
    measurement: "Extract all names, check for variations"
    tolerance: "0 inconsistent names"

  id_consistency:
    definition: "IDs follow documented patterns"
    patterns:
      entities: "data.{namespace}.{name}"
      screens: "screen.{namespace}.{name}"
      workflows: "WF-{NNN}"
      edge_cases: "EC-{CATEGORY}-{NNN}"
      decisions: "DEC-{CATEGORY}-{NNN}"

  cross_round_reference_accuracy:
    definition: "References to previous rounds are accurate"
    measurement: "Verify cited artifact sections exist"
    tolerance: "0 broken references"

  confidence_consistency:
    definition: "Confidence levels appropriate to evidence"
    rules:
      - "User explicitly stated = high"
      - "Strongly implied = medium"
      - "Speculative = low"
    measurement: "Sample check 20% of confidence assignments"
```

### 3.3 Coverage Metrics

```yaml
coverage:
  actor_coverage:
    definition: "Every actor has workflows, screens, and permissions defined"
    measurement: "For each R1 actor, verify presence in R3, R4, R6"
    threshold: "100%"

  entity_coverage:
    definition: "Every entity has CRUD or explicit non-CRUD justification"
    measurement: "Cross-check R2 entities against R4 screens"
    threshold: "100%"

  workflow_step_coverage:
    definition: "Every workflow step has UI representation"
    measurement: "Map R3 steps to R4 screens/components"
    threshold: ">95%"

  edge_case_category_coverage:
    definition: "All edge case categories explored"
    categories:
      - data
      - timing
      - state
      - user
      - permission
      - integration (if applicable)
      - business
    threshold: "All categories have minimum 1 case"

  module_package_coverage:
    definition: "Selected packages have corresponding entities/workflows"
    measurement: "Map modules.packages to discovered nodes"
    threshold: ">80% package utilization"
```

### 3.4 Confidence Distribution Metrics

```yaml
confidence_analysis:
  distribution_health:
    definition: "Confidence spread indicates thorough discovery"
    ideal_distribution:
      high: "50-70%"
      medium: "20-40%"
      low: "<20%"
    warning_signs:
      - "100% high = not questioning enough"
      - ">30% low = insufficient user validation"
      - "0% medium = binary thinking"

  confidence_by_round:
    R1: "Should be mostly high (user-provided)"
    R1_5: "High if confirmed, medium if inferred"
    R2: "Mix - entities from modules=high, inferred attributes=medium"
    R3: "Mix - workflows from user=high, edge paths=medium"
    R4: "Lower average - more inference from R2/R3"
    R5: "Lower average - speculative edge cases"
    R6: "All should reach high after validation"
    R7: "Computed from previous rounds"

  low_confidence_resolution:
    definition: "All low confidence items addressed by R6"
    threshold: "0 low confidence items remain after R6"
```

### 3.5 Information Flow Metrics

```yaml
information_flow:
  forward_flow_score:
    definition: "How well earlier rounds inform later rounds"
    measurement:
      - "R1 actor goals -> R3 workflow success criteria (correlation)"
      - "R2 entities -> R4 data requirements (subset check)"
      - "R3 parallelization -> R7 phases (exact match)"
    scoring: "0-100 based on correlation strength"

  backward_validation_score:
    definition: "Later rounds validating earlier assumptions"
    measurement:
      - "R5 edge cases -> R2 entity updates"
      - "R4 screen needs -> R2 missing attributes"
      - "R6 decisions -> R1-R5 assumption resolution"
    scoring: "Count of backward corrections applied"

  data_cascade_integrity:
    definition: "Changes propagate correctly through rounds"
    test_method: "Inject change in R2, verify R4/R7 reflect it"
    threshold: "100% propagation"
```

---

## 4. Test Report Structure

### 4.1 Report Template

```markdown
# Discovery System Test Report

**Scenario**: {{ scenario_name }}
**Test Date**: {{ ISO_DATE }}
**Test Duration**: {{ total_time }}
**Overall Status**: {{ PASS | PARTIAL | FAIL }}

---

## Executive Summary

| Metric | Score | Threshold | Status |
|--------|-------|-----------|--------|
| Round Completeness | {{ percentage }} | 100% | {{ status }} |
| Information Flow | {{ score }}/100 | 80 | {{ status }} |
| Confidence Health | {{ percentage }} | See dist | {{ status }} |
| Coverage | {{ percentage }} | 95% | {{ status }} |
| Consistency | {{ error_count }} errors | 0 | {{ status }} |

---

## Per-Round Scores

### Round 1: Context & Intent

| Metric | Value | Expected | Status |
|--------|-------|----------|--------|
| Duration | {{ time }} | 5-10 min | {{ ok/slow/fast }} |
| Actors Identified | {{ count }} | 1+ | {{ status }} |
| Constraints Captured | {{ count }} | 1+ | {{ status }} |
| Confidence Distribution | H:{{ h }} M:{{ m }} L:{{ l }} | See guide | {{ status }} |

**Validation Checklist**:
- [x] Problem one_liner captured
- [x] Primary actor identified (high confidence)
- [x] Platform decision made
- [ ] Timeline captured -- MISSING

**Information Generated**:
- {{ count }} actors -> feeds R3 workflows
- {{ count }} constraints -> feeds R6 decisions

**Beads Created**:
| ID | Type | Summary |
|----|------|---------|
| AS-R1-001 | Assumption | {{ summary }} |

---

### Round 1.5: Module Selection
{{ ... similar structure ... }}

### Round 2: Entities
{{ ... similar structure ... }}

### Round 3: Workflows
{{ ... similar structure ... }}

### Round 4: Screens
{{ ... similar structure ... }}

### Round 5: Edge Cases
{{ ... similar structure ... }}

### Round 6: Technical Lock-In
{{ ... similar structure ... }}

### Round 7: Build Plan
{{ ... similar structure ... }}

---

## Cross-Round Information Flow Analysis

### Forward Flow (Earlier -> Later)

```
R1 Actors ──────────────────────────────────┐
   └── {{ actor_count }} actors defined     │
                                            v
R3 Workflows ────────────────────────── {{ coverage }}% actor coverage
   └── {{ workflow_count }} workflows       │
                                            v
R4 Screens ─────────────────────────── {{ coverage }}% workflow coverage
   └── {{ screen_count }} screens           │
                                            v
R7 Build Plan ──────────────────────── {{ coverage }}% screen inclusion
   └── {{ node_count }} nodes queued
```

### Parallelization Flow (R3 -> R7)

| R3 Track | R7 Phase | Workflows Mapped | Status |
|----------|----------|------------------|--------|
| {{ track_name }} | Phase {{ n }} | {{ count }} | {{ ok/missing }} |

### Information Loss Points

| From | To | Expected | Actual | Lost |
|------|----|----------|--------|------|
| R1 actors | R3 workflows | {{ expected }} | {{ actual }} | {{ lost_items }} |
| R2 entities | R4 screens | {{ expected }} | {{ actual }} | {{ lost_items }} |

---

## Gap Detection

### Template Gaps Found

| Round | Template Section | Gap Description | Impact |
|-------|------------------|-----------------|--------|
| R2 | Entity Spec | No guidance for calculated fields | Medium |
| R4 | Screen Spec | Missing offline state definition | High |

### Coverage Gaps

| Category | Gap Description | Affected Items |
|----------|-----------------|----------------|
| Entity Coverage | {{ entity }} has no screen | {{ entity_id }} |
| Workflow Coverage | Step {{ n }} has no UI | WF-{{ id }} |

### Consistency Violations

| Type | Location | Issue | Severity |
|------|----------|-------|----------|
| Naming | R2/R4 | "Application" vs "IPApplication" | High |
| ID Format | R3 | WF-A01 instead of WF-001 | Low |

---

## Readiness Assessment

### Readiness Gates

| Gate | Status | Notes |
|------|--------|-------|
| all_rounds_complete | {{ status }} | {{ notes }} |
| no_hard_blockers | {{ status }} | {{ blocker_count }} blockers |
| confidence_threshold_met | {{ status }} | {{ low_count }} low items |
| modules_validated | {{ status }} | {{ module_count }} modules |

### Overall Readiness

**Status**: {{ READY | NOT_READY | CONDITIONAL }}

**Blocking Issues**:
{{ list of issues preventing readiness }}

**Recommendations**:
{{ list of improvements for next run }}

---

## Bead Summary

### By Type
| Type | Count | Examples |
|------|-------|----------|
| Decisions | {{ count }} | DD-R2-001, DD-R6-003 |
| Assumptions | {{ count }} | AS-R1-001, AS-R3-002 |
| Discoveries | {{ count }} | DS-R4-001 |
| Pivots | {{ count }} | PV-R5-001 |

### Assumption Lifecycle
| ID | Created | Status | Resolution |
|----|---------|--------|------------|
| AS-R1-001 | R1 | Validated | Confirmed in R5 |
| AS-R2-003 | R2 | Accepted Risk | User acknowledged |
| AS-R3-001 | R3 | Invalidated | Corrected in R5 |

---

## Test Artifacts

| Artifact | Location | Size | Status |
|----------|----------|------|--------|
| R1_CONTEXT.md | discovery/R1_CONTEXT.md | {{ size }} | Generated |
| R2_ENTITIES.md | discovery/R2_ENTITIES.md | {{ size }} | Generated |
| ... | ... | ... | ... |
| discovery-state.json | discovery/discovery-state.json | {{ size }} | Generated |
| DISCOVERY_COMPLETE.md | discovery/DISCOVERY_COMPLETE.md | {{ size }} | Generated |

---

## Appendix: Raw Metrics

### Timing Data
{{ JSON of all timestamps }}

### Confidence Data
{{ JSON of all confidence assignments }}

### Cross-Reference Data
{{ JSON of all cross-round references }}
```

---

## 5. Test Scenarios

### 5.1 Primary Scenario: IP/Trademark Engine

```yaml
scenario:
  id: "SCENARIO-001"
  name: "Autonomous IP Submission Engine"
  complexity: "high"

  brief: |
    An agentic/autonomous engine to submit intellectual property
    for trademark patents. The system should:
    - Accept IP descriptions from inventors
    - Research prior art automatically
    - Draft trademark applications
    - Submit to USPTO via API
    - Track application status
    - Handle office actions and responses

  expected_modules:
    primary:
      - documents: "Application drafts, supporting documents"
      - compliance: "USPTO regulations, filing requirements"
      - project: "Application tracking, deadlines"
    secondary:
      - communication: "Notifications, USPTO correspondence"
      - financial: "Filing fees, attorney fees"

  expected_entities:
    - Application: "Core IP submission record"
    - Inventor: "Person or company filing"
    - PriorArt: "Related existing patents/trademarks"
    - Filing: "USPTO submission instance"
    - OfficeAction: "USPTO response requiring action"
    - Amendment: "Changes to application"
    - Payment: "Fee tracking"

  expected_workflows:
    - "Submit New Application" (inventor -> system -> USPTO)
    - "Research Prior Art" (autonomous agent)
    - "Respond to Office Action" (inventor + agent)
    - "Track Application Status" (polling/webhook)
    - "Process Payment" (fees to USPTO)

  parallelization_opportunities:
    track_a: "Application Management" (CRUD, status tracking)
    track_b: "AI Research Agent" (prior art, classification)
    track_c: "USPTO Integration" (API calls, webhooks)

  edge_cases_to_probe:
    - "USPTO API rate limiting"
    - "Application rejected - appeal workflow"
    - "Multiple inventors, shared ownership"
    - "International filing (Madrid Protocol)"
    - "Deadline approaching with incomplete application"
    - "Office action response window expiring"

  simulated_user_responses:
    r1_context:
      problem: "IP attorneys spend 40+ hours per application on research and drafting. Small inventors can't afford the process."
      actors:
        - "Individual inventor (self-filing)"
        - "IP attorney (guided filing)"
        - "Corporate IP team (bulk filing)"
      environment: "Web application, USPTO API integration required"
      constraints:
        - "Must comply with USPTO electronic filing requirements"
        - "Cannot practice law - advisory only"
        - "Must handle PII securely"
```

### 5.2 Diverse Scenario: Field Service Dispatch

```yaml
scenario:
  id: "SCENARIO-002"
  name: "HVAC Field Service Dispatch"
  complexity: "medium"

  brief: |
    A dispatch system for an HVAC service company. Technicians
    work in the field with tablets, often in basements with no
    signal. Dispatchers need real-time visibility. Customers
    want appointment windows and status updates.

  expected_modules:
    primary:
      - field_service: "dispatch, mobile, offline_sync, inspections"
      - crm: "customer_management, interaction_tracking"
    secondary:
      - financial: "invoicing, payments"
      - administrative: "calendar, tasks"

  unique_challenges:
    - "Offline-first mobile app"
    - "GPS tracking and route optimization"
    - "Photo capture for before/after"
    - "Customer signature capture"
    - "Inventory on truck"

  parallelization_opportunities:
    track_a: "Office Operations" (dispatch, scheduling)
    track_b: "Field App" (mobile, offline, inspections)
    track_c: "Customer Portal" (booking, status, payments)
```

### 5.3 Diverse Scenario: SaaS Subscription Platform

```yaml
scenario:
  id: "SCENARIO-003"
  name: "Multi-Tenant SaaS Subscription Platform"
  complexity: "high"

  brief: |
    A platform for managing software subscriptions with
    multi-tenancy, usage-based billing, and self-service
    customer portal.

  expected_modules:
    primary:
      - financial: "invoicing, payments, accounts_receivable"
      - crm: "customer_management, lifecycle"
      - compliance: "audit_trail, data_isolation"
    secondary:
      - reporting: "dashboards, exports"
      - communication: "notifications, email"

  unique_challenges:
    - "Multi-tenant data isolation"
    - "Usage metering and billing"
    - "Stripe/payment processor integration"
    - "Self-service plan upgrades/downgrades"
    - "Proration calculations"
    - "Dunning and failed payment handling"

  parallelization_opportunities:
    track_a: "Subscription Management" (plans, features, tenants)
    track_b: "Billing Engine" (invoicing, payments, metering)
    track_c: "Customer Portal" (self-service, usage dashboard)
```

### 5.4 Diverse Scenario: Healthcare Appointment Booking

```yaml
scenario:
  id: "SCENARIO-004"
  name: "Healthcare Appointment Scheduling"
  complexity: "high"

  brief: |
    A HIPAA-compliant appointment scheduling system for a
    multi-location medical practice with multiple providers,
    insurance verification, and patient portal.

  expected_modules:
    primary:
      - administrative: "calendar, contacts"
      - compliance: "audit_trail, hipaa_controls"
      - communication: "notifications, reminders"
    secondary:
      - financial: "copays, insurance billing"
      - reporting: "utilization, no-shows"

  unique_challenges:
    - "HIPAA compliance throughout"
    - "Provider availability vs patient preference"
    - "Insurance eligibility verification"
    - "Waitlist management"
    - "Telehealth vs in-person routing"
    - "Multi-location scheduling"

  parallelization_opportunities:
    track_a: "Provider Management" (schedules, availability)
    track_b: "Patient Experience" (booking, portal, reminders)
    track_c: "Insurance/Billing" (verification, copays)
```

---

## 6. Test Execution Protocol

### 6.1 Pre-Test Setup

```bash
# 1. Create test directory
mkdir -p test_runs/$(date +%Y%m%d)_${SCENARIO_ID}

# 2. Initialize clean discovery folder
cp -r discovery/templates test_runs/$(date +%Y%m%d)_${SCENARIO_ID}/discovery/

# 3. Create scenario input file
cat > test_runs/.../scenario_input.md << EOF
{{ scenario_brief }}
EOF

# 4. Initialize test state
cat > test_runs/.../test_state.json << EOF
{
  "scenario_id": "${SCENARIO_ID}",
  "started_at": "{{ ISO_DATE }}",
  "current_round": "R1",
  "metrics": {}
}
EOF
```

### 6.2 Round Execution Protocol

For each round:

1. **Checkpoint Start**
   ```bash
   git add -A && git commit -m "test: checkpoint before R${N}"
   ```

2. **Execute Round**
   - Load round template
   - Execute with scenario context
   - Capture all outputs

3. **Collect Metrics**
   - Parse round artifact for metrics
   - Update test_state.json
   - Generate AGENT_NOTES_R${N}.md

4. **Checkpoint End**
   ```bash
   git add -A && git commit -m "test: complete R${N} for ${SCENARIO_ID}"
   ```

### 6.3 Post-Test Analysis

```python
def analyze_test_run(test_dir):
    """
    Analyze completed test run and generate report.
    """
    # Load all artifacts
    r1_context = load_artifact(f"{test_dir}/discovery/R1_CONTEXT.md")
    r2_entities = load_artifact(f"{test_dir}/discovery/R2_ENTITIES.md")
    # ... load all artifacts

    state = load_json(f"{test_dir}/discovery/discovery-state.json")

    # Calculate metrics
    metrics = {
        "completeness": calculate_completeness(artifacts),
        "consistency": check_consistency(artifacts),
        "coverage": measure_coverage(artifacts),
        "information_flow": trace_information_flow(artifacts),
        "confidence_health": analyze_confidence(state),
    }

    # Detect gaps
    gaps = {
        "template_gaps": find_template_gaps(agent_notes),
        "coverage_gaps": find_coverage_gaps(artifacts),
        "consistency_violations": find_inconsistencies(artifacts),
    }

    # Generate report
    report = generate_test_report(metrics, gaps, artifacts)

    return report
```

---

## 7. Automation Hooks

### 7.1 Metric Collection Scripts

```python
# metrics/completeness.py
def check_round_completeness(round_artifact, round_schema):
    """
    Verify all required sections present in round artifact.
    """
    required = round_schema["required_sections"]
    present = extract_sections(round_artifact)

    missing = [s for s in required if s not in present]

    return {
        "complete": len(missing) == 0,
        "missing": missing,
        "percentage": (len(present) / len(required)) * 100
    }

# metrics/information_flow.py
def trace_r1_to_r3_flow(r1_context, r3_workflows):
    """
    Verify R1 actors have corresponding R3 workflows.
    """
    r1_actors = extract_actors(r1_context)
    r3_actors = extract_workflow_actors(r3_workflows)

    coverage = len(r3_actors & r1_actors) / len(r1_actors)
    missing = r1_actors - r3_actors

    return {
        "coverage_percentage": coverage * 100,
        "missing_actors": list(missing),
        "status": "pass" if coverage == 1.0 else "fail"
    }

# metrics/confidence.py
def analyze_confidence_distribution(state):
    """
    Check confidence distribution is healthy.
    """
    entities = state["entities"]

    dist = Counter(e["confidence"] for e in entities)
    total = sum(dist.values())

    percentages = {k: (v/total)*100 for k, v in dist.items()}

    # Check health
    healthy = (
        percentages.get("high", 0) >= 50 and
        percentages.get("low", 0) < 20
    )

    return {
        "distribution": percentages,
        "healthy": healthy,
        "warnings": generate_confidence_warnings(percentages)
    }
```

### 7.2 Report Generation

```python
# reporting/generator.py
def generate_test_report(metrics, gaps, artifacts, scenario):
    """
    Generate comprehensive test report from collected data.
    """
    template = load_template("TEST_REPORT_TEMPLATE.md")

    report = template.render(
        scenario=scenario,
        timestamp=datetime.now().isoformat(),

        # Executive summary
        overall_status=calculate_overall_status(metrics),
        summary_table=generate_summary_table(metrics),

        # Per-round details
        round_reports=[
            generate_round_report(r, metrics, artifacts)
            for r in ["R1", "R1.5", "R2", "R3", "R4", "R5", "R6", "R7"]
        ],

        # Cross-round analysis
        information_flow=generate_flow_analysis(metrics),

        # Gaps
        template_gaps=gaps["template_gaps"],
        coverage_gaps=gaps["coverage_gaps"],
        consistency_violations=gaps["consistency_violations"],

        # Readiness
        readiness_assessment=generate_readiness(metrics, gaps),

        # Beads
        bead_summary=generate_bead_summary(artifacts),
    )

    return report
```

---

## 8. Success Criteria

### 8.1 Test Pass Criteria

A test scenario **PASSES** if:

| Criterion | Threshold |
|-----------|-----------|
| All rounds produce artifacts | 100% |
| Validation checklists pass | 100% Required, >80% Recommended |
| Information flow score | >80/100 |
| Coverage metrics | >95% |
| Consistency errors | 0 |
| Readiness gates | All pass |
| No hard blockers remain | True |
| Low confidence items resolved | 100% by R6 |

### 8.2 Test Partial Criteria

A test scenario is **PARTIAL** if:

- Some non-critical gaps exist
- Information flow score 60-80
- Coverage 80-95%
- Soft blockers remain but documented

### 8.3 Test Fail Criteria

A test scenario **FAILS** if:

- Any round fails to produce artifact
- Hard blockers remain unresolved
- Information flow score <60
- Coverage <80%
- Consistency errors >5
- Critical readiness gates fail

---

## 9. Iteration Protocol

### 9.1 After Test Failure

1. **Identify Root Cause**
   - Template gap?
   - Agent instruction unclear?
   - Scenario too complex?

2. **Update Templates**
   - Add missing guidance
   - Clarify ambiguous sections
   - Add examples

3. **Re-run Failed Round**
   - Isolate the round
   - Test with fix applied

4. **Full Regression**
   - Re-run complete scenario
   - Verify fix didn't break other rounds

### 9.2 Template Improvement Cycle

```
Test Run -> Gaps Found -> Template Update -> Re-Test -> Validate Fix
     ^                                                       |
     └───────────────────────────────────────────────────────┘
```

---

## 10. Appendix: Metric Collection Schemas

### 10.1 Round Metrics Schema

```json
{
  "round": "R2",
  "timestamp": "2026-01-26T10:00:00Z",
  "duration_seconds": 720,

  "completeness": {
    "required_sections_present": 8,
    "required_sections_total": 8,
    "recommended_sections_present": 5,
    "recommended_sections_total": 6,
    "percentage": 100
  },

  "outputs": {
    "entities_count": 7,
    "relationships_count": 12,
    "attributes_total": 45
  },

  "confidence": {
    "high": 5,
    "medium": 2,
    "low": 0
  },

  "cross_references": {
    "r1_references": 4,
    "r1_5_references": 2
  },

  "beads_created": [
    {"id": "AS-R2-001", "type": "assumption"},
    {"id": "DD-R2-001", "type": "decision"}
  ],

  "issues": {
    "hard_blockers": 0,
    "soft_blockers": 1,
    "warnings": 2
  }
}
```

### 10.2 Information Flow Schema

```json
{
  "flow_id": "R1_to_R3",
  "source_round": "R1",
  "target_round": "R3",

  "source_items": {
    "type": "actors",
    "count": 3,
    "ids": ["inventor", "attorney", "corporate_team"]
  },

  "target_items": {
    "type": "workflows",
    "count": 5,
    "actor_references": ["inventor", "attorney", "corporate_team"]
  },

  "coverage": {
    "percentage": 100,
    "missing": [],
    "extra": []
  },

  "quality": {
    "explicit_references": 3,
    "implicit_references": 2,
    "score": 85
  }
}
```

### 10.3 Gap Schema

```json
{
  "gap_id": "GAP-R2-001",
  "round": "R2",
  "type": "template_gap",

  "location": {
    "template": "ROUND_2_ENTITIES.md",
    "section": "Entity Specification Template"
  },

  "description": "No guidance for handling calculated/derived fields",

  "impact": {
    "severity": "medium",
    "affected_scenarios": ["all"],
    "workaround": "Agent improvised with implementation_notes field"
  },

  "suggested_fix": "Add calculated_fields array to entity spec with formula and dependencies"
}
```
