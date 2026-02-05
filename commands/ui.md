---
description: UI Build Phase. Generate React components from R4 specs and UI Impact Log. Supports iteration and refinement.
arguments:
  - name: action
    description: "Action: generate | refine | validate | observe (default: generate)"
    required: false
  - name: target
    description: "Screen ID, component name, or URL for observe"
    required: false
---

# /go-auto:ui [action] [target] — UI Build Phase

You are the **Boss** running the UI build phase after all implementation phases complete.

**Announce**: "Running UI build phase. I'll generate screens from R4 specs merged with UI Impact Log changes."

## Prerequisites

Before running `/go-auto:ui`:

1. **All build phases complete** — Check HANDOFF.md status
2. **R4_SCREENS.md exists** — From discovery phase
3. **UI Impact Log populated** — Auto-filled during build phases
4. **Target app running** (for observe action) — localhost or deployed

## Actions

### generate (default)

Generate all screens from R4 specs + UI impacts:

```
/go-auto:ui generate
/go-auto:ui generate dashboard    # Single screen
```

### refine

Iterate on existing generated components:

```
/go-auto:ui refine UserTable "add sorting to name column"
/go-auto:ui refine LoginForm "make button full width"
```

### validate

Run validation rules on generated code:

```
/go-auto:ui validate
/go-auto:ui validate src/components/Dashboard.tsx
```

### observe

Capture visual state of running app for comparison:

```
/go-auto:ui observe http://localhost:3000
/go-auto:ui observe http://localhost:3000/dashboard
```

## Generation Workflow

```
1. Load Context
   ├─ Read R4_SCREENS.md (screen specifications)
   ├─ Read HANDOFF.md UI Impact Log (changes since R4)
   └─ Run /ui:inventory (existing components)

2. For Each Screen
   ├─ Merge R4 spec with UI impacts
   ├─ Select components from registry
   ├─ Apply design tokens
   └─ Generate TSX

3. Validate
   ├─ TypeScript compilation
   ├─ Performance rules (15)
   ├─ Accessibility rules
   └─ Consistency rules

4. Output
   └─ Write to src/components/screens/
```

## Refinement Workflow (IMPORTANT)

UI is iterative. After initial generation:

### Step 1: Review Generated Code

```bash
# Check what was generated
ls src/components/screens/

# Review a specific screen
cat src/components/screens/Dashboard.tsx
```

### Step 2: Capture Issues

Use observation to document problems:

```
/go-auto:ui observe http://localhost:3000/dashboard
```

Or note issues in plain text:
- "Table columns too narrow"
- "Button should be primary variant"
- "Missing loading state"

### Step 3: Refine with Context

```
/go-auto:ui refine Dashboard "Table columns too narrow, use minWidth. Button should be primary."
```

The refine action:
1. Reads the existing generated code
2. Reads the original R4 spec
3. Applies the requested changes
4. Preserves existing logic
5. Re-validates

### Step 4: Iterate Until Satisfied

```
Generate → Review → Refine → Review → Refine → Done
```

Each refinement creates a bead:
```
UI-DD-NNN: Dashboard table column widths adjusted
```

## Documentation for Changes

Every generation and refinement is documented:

### In HANDOFF.md

```markdown
## UI Generation Log

| Screen | Generated | Refinements | Final Status |
|--------|-----------|-------------|--------------|
| Dashboard | 2026-02-03 | 2 | Approved |
| UserList | 2026-02-03 | 0 | Approved |
```

### In Screen File Header

```tsx
/**
 * Dashboard Screen
 *
 * Generated: 2026-02-03
 * Source: R4_SCREENS.md#dashboard
 * UI Impacts Applied: UI-001, UI-003, UI-007
 *
 * Refinements:
 * - 2026-02-03: Adjusted table column widths (UI-DD-042)
 * - 2026-02-03: Changed button to primary variant (UI-DD-043)
 */
```

### In Beads

```bash
bd create "UI-DD-042: Dashboard table column widths" \
  -t ui-design-decision \
  -p 3 \
  --body "Refinement: Adjusted UserTable column widths.

Original: Auto-sized columns
Change: Added minWidth to name (200px) and email (250px)
Reason: Text was truncating on standard viewport

Screen: Dashboard
Component: UserTable"
```

## Output Structure

```
src/components/
├── screens/           # Generated screens
│   ├── Dashboard.tsx
│   ├── UserList.tsx
│   └── Settings.tsx
├── ui/                # shadcn/ui components (existing)
│   ├── button.tsx
│   ├── card.tsx
│   └── ...
└── generated/         # Supporting generated files
    ├── types.ts       # Generated prop types
    └── hooks.ts       # Generated data hooks
```

## Validation Rules Summary

| Category | Rules | Examples |
|----------|-------|----------|
| Performance | 5 | No inline functions, limit children |
| Accessibility | 5 | Button names, alt text, labels |
| Consistency | 5 | Design tokens, naming conventions |

Run `/go-auto:ui validate` to check all rules.

## Example Full Workflow

```bash
# 1. Generate all screens
/go-auto:ui generate

# 2. Start dev server and review
npm run dev

# 3. Observe what needs fixing
/go-auto:ui observe http://localhost:3000

# 4. Refine specific issues
/go-auto:ui refine Dashboard "Table needs pagination"
/go-auto:ui refine LoginForm "Add forgot password link"

# 5. Validate final code
/go-auto:ui validate

# 6. Review documentation
cat HANDOFF.md  # Check UI Generation Log
```

## Integration with GO-Auto Phases

The UI phase runs AFTER Phase H (Final Verification):

```
Phase A-G: Build (ui-impact-detection hook active)
Phase H: Verification
Phase UI: /go-auto:ui generate → refine → validate
```

## Error Handling

### Generation Errors

If generation fails:
1. Check R4_SCREENS.md exists and is valid
2. Check component-registry has required components
3. Review error message for missing dependencies

### Refinement Errors

If refinement fails:
1. Ensure the component exists
2. Check the refinement instruction is clear
3. Try breaking into smaller changes

### Validation Errors

If validation fails:
1. Review the specific rule that failed
2. Use `/go-auto:ui refine` to fix
3. Re-run validation

## Skills Used

| Skill | Usage |
|-------|-------|
| component-inventory | Scan existing components |
| react-ui-codegen | Generate TSX code |
| agentic-ui-annotation | Observe running app |
| ui-impact-capture | Verify impacts before generation |

## Output on Completion

```markdown
## UI Build Phase Complete

**Screens Generated**: 5
**Refinements Made**: 3
**Validation Status**: PASSED

### Screens
| Screen | Components | Lines | Status |
|--------|------------|-------|--------|
| Dashboard | 8 | 245 | ✅ |
| UserList | 5 | 180 | ✅ |
| Settings | 6 | 210 | ✅ |

### Beads Created
- UI-DD-042: Dashboard table widths
- UI-DD-043: LoginForm button variant
- UI-DD-044: Settings form layout

### Files Created
- src/components/screens/Dashboard.tsx
- src/components/screens/UserList.tsx
- src/components/screens/Settings.tsx
- src/components/generated/types.ts

### Next Steps
1. Review generated screens in browser
2. Run `/go-auto:ui refine` for any adjustments
3. Commit when satisfied
```
