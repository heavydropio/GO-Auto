# BUILD GUIDE: Phase [N] — [Phase Name]

**Date**: YYYY-MM-DD
**Prepared by**: Review Agent
**For**: Build Planning Agent

---

## Executive Summary

[3-5 sentences: What this phase builds, why it matters, key challenges]

---

## Phase Context

### What We're Building
[Description of deliverables]

### Why This Phase
[How it fits in the overall project, what depends on it]

### Success Criteria
1. [Criterion 1]
2. [Criterion 2]
3. [Criterion 3]

---

## Codebase Inventory

### Project Structure
```
project/
├── src/
│   ├── module1/
│   │   ├── __init__.py
│   │   └── core.py        # [description]
│   └── module2/
│       └── ...
├── tests/
│   └── ...
└── [other relevant dirs]
```

### Key Files for This Phase

| File | Purpose | Relevance |
|------|---------|-----------|
| `src/module/file.py` | [what it does] | Will extend |
| `src/core/types.py` | [what it does] | Read only |
| `tests/conftest.py` | [what it does] | May add fixtures |

### Existing Infrastructure to Reuse

| Component | Location | How to Use |
|-----------|----------|------------|
| [Component 1] | `src/path` | Import and extend |
| [Component 2] | `src/path` | Use as-is |

---

## Existing Patterns

### Code Style
- [Pattern 1: e.g., "All classes use dataclasses"]
- [Pattern 2: e.g., "Async methods prefixed with a_"]
- [Pattern 3: e.g., "Tests use pytest fixtures"]

### Type Definitions
```python
# Key types this phase will work with
@dataclass
class ExistingType:
    field1: str
    field2: int
```

### Import Conventions
```python
# Standard imports in this codebase
from src.core.types import BaseType
from src.utils import helper_function
```

---

## Dependencies

### Existing (Already Installed)
| Package | Version | Used For |
|---------|---------|----------|
| [package] | [version] | [purpose] |

### New (To Add)
| Package | Version | Why Needed | Optional? |
|---------|---------|------------|-----------|
| [package] | [version] | [purpose] | Yes/No |

### pyproject.toml Changes
```toml
[project.dependencies]
new-package = ">=1.0"

[project.optional-dependencies]
phase-n = ["optional-package>=2.0"]
```

---

## External Research

### APIs/Services
| Service | Documentation | Key Endpoints |
|---------|---------------|---------------|
| [Service] | [URL] | [endpoints to use] |

### Reference Implementations
| Project | Location | What to Reference |
|---------|----------|-------------------|
| [Project] | [path or URL] | [specific patterns] |

### Best Practices Found
- [Practice 1 with source]
- [Practice 2 with source]

---

## Beads from Previous Phases

Key context from previous phases that affects this phase. Do not contradict active decisions.

### Design Decisions (DD-NNN)

| ID | Decision | Rationale | Phase | Status |
|----|----------|-----------|-------|--------|
| DD-001 | [Decision] | [Why] | [N] | Active |

### Assumptions (AS-NNN)

Open assumptions to validate or work around.

| ID | Assumption | Risk if Wrong | Phase | Status |
|----|------------|---------------|-------|--------|
| AS-001 | [Assumption] | [Risk] | [N] | Open/Validated |

### Discoveries (DS-NNN)

Non-obvious learnings that affect implementation.

| ID | Discovery | Impact | Phase |
|----|-----------|--------|-------|
| DS-001 | [Discovery] | [Impact] | [N] |

### Open Questions (OQ-NNN)

Questions to address in planning or escalate to human.

| ID | Question | Relevant To | Blocking? |
|----|----------|-------------|-----------|
| OQ-001 | [Question] | This Phase | Yes/No |

---

## Design Decisions

### Decisions to Make This Phase
| Question | Options | Recommendation |
|----------|---------|----------------|
| [Question 1] | A, B, C | A because [reason] |

### Constraints
- [Constraint 1]
- [Constraint 2]

---

## Component Specifications

### Component 1: [Name]

**Purpose**: [What it does]

**Interface**:
```python
class ComponentName:
    def method_one(self, arg: Type) -> ReturnType:
        """[Description]"""
        ...
```

**Behavior**:
- [Behavior 1]
- [Behavior 2]

**Error Handling**:
- [How errors should be handled]

---

### Component 2: [Name]

**Purpose**: [What it does]

**Interface**:
```python
# Similar structure
```

---

## Test Strategy

### Unit Tests
| Component | Test Focus | Fixtures Needed |
|-----------|------------|-----------------|
| [Component 1] | [What to test] | [Fixtures] |

### Integration Tests
| Flow | Components Involved | Setup |
|------|---------------------|-------|
| [Flow 1] | [Components] | [How to set up] |

### Edge Cases to Cover
- [Edge case 1]
- [Edge case 2]

---

## Blockers and Prerequisites

### Resolved
- [x] [Blocker that was resolved]

### Outstanding
- [ ] [Blocker that needs resolution]

### Assumptions
- [Assumption 1]
- [Assumption 2]

---

## Questions for Planning Agent

1. [Question about approach]
2. [Question about prioritization]
3. [Question about dependencies]

---

## Checklist: Ready for Planning

- [ ] Codebase inventory complete
- [ ] Existing patterns documented
- [ ] Dependencies identified
- [ ] External research done
- [ ] Design decisions documented
- [ ] Component specs outlined
- [ ] Test strategy defined
- [ ] Blockers identified

**Status**: Ready for Build Planning Agent
