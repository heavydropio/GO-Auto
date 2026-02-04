# Node Specification Schema

Defines the JSON schema for **Nodes** - the buildable units in GO Build's discovery system.

---

## Overview

Nodes represent everything that needs to be built: infrastructure, data models, screens, features, integrations, and AI agents. The schema enables:

1. Progressive discovery through 7 rounds
2. Automatic parallelization detection from dependency graphs
3. Integration with GO Build's Boss/Worker execution model
4. Confidence tracking and provenance for AI-inferred specifications

---

## Node Types

| Type | Description | Examples |
|------|-------------|----------|
| `infrastructure` | Foundational systems | Auth, database, storage, config |
| `data` | Entities, schemas, migrations | User model, Client entity |
| `screen` | User interface components | Login form, Dashboard |
| `feature` | Business logic and workflows | Invoice generation, Payment processing |
| `integration` | External API connections | Stripe, Email service |
| `agent` | AI-powered touchpoints | Smart search, Auto-categorization |

---

## Status Lifecycle

```
discovered → specifying → specified → queued → building → complete
                                        │         │
                                        │         └→ failed → (retry)
                                        │
                                        └→ (deleted if invalid)
```

| Status | Description |
|--------|-------------|
| `discovered` | Node identified during discovery |
| `specifying` | Actively being refined |
| `specified` | Specification complete, ready for planning |
| `queued` | Assigned to a wave, waiting for dependencies |
| `building` | Worker agent actively constructing |
| `complete` | Built and verified |
| `failed` | Build attempt failed |

---

## JSON Schema

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://go-build.dev/schemas/node-spec.json",
  "title": "GO Build Node Specification",
  "type": "object",
  "required": ["id", "name", "type", "namespace", "status", "spec", "metadata"],

  "properties": {
    "id": {
      "type": "string",
      "pattern": "^(infrastructure|data|screen|feature|integration|agent)\\.[a-z_]+\\.[a-z_]+$",
      "description": "Format: {type}.{namespace}.{name}"
    },

    "name": {
      "type": "string",
      "description": "Human-readable display name"
    },

    "type": {
      "type": "string",
      "enum": ["infrastructure", "data", "screen", "feature", "integration", "agent"]
    },

    "namespace": {
      "type": "string",
      "pattern": "^[a-z_]+$",
      "description": "Logical grouping (e.g., 'invoicing', 'auth')"
    },

    "tags": {
      "type": "array",
      "items": { "type": "string" },
      "default": []
    },

    "status": {
      "type": "string",
      "enum": ["discovered", "specifying", "specified", "queued", "building", "complete", "failed"]
    },

    "requires": {
      "type": "array",
      "items": { "type": "string" },
      "default": [],
      "description": "Node IDs this node depends on"
    },

    "blocks": {
      "type": "array",
      "items": { "type": "string" },
      "default": [],
      "description": "Node IDs that depend on this (computed)"
    },

    "parallel_hints": {
      "type": "array",
      "items": { "type": "string" },
      "default": [],
      "description": "Suggested parallel groupings"
    },

    "spec": {
      "type": "object",
      "required": ["purpose"],
      "properties": {
        "purpose": { "type": "string" },
        "acceptance_criteria": { "type": "array" },
        "implementation_notes": { "type": "string" },
        "context_files": { "type": "array" },
        "questions": { "type": "array" },
        "assumptions": { "type": "array" }
      }
    },

    "metadata": {
      "type": "object",
      "required": ["source_round", "confidence", "created_at", "updated_at", "version"],
      "properties": {
        "source_round": { "type": "integer", "minimum": 1, "maximum": 7 },
        "confidence": { "enum": ["high", "medium", "low"] },
        "confirmed_by": { "type": "string" },
        "module_source": { "type": "string" },
        "inferred_from": { "type": "array" },
        "created_at": { "type": "string", "format": "date-time" },
        "updated_at": { "type": "string", "format": "date-time" },
        "version": { "type": "integer", "minimum": 1 }
      }
    },

    "build": {
      "type": "object",
      "properties": {
        "estimated_effort": { "enum": ["xs", "s", "m", "l", "xl"] },
        "phase": { "type": "integer" },
        "wave": { "type": "integer" },
        "assigned_to": { "type": "string" },
        "started_at": { "type": "string", "format": "date-time" },
        "completed_at": { "type": "string", "format": "date-time" },
        "files": {
          "type": "object",
          "properties": {
            "creates": { "type": "array" },
            "modifies": { "type": "array" },
            "reads": { "type": "array" }
          }
        },
        "testing": {
          "type": "object",
          "properties": {
            "unit_tests_required": { "type": "boolean" },
            "integration_tests_required": { "type": "boolean" },
            "test_files": { "type": "array" },
            "smoke_commands": { "type": "array" }
          }
        }
      }
    }
  }
}
```

---

## Dependency Graph and Parallelization

### How Nodes Connect

```
INFRASTRUCTURE LAYER
  ├── config
  └── database
         │
DATA LAYER
  ├── client (requires: database)
  └── matter (requires: database)
         │
SCREEN LAYER
  └── time_entry_form (requires: client, matter)
         │
FEATURE LAYER
  └── invoice_generation (requires: time_entry_form)
```

### Parallelization Detection

Two nodes can run in parallel if:
1. **No dependency relationship** - Neither requires the other
2. **No file write conflicts** - Their creates/modifies don't overlap

```python
def can_parallel(node_a, node_b, graph):
    # Check no dependency relationship
    if graph.has_path(node_a.id, node_b.id):
        return False
    if graph.has_path(node_b.id, node_a.id):
        return False

    # Check no file write conflicts
    a_writes = set(node_a.build.files.creates + node_a.build.files.modifies)
    b_writes = set(node_b.build.files.creates + node_b.build.files.modifies)

    if a_writes & b_writes:
        return False

    return True
```

### Wave Assignment Example

```
WAVE 1: [infrastructure.core.config, infrastructure.core.database]
        → Can parallel: No dependencies, different files

WAVE 2: [data.invoicing.client, data.invoicing.matter]
        → Can parallel: Both depend on database, no file conflicts

WAVE 3: [screen.invoicing.time_entry_form]
        → Sequential: Depends on both data nodes

WAVE 4: [feature.invoicing.invoice_generation]
        → Sequential: Depends on screen
```

---

## Example Nodes

### Infrastructure Node

```json
{
  "id": "infrastructure.auth.jwt_auth",
  "name": "JWT Authentication System",
  "type": "infrastructure",
  "namespace": "auth",
  "tags": ["security", "mvp"],
  "status": "specified",

  "requires": [],
  "blocks": [],

  "spec": {
    "purpose": "Provide JWT-based authentication for API endpoints.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Generate valid JWT on login", "verification_method": "automated" },
      { "id": "AC-2", "description": "Validate JWT and extract claims", "verification_method": "automated" },
      { "id": "AC-3", "description": "Reject expired tokens with 401", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 3,
    "confidence": "high",
    "confirmed_by": "user",
    "created_at": "2026-01-26T10:00:00Z",
    "updated_at": "2026-01-26T14:30:00Z",
    "version": 2
  },

  "build": {
    "estimated_effort": "m",
    "phase": 1,
    "wave": 1,
    "files": {
      "creates": ["src/auth/jwt.py", "tests/test_auth.py"],
      "modifies": ["src/main.py"],
      "reads": ["src/core/config.py"]
    },
    "testing": {
      "unit_tests_required": true,
      "smoke_commands": ["uv run pytest tests/test_auth.py -v"]
    }
  }
}
```

### Data Node

```json
{
  "id": "data.invoicing.client",
  "name": "Client Entity",
  "type": "data",
  "namespace": "invoicing",
  "tags": ["core-entity", "mvp"],
  "status": "specified",

  "requires": ["infrastructure.core.database"],
  "parallel_hints": ["data.invoicing.matter"],

  "spec": {
    "purpose": "Represents a client in the billing system.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations work", "verification_method": "automated" },
      { "id": "AC-2", "description": "Has one-to-many with Matter", "verification_method": "automated" }
    ],
    "assumptions": [
      {
        "id": "AS-1",
        "assumption": "Client names are unique",
        "risk_if_wrong": "Duplicate entries",
        "status": "validated"
      }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.invoicing",
    "created_at": "2026-01-26T09:00:00Z",
    "updated_at": "2026-01-26T12:00:00Z",
    "version": 3
  },

  "build": {
    "estimated_effort": "s",
    "phase": 1,
    "wave": 2,
    "files": {
      "creates": ["src/models/client.py", "tests/test_client.py"],
      "modifies": ["src/models/__init__.py"],
      "reads": ["src/core/database.py"]
    }
  }
}
```

### Screen Node

```json
{
  "id": "screen.invoicing.time_entry_form",
  "name": "Time Entry Form",
  "type": "screen",
  "namespace": "invoicing",
  "tags": ["user-facing", "mvp"],
  "status": "specified",

  "requires": ["data.invoicing.client", "data.invoicing.matter"],

  "spec": {
    "purpose": "Form for logging billable time against client matters.",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Select client from dropdown", "verification_method": "manual" },
      { "id": "AC-2", "description": "Matter filters by client", "verification_method": "automated" },
      { "id": "AC-3", "description": "Validates required fields", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 4,
    "confidence": "high",
    "confirmed_by": "user",
    "created_at": "2026-01-26T11:00:00Z",
    "updated_at": "2026-01-26T15:00:00Z",
    "version": 2
  },

  "build": {
    "estimated_effort": "m",
    "phase": 2,
    "wave": 1,
    "files": {
      "creates": ["src/screens/TimeEntryForm.tsx", "src/screens/TimeEntryForm.test.tsx"],
      "modifies": ["src/App.tsx"],
      "reads": ["src/api/clients.ts"]
    }
  }
}
```

---

## Confidence and Provenance

| Confidence | Meaning |
|------------|---------|
| `high` | User confirmed or established pattern |
| `medium` | Reasonable inference with evidence |
| `low` | Speculative, needs validation |

The `inferred_from` field creates audit trail:
```json
"inferred_from": [
  "user said: 'need to track time'",
  "workflow step 3.2",
  "module catalog: financial.invoicing"
]
```

---

## Integration with GO Build

### Discovery to Execution Flow

```
/go:discover
    ├── R2: Entities     → Creates data nodes
    ├── R3: Workflows    → Creates feature/screen nodes
    ├── R4: Screens      → Refines screen nodes
    └── R7: Build Plan   → Assigns phases/waves
         │
         ▼
    discovery-state.json (contains all nodes)
         │
         ▼
    /go:kickoff → Workers build nodes by wave
```

### Node to Task Mapping

Each `queued` node becomes a task in `PHASE_N_PLAN.md`:

```markdown
### Task 2.1: Time Entry Form

- **Node**: `screen.invoicing.time_entry_form`
- **Files**: Creates TimeEntryForm.tsx, Modifies App.tsx
- **Dependencies**: Wave 1 complete
- **Acceptance Criteria**: [from node spec]
- **Smoke Tests**: [from node build.testing]
```

---

## Summary

The Node Specification Schema provides:

1. **Structured identity** with type-namespaced IDs
2. **Status lifecycle** from discovery to completion
3. **Dependency tracking** for automatic parallelization
4. **Progressive specification** from discovered to built
5. **Confidence tracking** for AI transparency
6. **Build configuration** integrating with GO Build execution
