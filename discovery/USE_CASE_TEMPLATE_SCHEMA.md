# Use Case Template Schema

The structured output produced by Conversational Discovery. This template gets progressively populated during a natural conversation and serves as the handoff to R2-R7.

---

## Schema Definition

```yaml
use_case:
  # --- IDENTITY ---
  project_name: string           # Required. Short name for the project.
  created: ISO_DATE              # Auto-populated.
  status: pending | complete     # Flips to complete after user checkpoint approval.

  # --- PROBLEM ---
  problem:
    one_liner: string            # Required. One sentence: who has what problem.
    who_affected:
      primary: string            # Required. Who feels the pain most.
      secondary: string          # Optional. Others affected.
    pain_level: critical | high | medium | low  # Required.
    current_workaround: string   # Required. How they cope today.
    cost_of_inaction: string     # Optional. What happens if unsolved.
    success_criteria:            # Required. At least 2 items.
      - string

  # --- ACTORS ---
  actors:                        # Required. At least 1 primary actor.
    - name: string               # Required.
      type: primary | secondary | system  # Required.
      goal: string               # Required. What they want to accomplish.
      frequency: daily | weekly | monthly | occasional  # Required.
      confidence: high | medium | low
      source: string             # What the user said that revealed this actor.

  # --- ENVIRONMENT ---
  environment:
    platform: web | mobile | desktop | hybrid  # Required.
    offline: yes | no | partial                 # Required.
    responsive: mobile-first | desktop-first | both  # Optional.
    hosting: cloud | on-prem | hybrid | TBD     # Optional.
    auth: email | oauth | sso | none | TBD      # Optional.

  integrations:                  # Optional.
    - system: string
      purpose: string
      priority: must-have | nice-to-have
      confidence: high | medium | low

  # --- CONSTRAINTS ---
  constraints:                   # Optional but downstream rounds benefit.
    - category: tech_stack | timeline | compliance | budget | team | legal | security
      constraint: string
      type: hard | soft
      confidence: high | medium | low
      impact_if_violated: string

  # --- MODULES ---
  modules:
    selected:                    # Required. At least 1 module.
      - module: string           # Module ID from the 13-module catalog.
        packages:                # Required. At least 1 package per module.
          - string
        priority: primary | secondary
        rationale: string        # Why this module matched.
    rejected:                    # Optional. Modules considered but excluded.
      - module: string
        reason: string
    gaps:                        # Optional. Needs not covered by any module.
      - string

  # --- ASSUMPTIONS ---
  assumptions:                   # Optional.
    - id: string                 # AS-NNN format.
      description: string
      confidence: high | medium | low
      validation_needed: boolean

  # --- VALIDATION ---
  validation:
    items_needing_confirmation:  # Medium/low confidence items surfaced to user.
      - item: string
        current_assumption: string
        risk_if_wrong: string
        follow_up_question: string
```

---

## Required Fields Checklist

These fields MUST be populated before the template is considered complete. This matches the R1 + R1.5 validation gates:

| # | Field | Minimum Threshold |
|---|-------|-------------------|
| 1 | `problem.one_liner` | Any confidence |
| 2 | `problem.who_affected.primary` | Medium+ confidence |
| 3 | `problem.success_criteria` | At least 2 items |
| 4 | `actors` | At least 1 primary actor, high confidence |
| 5 | `actors[0].goal` | Medium+ confidence |
| 6 | `environment.platform` | Any confidence |
| 7 | `constraints` with `category: timeline` | Any confidence (can be "TBD") |
| 8 | `modules.selected` | At least 1 module with at least 1 package |
| 9 | `modules.selected` user confirmed | User approved at checkpoint |

---

## How Downstream Rounds Use This Template

| Round | Fields Consumed | Purpose |
|-------|----------------|---------|
| R2 (Entities) | `modules.selected.packages`, `actors`, `problem` | Seed entity templates from packages; actor goals inform entity attributes |
| R3 (Workflows) | `actors` + goals, `modules.selected`, `problem.success_criteria` | Actor goals become workflow triggers; success criteria become end states |
| R4 (Screens) | `actors`, `environment.platform`, `environment.responsive` | Actor count drives navigation; platform drives layout |
| R5 (Edge Cases) | `constraints`, `integrations`, `modules.selected` | Constraints generate edge cases; integrations generate failure modes |
| R6 (Tech Lock-in) | `environment`, `constraints`, `integrations` | Platform and constraint decisions feed tech stack selection |
| R7 (Build Plan) | Everything | Full template feeds phasing and effort estimation |

---

## State Update

When the template is marked complete, write to `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R1": { "status": "complete", "completed": "<ISO_DATE>" },
    "R1.5": { "status": "complete", "completed": "<ISO_DATE>" }
  },
  "current_round": "R2",
  "modules": {
    "selected": ["<module_ids>"],
    "packages": { "<module>": ["<packages>"] },
    "selection_rationale": { "<module>": "<rationale>" },
    "rejected": { "<module>": "<reason>" }
  },
  "actors": [
    { "name": "<name>", "type": "<type>", "goal": "<goal>", "frequency": "<freq>", "confidence": "<conf>" }
  ],
  "constraints": [
    { "id": "C-NNN", "category": "<cat>", "description": "<desc>", "type": "<hard|soft>", "confidence": "<conf>" }
  ]
}
```
