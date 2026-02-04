# Round 1: Context & Intent

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 5-10 minutes

---

## Purpose

Round 1 establishes the foundation for all discovery. We capture:
- **The Problem** — What pain exists and for whom
- **The Actors** — Who uses the system and what they need
- **The Environment** — Technical context and constraints
- **Constraints** — Hard limits that shape the solution

Everything captured here feeds into module selection (R1.5) and all subsequent rounds.

---

## Instructions for Boss Agent

### Questioning Protocol

**Step 1: Open Exploration (2-3 minutes)**

Start with: *"Tell me about what you're building and the problem it solves."*

Listen for implicit answers to:
- Problem description
- Who experiences the problem
- What "done" looks like
- User types and their goals
- Technical preferences

**Step 2: Gap-Filling Questions**

Only ask questions whose answers were NOT covered in Step 1:

**Problem (if gaps exist)**
- "Who experiences this problem most acutely?"
- "What happens if this problem isn't solved?"
- "How do they cope with it today?"

**Actors (if gaps exist)**
- "Besides [mentioned users], who else will use this?"
- "Are there admin or back-office users?"
- "What's the most important thing [actor] needs to accomplish?"

**Environment (if gaps exist)**
- "Web, mobile, desktop, or a combination?"
- "Does it need to work offline?"
- "What existing systems must it integrate with?"

**Constraints (if gaps exist)**
- "Is there an existing tech stack you need to use?"
- "What's your timeline?"
- "Any compliance requirements (HIPAA, SOC2, GDPR)?"

**Step 3: Confirm Inferences**

For each medium/low confidence item, confirm explicitly:
- "I understood [X] - is that correct?"

### Inference Guidelines

| Confidence | When to Use | Example |
|------------|-------------|---------|
| high | User explicitly stated | "We need to track billable hours" |
| medium | Strongly implied by context | User mentions "invoices" → invoice generation |
| low | Reasonable assumption | Web app → desktop-first responsive |

---

## Output Template

### Problem Statement

```yaml
one_liner: |
  [1 sentence: Who has what problem that this solves]

who_affected:
  primary: [Who feels the pain most]
  secondary: [Others affected]

pain_level: [critical | high | medium | low]

current_workaround: |
  [How they cope today without this solution]

cost_of_inaction: |
  [What happens if problem persists]

success_criteria:
  - [Criterion 1: Specific, measurable outcome]
  - [Criterion 2: Specific, measurable outcome]
  - [Criterion 3: Specific, measurable outcome]

confidence: [high | medium | low]
source: |
  [Quote or summary of what user said]
```

### Actors

| Actor | Type | Primary Goal | Frequency | Confidence | Source |
|-------|------|--------------|-----------|------------|--------|
| [Name] | primary | [What they want to accomplish] | [daily/weekly/monthly] | [high/medium/low] | [What user said] |
| [Name] | secondary | [Goal] | [frequency] | [confidence] | [source] |

### Environment

| Aspect | Decision | Confidence | Notes |
|--------|----------|------------|-------|
| Platform | [web / mobile / desktop / hybrid] | [confidence] | [Why] |
| Offline | [yes / no / partial] | [confidence] | [Which features] |
| Responsive | [mobile-first / desktop-first / both] | [confidence] | [Primary device] |
| Hosting | [cloud / on-prem / hybrid / TBD] | [confidence] | [Preferences] |
| Auth | [email / OAuth / SSO / none / TBD] | [confidence] | [Requirements] |

**Integrations Required**:

| System | Purpose | Priority | Confidence |
|--------|---------|----------|------------|
| [System name] | [Why integrate] | [must-have / nice-to-have] | [confidence] |

### Constraints

| Category | Constraint | Type | Confidence | Impact if Violated |
|----------|------------|------|------------|-------------------|
| Tech Stack | [e.g., "Must use Python"] | hard / soft | [confidence] | [What breaks] |
| Timeline | [e.g., "MVP in 8 weeks"] | hard / soft | [confidence] | [What breaks] |
| Compliance | [e.g., "HIPAA required"] | hard / soft | [confidence] | [What breaks] |
| Budget | [e.g., "No paid APIs"] | hard / soft | [confidence] | [What breaks] |
| Team | [e.g., "Solo developer"] | hard / soft | [confidence] | [What breaks] |

---

## Validation Checklist

R1 cannot be marked complete until all REQUIRED items are checked:

### Required (Blocks Completion)

- [ ] Problem one_liner captured (any confidence)
- [ ] who_affected.primary identified (medium+ confidence)
- [ ] At least 2 success_criteria defined
- [ ] At least 1 primary actor identified (high confidence)
- [ ] Primary actor's goal is clear (medium+ confidence)
- [ ] Platform decision made (any confidence)
- [ ] Timeline captured (any confidence, can be "TBD")

### Items Needing Validation

| Item | Current Assumption | Risk if Wrong | Follow-up Question |
|------|-------------------|---------------|-------------------|
| [What] | [Assumption] | [What breaks] | [Question to ask] |

---

## State Update

When R1 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R1": { "status": "complete", "completed": "{{ ISO_DATE }}" }
  },
  "current_round": "R1.5"
}
```

---

## Next Steps

After R1 completes:
1. Save as `discovery/R1_CONTEXT.md`
2. Update `discovery-state.json`
3. Proceed to R1.5: Module Selection
