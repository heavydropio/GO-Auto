# Round 2: Entities

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 10-15 minutes
**Parallel**: Can run with R3 (Workflows)

---

## Purpose

Round 2 maps the data model. We capture:
- **Entities** — The nouns of the system (what data we store)
- **Attributes** — Properties of each entity (what fields they have)
- **Relationships** — How entities connect (one-to-many, many-to-many)
- **Constraints** — Business rules that govern the data

Each discovered entity becomes a `data` type node in the build system.

**Why R2 matters**: Bad data models cause cascading problems. A missing relationship means broken screens. An unclear entity means scope creep. R2 forces clarity before code.

---

## Instructions for Boss Agent

### Prerequisites

Before starting R2:
1. R1.5 (Module Selection) must be complete
2. Read `discovery/discovery-state.json` for selected modules/packages
3. Read `discovery/R1_CONTEXT.md` for actors and domain language

### Entity Discovery Protocol

**Phase 1: Seed from Modules (5 minutes)**

For each selected package in `modules.packages`, extract entity templates:

```
Example: If financial.invoicing selected:
  - Invoice, InvoiceLine, Client, Matter, TimeEntry
```

Present seeded entities to user:
> "Based on the modules we selected, here are the core entities I expect we'll need: [list]. Let me ask a few questions to refine these."

**Phase 2: Entity Refinement (5-7 minutes)**

For each seeded entity, validate and expand:

1. **Existence Check**
   - "Do you need [Entity]? Or is it handled differently?"
   - If no: Remove from list, note rejection reason

2. **Naming Alignment**
   - "I'm calling this [Entity]. Does your team use a different name?"
   - If yes: Update name, note the domain term

3. **Attribute Discovery**
   - "What information do you need to store about a [Entity]?"
   - Listen for: Required fields, optional fields, derived fields, foreign keys

4. **Relationship Mapping**
   - "How does [Entity A] relate to [Entity B]?"
   - Probe: One-to-one, one-to-many, many-to-many?
   - Probe: Required or optional relationship?

5. **Missing Entity Detection**
   - "Is there anything you track that I haven't mentioned?"
   - Common misses: Status history, audit logs, configuration, preferences

**Phase 3: Constraint Identification (3-5 minutes)**

For critical entities, identify business rules:
- "Can a [Entity] exist without a [Related Entity]?"
- "Can [field] ever be empty?"
- "What makes two [Entity] records duplicates?"
- "Can a [Entity] be deleted? What happens to related records?"

### Inference Guidelines

| Confidence | When to Use | Example |
|------------|-------------|---------|
| high | User explicitly named and described | "We track clients with name, email, and billing address" |
| medium | Reasonable inference from domain/module | Invoice module → Invoice entity with standard fields |
| low | Speculative, based on common patterns | Probably need audit timestamps on all entities |

### Attribute Type Inference

When user describes attributes, infer types:

| User Says | Infer Type | Notes |
|-----------|------------|-------|
| "name", "title", "description" | string | |
| "email" | string (email) | Add validation |
| "amount", "price", "total" | decimal | Specify precision |
| "count", "quantity" | integer | |
| "date", "when", "at" | datetime | Consider timezone |
| "yes/no", "active", "is_*" | boolean | |
| "type", "status", "category" | enum | Ask for valid values |
| "notes", "comments" | text | Long string |
| "chooses from list" | foreign_key | Determine related entity |

---

## Entity Specification Template

For each entity discovered, capture:

```yaml
entity:
  id: "data.{{ namespace }}.{{ name }}"
  name: "{{ Entity Name }}"
  namespace: "{{ module_namespace }}"
  domain_term: "{{ What users call it, if different }}"

  description: |
    {{ 1-2 sentences explaining what this entity represents }}

  attributes:
    - name: "{{ attribute_name }}"
      type: "{{ string | integer | decimal | boolean | datetime | text | enum | uuid }}"
      required: {{ true | false }}
      unique: {{ true | false }}
      default: "{{ default value, if any }}"
      description: "{{ What this field represents }}"
      confidence: {{ high | medium | low }}
      source: "{{ User said X | Inferred from Y | Module template }}"

    - name: "{{ next_attribute }}"
      # ... repeat for each attribute

  relationships:
    - name: "{{ relationship_name }}"
      type: "{{ belongs_to | has_many | has_one | many_to_many }}"
      related_entity: "{{ data.namespace.entity_id }}"
      foreign_key: "{{ field_name }}"
      required: {{ true | false }}
      cascade_delete: {{ true | false }}
      description: "{{ What this relationship represents }}"
      confidence: {{ high | medium | low }}

  constraints:
    - type: "{{ unique | check | foreign_key | not_null }}"
      fields: ["{{ field1 }}", "{{ field2 }}"]
      description: "{{ Business rule this enforces }}"

  metadata:
    source_round: 2
    confidence: {{ high | medium | low }}
    module_source: "{{ module.package if from template }}"
    inferred_from:
      - "{{ evidence 1 }}"
      - "{{ evidence 2 }}"
    requires_validation:
      - item: "{{ What needs confirmation }}"
        risk_if_wrong: "{{ Impact }}"
        question: "{{ Follow-up question }}"
```

---

## Output Template

### Entity Summary

| Entity | Namespace | Attributes | Relationships | Confidence | Source |
|--------|-----------|------------|---------------|------------|--------|
| {{ name }} | {{ namespace }} | {{ count }} | {{ count }} | {{ confidence }} | {{ module or user }} |

### Entity Specifications

#### Entity: {{ Entity Name }}

**ID**: `data.{{ namespace }}.{{ name }}`
**Namespace**: {{ namespace }}
**Domain Term**: {{ what users call it }}
**Confidence**: {{ high | medium | low }}
**Source**: {{ Module template / User description / Inferred }}

**Description**: {{ 1-2 sentences }}

**Attributes**:

| Name | Type | Required | Unique | Default | Confidence | Notes |
|------|------|----------|--------|---------|------------|-------|
| id | uuid | yes | yes | auto | high | Primary key |
| {{ attr }} | {{ type }} | {{ yes/no }} | {{ yes/no }} | {{ default }} | {{ conf }} | {{ notes }} |

**Relationships**:

| Name | Type | Related Entity | Required | Cascade | Confidence |
|------|------|----------------|----------|---------|------------|
| {{ name }} | {{ type }} | {{ entity }} | {{ yes/no }} | {{ yes/no }} | {{ conf }} |

**Constraints**:

| Type | Fields | Rule |
|------|--------|------|
| {{ type }} | {{ fields }} | {{ description }} |

**Inferred From**:
- {{ evidence 1 }}
- {{ evidence 2 }}

**Requires Validation**:
- [ ] {{ item needing confirmation }}

---

### Entity Relationship Diagram (ASCII)

```
{{ Entity A }}          {{ Entity B }}
+---------------+       +---------------+
| id            |       | id            |
| name          |       | name          |
| entity_b_id --|------>| ...           |
| ...           |       +---------------+
+---------------+
      |
      | has_many
      v
{{ Entity C }}
+---------------+
| id            |
| entity_a_id   |
| ...           |
+---------------+
```

---

### Relationship Summary

| From Entity | Relationship | To Entity | Type | Required |
|-------------|--------------|-----------|------|----------|
| {{ from }} | {{ name }} | {{ to }} | {{ type }} | {{ yes/no }} |

---

### Low Confidence Items

Items requiring user validation before R4:

| Entity/Attribute | Current Assumption | Risk if Wrong | Follow-up Question |
|------------------|-------------------|---------------|-------------------|
| {{ item }} | {{ assumption }} | {{ risk }} | {{ question }} |

---

## Validation Checklist

R2 cannot be marked complete until all REQUIRED items are checked:

### Required (Blocks Completion)

- [ ] At least 1 entity identified (high confidence)
- [ ] Each entity has at least 1 attribute beyond id
- [ ] Primary key defined for all entities (typically `id`)
- [ ] All relationships have both sides identified
- [ ] No orphan entities (entities with no relationships and no clear standalone purpose)
- [ ] Entity names follow consistent naming convention (singular, PascalCase or snake_case)
- [ ] At least one entity per selected module package has been considered

### Recommended (Quality Gates)

- [ ] Each entity has a description
- [ ] Foreign key fields explicitly named
- [ ] Cascade delete rules defined for critical relationships
- [ ] Enum fields have valid values listed
- [ ] Timestamps (created_at, updated_at) considered for audit needs
- [ ] Soft delete vs hard delete decision made for major entities

### Items Needing Validation

List any medium/low confidence items that must be validated before R4:

| Item | Current State | Must Resolve By |
|------|---------------|-----------------|
| {{ entity/attribute }} | {{ assumption }} | R4 (Screens) |

---

## State Update

When R2 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R2": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "entities_discovered": {{ count }},
      "relationships_mapped": {{ count }},
      "low_confidence_items": {{ count }}
    }
  },
  "current_round": "{{ R3 if R3 pending, else R4 }}",
  "entities": [
    {
      "id": "data.{{ namespace }}.{{ name }}",
      "name": "{{ Entity Name }}",
      "namespace": "{{ namespace }}",
      "attribute_count": {{ count }},
      "relationship_count": {{ count }},
      "confidence": "{{ high | medium | low }}",
      "module_source": "{{ module.package or null }}",
      "status": "discovered"
    }
  ]
}
```

### Node Generation

For each entity, create a node entry:

```json
{
  "id": "data.{{ namespace }}.{{ name }}",
  "name": "{{ Entity Name }}",
  "type": "data",
  "namespace": "{{ namespace }}",
  "tags": ["entity", "{{ module }}"],
  "status": "discovered",

  "requires": ["infrastructure.core.database"],
  "parallel_hints": ["{{ other entities in same namespace }}"],

  "spec": {
    "purpose": "{{ entity description }}",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations work", "verification_method": "automated" },
      { "id": "AC-2", "description": "All relationships enforced", "verification_method": "automated" },
      { "id": "AC-3", "description": "Constraints validated", "verification_method": "automated" }
    ],
    "assumptions": [
      {
        "id": "AS-{{ n }}",
        "assumption": "{{ low confidence item }}",
        "risk_if_wrong": "{{ impact }}",
        "status": "needs_validation"
      }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "{{ high | medium | low }}",
    "module_source": "{{ module.package }}",
    "inferred_from": ["{{ evidence }}"],
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

---

## Cross-Reference with R3 (Workflows)

R2 and R3 run in parallel. After both complete, verify:

1. **Entity Coverage**: Every entity mentioned in R3 workflows exists in R2
2. **Relationship Coverage**: Workflow transitions match relationship types
3. **Attribute Coverage**: Fields used in workflow conditions are defined

If gaps exist, resolve before R4:
- Missing entity → Add to R2
- Missing relationship → Add to R2
- Missing attribute → Add to entity

---

## Common Entity Patterns

### Standard Audit Fields

Consider adding to all entities:

```yaml
- name: "created_at"
  type: "datetime"
  required: true
  default: "now()"

- name: "updated_at"
  type: "datetime"
  required: true
  default: "now()"

- name: "created_by"
  type: "uuid"
  required: false
  description: "User who created this record"

- name: "updated_by"
  type: "uuid"
  required: false
  description: "User who last modified this record"
```

### Soft Delete Pattern

For entities that shouldn't be permanently deleted:

```yaml
- name: "deleted_at"
  type: "datetime"
  required: false
  description: "If set, record is soft-deleted"

- name: "deleted_by"
  type: "uuid"
  required: false
```

### Status/State Pattern

For entities with lifecycle states:

```yaml
- name: "status"
  type: "enum"
  required: true
  default: "{{ initial_status }}"
  values: ["draft", "active", "archived"]

- name: "status_changed_at"
  type: "datetime"
  required: false
```

### Multi-tenant Pattern

For SaaS applications:

```yaml
- name: "tenant_id"
  type: "uuid"
  required: true
  description: "Tenant/organization this belongs to"
```

---

## Entity Discovery Questions by Module

Use these prompts when refining entities from selected modules:

### Financial Module

- "What information do you need on an invoice? Line items, discounts, taxes?"
- "Do you track partial payments? Payment plans?"
- "Is there a concept of billable vs non-billable time?"
- "Do clients have multiple billing contacts or addresses?"

### Field Service Module

- "What makes up a work order? Parts, labor, travel?"
- "Do technicians have specialties or certifications?"
- "How granular is your location tracking? Address? GPS coordinates?"
- "What gets captured during an inspection?"

### CRM Module

- "Is there a difference between a contact and a customer?"
- "Do you track interactions automatically or manually?"
- "What stages does a customer go through?"
- "Do you need organization/company hierarchy?"

### Project Module

- "What's the relationship between projects and tasks?"
- "Do you track time against projects? Tasks? Both?"
- "Are there project templates you reuse?"
- "How do you handle resource conflicts?"

### Inventory Module

- "Do you track serial numbers? Lot numbers? Both?"
- "What locations hold inventory? Warehouses? Trucks? Customer sites?"
- "Do you need to reserve stock before shipping?"
- "How do you handle damaged or returned goods?"

---

## Next Steps

After R2 completes:
1. Save as `discovery/R2_ENTITIES.md`
2. Update `discovery-state.json` with entity list and round status
3. Check R3 status:
   - If R3 complete: Proceed to R4 (Screens)
   - If R3 in progress: Wait for completion, then cross-reference
   - If R3 pending: R3 can start independently
4. Announce completion:
   > "Entity discovery complete. Found {{ count }} entities with {{ relationship_count }} relationships. {{ low_confidence_count }} items need validation before screen design."
