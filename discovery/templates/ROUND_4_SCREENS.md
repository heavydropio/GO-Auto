# Round 4: Screens

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 20-30 minutes

---

## Purpose

Round 4 maps the user interface. We work backwards from what users see to what the system must support:

- **Screens** — The pages/views users interact with
- **Components** — Reusable UI building blocks
- **Navigation** — How users move between screens
- **Interactions** — What users can do and how the system responds

This is **UI-First Derivation**: the interface validates and refines backend requirements discovered in R2 and R3. If a workflow step has no screen, something is missing. If an entity has no CRUD interface, it's either embedded elsewhere or forgotten.

### Why R4 Matters

Screens are where users validate your understanding. Abstract entity definitions and workflow diagrams are hard to critique. But show someone a screen layout and they immediately say "wait, where's the X button?" or "I need to see Y here too."

R4 catches:
- Missing entity attributes (user needs to see data not captured in R2)
- Broken workflow steps (no screen exists for a workflow action)
- Unclear navigation (how does the user get from A to B?)
- Accessibility gaps (can keyboard users navigate? screen readers?)

---

## Entry Requirements

Before starting R4, verify:

- [ ] R2 (Entities) status = complete
- [ ] R3 (Workflows) status = complete
- [ ] `discovery/R2_ENTITIES.md` exists with entity specifications
- [ ] `discovery/R3_WORKFLOWS.md` exists with workflow definitions
- [ ] `discovery/R1_CONTEXT.md` available for platform/responsive decisions

**Hard Requirement**: Both R2 AND R3 must be complete. Screens synthesize data models (R2) with user flows (R3).

---

## Instructions for Boss Agent

### Preparation (3 minutes)

1. **Load R1 Context**
   - Platform decision (web/mobile/desktop)
   - Responsive approach (mobile-first/desktop-first)
   - Offline requirements
   - Accessibility needs
   - Primary actors and their contexts

2. **Load R2 Entities**
   - Entity list with attributes
   - Relationships between entities
   - Which entities need full CRUD vs embedded views

3. **Load R3 Workflows**
   - Workflow steps (each step often = screen or component)
   - Screen names mentioned in workflow definitions
   - Decision points (may need confirmation dialogs)
   - Error states (may need error screens)

### Screen Discovery Protocol

#### Phase 1: Derive Screens from Workflows (5-10 minutes)

For each workflow in R3:

```
Workflow: [WF-ID] [Name]
Steps that need screens:
  Step 1: [Action] → Screen: [Name] or Component: [Name]
  Step 2: [Action] → Screen: [Name] or Component: [Name]
  ...
```

**Questions to ask:**

- "Looking at [Workflow], at step [N] where [Action happens], what does the user see?"
- "Is this a full-page screen or a modal/dialog?"
- "Does this need its own URL/route or is it embedded?"

**Categorize each UI touchpoint:**

| Category | When to Use | Example |
|----------|-------------|---------|
| **Screen** | Dedicated page, has its own URL | Dashboard, Entity List, Entity Detail |
| **Modal** | Overlay, blocks interaction | Confirmation, Quick Edit |
| **Drawer** | Side panel, partial interaction | Filters, Settings |
| **Inline** | Embedded in parent screen | Expandable row, Inline form |
| **Toast** | Brief notification | Success message, Error alert |

#### Phase 2: Map Entities to Screens (5 minutes)

For each entity in R2, determine CRUD coverage:

```yaml
entity_screen_mapping:
  - entity: "[Entity Name]"
    create: "[Screen name or 'embedded in X' or 'not needed']"
    read_list: "[List screen name or 'not needed']"
    read_detail: "[Detail screen name or 'embedded in X']"
    update: "[Edit screen name or 'inline edit' or 'same as create']"
    delete: "[Confirmation modal or 'soft delete toggle' or 'not allowed']"
    notes: "[Why this pattern]"
```

**Common patterns:**

| Entity Type | Typical Screen Pattern |
|-------------|------------------------|
| Core domain entity | Full CRUD: List + Detail + Create/Edit Form |
| Child entity | Embedded in parent detail, modal for create/edit |
| Lookup/Reference | Admin-only list, embedded selector elsewhere |
| Audit/Log | Read-only list, no create/edit |
| Settings | Single settings page, no list |

**Gap Detection:**

- Entity with no screens and no embedded mentions → **Flag for review**
- Entity CRUD mentioned in workflow but no screen defined → **Add screen**

#### Phase 3: Define Navigation and Information Architecture (5-10 minutes)

**Step 1: Identify Entry Points**

Primary entry points based on actors:

```yaml
navigation:
  primary_entry:
    - actor: "[Actor name]"
      lands_on: "[Screen ID]"
      reason: "[Why this is their home]"

  global_navigation:
    type: [sidebar | top_nav | bottom_tabs | hamburger]
    items:
      - label: "[Menu item]"
        screen: "[Screen ID]"
        icon: "[Icon name or description]"
        actors: ["Actor1", "Actor2"]  # Who sees this item
```

**Step 2: Map Screen-to-Screen Navigation**

For each screen, document:
- Where users can go FROM this screen
- How users GET TO this screen (entry points)

```yaml
screen_navigation:
  - screen: "[Screen ID]"
    entry_points:
      - from: "[Screen or 'direct URL' or 'global nav']"
        trigger: "[Click button/link/menu item]"
    exits:
      - to: "[Screen ID]"
        trigger: "[Button/Link label]"
        type: [navigate | modal | drawer]
```

**Step 3: Define URL Structure (Web)**

```yaml
routes:
  - path: "/dashboard"
    screen: "screen.core.dashboard"
    auth_required: true

  - path: "/clients"
    screen: "screen.invoicing.client_list"
    auth_required: true

  - path: "/clients/:id"
    screen: "screen.invoicing.client_detail"
    params:
      - name: id
        type: uuid
        description: "Client ID"

  - path: "/clients/:id/edit"
    screen: "screen.invoicing.client_form"
    mode: edit
```

#### Phase 4: Component Identification (5-10 minutes)

**Step 1: Find Repeated Patterns**

Review screens for reusable elements:

```
Pattern Detection Questions:
- Do multiple screens show entity lists? → EntityList component
- Do multiple screens have search? → SearchBar component
- Do multiple screens show user info? → UserCard component
- Are there similar forms? → FormField components
- Are there common actions? → ActionButton components
```

**Step 2: Categorize Components**

| Category | Purpose | Examples |
|----------|---------|----------|
| **Layout** | Page structure | PageLayout, Sidebar, Header |
| **Navigation** | Moving between views | NavMenu, Breadcrumb, TabBar |
| **Data Display** | Showing information | DataTable, Card, Stat |
| **Forms** | User input | TextField, Select, DatePicker |
| **Feedback** | System responses | Toast, Modal, Loading |
| **Domain** | Business-specific | ClientCard, InvoiceRow |

**Step 3: Document Shared Components**

```yaml
component_library:
  - id: "component.shared.data_table"
    name: "DataTable"
    category: data_display
    description: "Sortable, filterable table for entity lists"
    used_in:
      - screen.invoicing.client_list
      - screen.invoicing.invoice_list
      - screen.admin.user_list
    props:
      - name: columns
        type: array
        required: true
      - name: data
        type: array
        required: true
      - name: sortable
        type: boolean
        default: true
      - name: filterable
        type: boolean
        default: true
      - name: pagination
        type: boolean
        default: true
```

#### Phase 5: Interaction Specification (10-15 minutes)

For each screen, define interactions:

**Step 1: Identify Actions**

```yaml
screen_actions:
  - screen: "[Screen ID]"
    actions:
      - id: "ACT-001"
        label: "[Button/link text]"
        type: [primary | secondary | danger | link]
        trigger: [click | submit | key_shortcut]
        key_shortcut: "[Ctrl+S]"  # if applicable
        requires_selection: [true | false]  # for list screens
        confirmation: "[Confirmation message]"  # if dangerous
        result:
          - type: [navigate | api_call | modal | state_change]
            detail: "[What happens]"
        error_handling:
          - error: "[Error condition]"
            response: "[How UI responds]"
```

**Step 2: Define Form Behaviors**

```yaml
form_specification:
  - screen: "[Form screen ID]"
    entity: "[Entity being created/edited]"
    mode: [create | edit | both]

    fields:
      - name: "[field_name]"
        label: "[Display label]"
        type: [text | email | number | date | select | textarea | checkbox | radio | file]
        required: [true | false]
        validation:
          - rule: "[Validation rule]"
            message: "[Error message]"
        depends_on: "[Other field, if cascading]"
        placeholder: "[Placeholder text]"
        help_text: "[Help text]"

    submit:
      label: "[Submit button text]"
      loading_text: "[Text during submission]"
      success:
        message: "[Success toast]"
        redirect: "[Screen to navigate to]"
      error:
        display: [toast | inline | modal]
```

**Step 3: Document Loading and Empty States**

```yaml
screen_states:
  - screen: "[Screen ID]"
    states:
      loading:
        display: [skeleton | spinner | progress]
        message: "[Loading message, if any]"

      empty:
        message: "[No data message]"
        action:
          label: "[CTA button]"
          target: "[Screen or action]"

      error:
        display: [inline | full_page | toast]
        retry_available: [true | false]
```

---

## Screen Specification Template

For each screen discovered, capture:

```yaml
screen:
  id: "screen.{{ namespace }}.{{ name }}"
  name: "{{ Screen Display Name }}"
  type: [list | detail | form | dashboard | wizard | settings | report | modal]
  namespace: "{{ module_namespace }}"

  purpose: |
    {{ 1-2 sentences explaining what this screen does and why }}

  actors:
    - name: "[Actor name]"
      permissions: [view | edit | admin]

  entry_points:
    - from: "[Screen ID or 'global_nav' or 'direct_url']"
      trigger: "[How user gets here]"
      params: ["[param1]", "[param2]"]  # URL params or state passed

  data_requirements:
    entities:
      - entity: "data.{{ namespace }}.{{ entity }}"
        usage: [display | edit | create | delete]
        fields:
          - "[field1]"
          - "[field2]"
        filters: "[Any default filters applied]"
        sort: "[Default sort order]"

    api_endpoints:
      - method: [GET | POST | PUT | DELETE]
        path: "/api/{{ path }}"
        purpose: "[What this call does]"

  layout:
    type: [single_column | two_column | grid | tabs | wizard_steps]
    sections:
      - name: "[Section name]"
        components: ["[Component ID]"]
        collapsible: [true | false]

  actions:
    primary:
      - label: "[Button text]"
        action: "[What it does]"
        navigates_to: "[Screen ID, if navigation]"
    secondary:
      - label: "[Button text]"
        action: "[What it does]"
    danger:
      - label: "[Button text]"
        action: "[What it does]"
        confirmation: "[Confirmation message]"

  navigation:
    breadcrumb: ["Home", "Clients", "{{ client.name }}"]
    back_button: "[Screen ID or null]"
    related_screens:
      - screen: "[Screen ID]"
        label: "[Link text]"
        relationship: "[Why related]"

  responsive:
    breakpoints:
      mobile: "[Layout changes for mobile]"
      tablet: "[Layout changes for tablet]"
      desktop: "[Default layout]"
    priority_content: "[What shows first on small screens]"
    hidden_on_mobile: ["[Element]", "[Element]"]

  offline:
    available: [true | false]
    cached_data: ["[What's cached]"]
    queued_actions: ["[Actions that queue for sync]"]
    sync_indicator: [true | false]

  accessibility:
    keyboard_navigation: "[How to navigate with keyboard]"
    screen_reader: "[ARIA labels and landmarks]"
    focus_management: "[Where focus goes on load/action]"
    skip_links: [true | false]

  states:
    loading:
      type: [skeleton | spinner | progress]
      message: "[Loading text]"
    empty:
      message: "[Empty state message]"
      action: "[CTA if any]"
    error:
      display: [inline | toast | full_page]
      retry: [true | false]

  metadata:
    source_round: 4
    confidence: [high | medium | low]
    derived_from:
      workflows: ["WF-001", "WF-002"]
      entities: ["data.namespace.entity"]
    inferred_from:
      - "[Evidence 1]"
      - "[Evidence 2]"
    open_questions:
      - "[Question needing validation]"
```

---

## Output Template

### Screen Inventory

| ID | Name | Type | Namespace | Actors | Confidence | Derived From |
|----|------|------|-----------|--------|------------|--------------|
| screen.core.dashboard | Dashboard | dashboard | core | All | high | WF-001 |
| screen.invoicing.client_list | Client List | list | invoicing | Staff, Admin | high | WF-002, WF-003 |
| screen.invoicing.client_detail | Client Detail | detail | invoicing | Staff, Admin | high | WF-002 |
| screen.invoicing.client_form | Client Form | form | invoicing | Admin | medium | Inferred from entity |

### Entity-Screen Coverage Matrix

| Entity | List | Detail | Create | Edit | Delete | Notes |
|--------|------|--------|--------|------|--------|-------|
| Client | screen.invoicing.client_list | screen.invoicing.client_detail | screen.invoicing.client_form | screen.invoicing.client_form | Modal confirm | Full CRUD |
| Invoice | screen.invoicing.invoice_list | screen.invoicing.invoice_detail | screen.invoicing.invoice_wizard | Inline edit | Soft delete | Wizard for create |
| TimeEntry | Embedded in invoice | N/A | Modal | Inline edit | Row delete | Child of Invoice |

### Workflow-Screen Mapping

| Workflow | Step | Screen/Component | Notes |
|----------|------|------------------|-------|
| WF-001: Create Invoice | 1: Select Client | screen.invoicing.invoice_wizard (Step 1) | |
| WF-001: Create Invoice | 2: Add Line Items | screen.invoicing.invoice_wizard (Step 2) | |
| WF-001: Create Invoice | 3: Review | screen.invoicing.invoice_wizard (Step 3) | |
| WF-001: Create Invoice | 4: Send | Modal: Confirm Send | |

### Navigation Map

```yaml
navigation:
  global:
    type: sidebar
    items:
      - label: Dashboard
        screen: screen.core.dashboard
        icon: home
        actors: [all]

      - label: Clients
        screen: screen.invoicing.client_list
        icon: users
        actors: [Staff, Admin]

      - label: Invoices
        screen: screen.invoicing.invoice_list
        icon: file-text
        actors: [Staff, Admin]

      - label: Settings
        screen: screen.admin.settings
        icon: settings
        actors: [Admin]

  screen_flows:
    - from: screen.invoicing.client_list
      to:
        - screen.invoicing.client_detail (click row)
        - screen.invoicing.client_form (click "New Client")

    - from: screen.invoicing.client_detail
      to:
        - screen.invoicing.client_list (back button)
        - screen.invoicing.client_form (click "Edit")
        - screen.invoicing.invoice_wizard (click "New Invoice")

routes:
  - path: /
    screen: screen.core.dashboard
    redirect_if_unauthenticated: /login

  - path: /clients
    screen: screen.invoicing.client_list

  - path: /clients/new
    screen: screen.invoicing.client_form
    mode: create

  - path: /clients/:id
    screen: screen.invoicing.client_detail
    params: [id]

  - path: /clients/:id/edit
    screen: screen.invoicing.client_form
    mode: edit
    params: [id]

  - path: /invoices
    screen: screen.invoicing.invoice_list

  - path: /invoices/new
    screen: screen.invoicing.invoice_wizard
    mode: create

  - path: /invoices/:id
    screen: screen.invoicing.invoice_detail
    params: [id]
```

### Navigation Flow Diagram

```
                    ┌─────────────────────┐
                    │   Global Navigation │
                    └─────────┬───────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌─────────────────┐   ┌───────────────┐
│   Dashboard   │   │   Client List   │   │ Invoice List  │
│               │   │                 │   │               │
└───────────────┘   └────────┬────────┘   └───────┬───────┘
                             │                    │
                    ┌────────┴────────┐     ┌─────┴─────┐
                    │                 │     │           │
                    ▼                 ▼     ▼           ▼
          ┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
          │ Client Detail   │  │ Client Form  │  │Invoice Detail│
          │                 │  │ (Create/Edit)│  │              │
          └────────┬────────┘  └──────────────┘  └──────────────┘
                   │
                   │ "New Invoice"
                   ▼
          ┌─────────────────┐
          │ Invoice Wizard  │
          │ (Multi-step)    │
          └─────────────────┘
```

### Component Library

```yaml
components:
  layout:
    - id: component.layout.page_layout
      name: PageLayout
      description: "Standard page wrapper with header, sidebar, content area"
      used_in: [all screens]

    - id: component.layout.sidebar
      name: Sidebar
      description: "Main navigation sidebar"
      props: [items, collapsed, onToggle]

  data_display:
    - id: component.data.data_table
      name: DataTable
      description: "Sortable, filterable, paginated table"
      used_in:
        - screen.invoicing.client_list
        - screen.invoicing.invoice_list
      props: [columns, data, sortable, filterable, pagination, onRowClick]

    - id: component.data.stat_card
      name: StatCard
      description: "Single metric display with label and optional trend"
      used_in:
        - screen.core.dashboard
      props: [label, value, trend, icon]

  forms:
    - id: component.form.text_field
      name: TextField
      description: "Standard text input with label and validation"
      props: [label, value, onChange, error, required, placeholder]

    - id: component.form.select
      name: Select
      description: "Dropdown selection"
      props: [label, options, value, onChange, searchable, multi]

    - id: component.form.date_picker
      name: DatePicker
      description: "Date selection with calendar"
      props: [label, value, onChange, minDate, maxDate, format]

  domain:
    - id: component.domain.client_card
      name: ClientCard
      description: "Summary card for client info"
      entity: data.invoicing.client
      fields_displayed: [name, email, status, balance]
      used_in:
        - screen.invoicing.client_list
        - screen.core.dashboard

    - id: component.domain.invoice_row
      name: InvoiceRow
      description: "Invoice line item in list or table"
      entity: data.invoicing.invoice
      fields_displayed: [invoice_number, client, total, status, due_date]
      actions: [view, edit, send, void]
```

### Screen Details

For each screen, provide full specification. Example:

---

#### Screen: Client List

**ID**: `screen.invoicing.client_list`
**Type**: list
**Namespace**: invoicing
**Confidence**: high

**Purpose**: Display all clients with search, filter, and sort capabilities. Primary entry point for client management.

**Actors**:
| Actor | Permissions |
|-------|-------------|
| Staff | view |
| Admin | view, edit |

**Entry Points**:
- Global navigation: "Clients" menu item
- Dashboard: "View All Clients" link
- Direct URL: `/clients`

**Data Requirements**:

| Entity | Usage | Fields | Default Sort |
|--------|-------|--------|--------------|
| data.invoicing.client | display | name, email, phone, status, created_at, balance | name ASC |

**Layout**:

```
┌─────────────────────────────────────────────────────────────┐
│ Clients                                    [+ New Client]   │
├─────────────────────────────────────────────────────────────┤
│ [Search...]              [Status ▼]  [Sort ▼]  [Filter ▼]   │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Name          │ Email         │ Status │ Balance │ ... │ │
│ ├───────────────┼───────────────┼────────┼─────────┼─────┤ │
│ │ Acme Corp     │ acme@...      │ Active │ $5,000  │  →  │ │
│ │ Beta Inc      │ beta@...      │ Active │ $2,500  │  →  │ │
│ │ ...           │ ...           │ ...    │ ...     │  →  │ │
│ └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│ Showing 1-10 of 45                    [< Prev] [Next >]     │
└─────────────────────────────────────────────────────────────┘
```

**Actions**:

| Action | Type | Trigger | Result |
|--------|------|---------|--------|
| New Client | primary | Click button | Navigate to client_form (create mode) |
| View Client | row_click | Click row | Navigate to client_detail |
| Search | filter | Type in search | Filter table by name/email |
| Filter | filter | Select filter | Filter table by criteria |
| Export | secondary | Click export | Download CSV |

**States**:

| State | Display |
|-------|---------|
| Loading | Skeleton table rows |
| Empty | "No clients yet. Create your first client to get started." + CTA |
| Error | Toast notification with retry |
| Filtered Empty | "No clients match your filters." + Clear filters button |

**Responsive**:
- Mobile: Cards instead of table, search always visible
- Tablet: Condensed table columns
- Desktop: Full table with all columns

**Accessibility**:
- Table has proper ARIA labels
- Row click also works with Enter key
- Skip link to main content
- Focus visible on all interactive elements

**Derived From**:
- WF-002: Client Management (Step 1: View client list)
- WF-003: Invoice Creation (Step 1: Select client)

---

### Wireframe Template (ASCII)

Use this format for text-based wireframes:

```
Screen: [Name]
Route: [URL path]

┌─────────────────────────────────────────────────────────────┐
│ HEADER: [Page title]                        [Action buttons]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ SECTION: [Section name]                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [Component description]                                 │ │
│ │                                                         │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ SECTION: [Section name]                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [Component description]                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ FOOTER: [Footer content]                                    │
└─────────────────────────────────────────────────────────────┘

Legend:
  [ ] = Button or interactive element
  ▼ = Dropdown
  → = Navigation arrow
  ... = Truncated content
```

### When to Suggest Visual Mockups

Recommend visual mockup tools when:

1. **Complex layouts** - More than 3 nested sections
2. **Custom visualizations** - Charts, graphs, maps
3. **Brand-specific design** - Color, typography decisions
4. **User testing** - Need clickable prototype
5. **Stakeholder presentation** - Non-technical audience

Suggest:
- Figma / Sketch for high-fidelity
- Excalidraw / tldraw for quick sketches
- Balsamiq for wireframes
- Storybook for component documentation

---

## Validation Protocol

### Gap Detection

**Entity Coverage Check:**

For each entity in R2:
```
Entity: [Name]
[ ] Has list view OR is embedded in parent list
[ ] Has detail view OR is embedded in parent detail
[ ] Has create mechanism (form, modal, or embedded)
[ ] Has update mechanism (form, inline, or modal)
[ ] Has delete mechanism OR deletion not applicable
```

Entities with unchecked items → Document why or add screens.

**Workflow Coverage Check:**

For each workflow step in R3:
```
Workflow: [WF-ID] Step: [N]
[ ] Screen or component identified for this step
[ ] All data_read entities have display on screen
[ ] All data_write entities have input mechanism
[ ] Decision points have UI representation (buttons, modals)
[ ] Error states have UI representation
```

Steps with unchecked items → Add screens or document as background process.

**Navigation Consistency Check:**

```
[ ] Every screen has at least one entry point
[ ] Every screen has at least one exit (except dead-end wizards with completion)
[ ] No orphan screens (screens with no navigation to them)
[ ] Back navigation is consistent (breadcrumb or back button)
[ ] User can always return to a known state
```

---

## Validation Checklist

R4 cannot be marked complete until all REQUIRED items are checked:

### Required (Blocks Completion)

**Screen Coverage**
- [ ] At least 1 screen per workflow
- [ ] At least 1 screen or embedded view per entity
- [ ] All primary actor goals have corresponding screens
- [ ] Every workflow step maps to a screen or component

**Navigation**
- [ ] Global navigation defined
- [ ] All screens have entry points documented
- [ ] Route structure defined (for web applications)
- [ ] No orphan screens

**Data Mapping**
- [ ] Each screen specifies required entities
- [ ] Each screen specifies which fields are displayed/editable
- [ ] Forms specify field validation requirements

**States**
- [ ] Loading states defined for data-fetching screens
- [ ] Empty states defined for list screens
- [ ] Error handling approach documented

### Recommended (Quality Gates)

- [ ] Component library started with at least 3 shared components
- [ ] ASCII wireframes for complex screens
- [ ] Responsive behavior documented for primary screens
- [ ] Accessibility requirements noted
- [ ] Offline behavior documented (if applicable from R1)

### Items Needing Validation

| Item | Current Assumption | Risk if Wrong | Follow-up Question |
|------|-------------------|---------------|-------------------|
| [Screen/Component] | [Assumption] | [What breaks] | [Question to ask] |

---

## State Update

When R4 completes, update `discovery/discovery-state.json`:

```json
{
  "rounds": {
    "R4": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "screens_discovered": {{ count }},
      "components_identified": {{ count }},
      "routes_defined": {{ count }}
    }
  },
  "current_round": "R5",

  "screens": [
    {
      "id": "screen.{{ namespace }}.{{ name }}",
      "name": "{{ Screen Name }}",
      "type": "{{ list | detail | form | dashboard | wizard | settings }}",
      "namespace": "{{ namespace }}",
      "entities": ["data.namespace.entity1", "data.namespace.entity2"],
      "workflows": ["WF-001", "WF-002"],
      "confidence": "{{ high | medium | low }}",
      "status": "discovered"
    }
  ],

  "components": [
    {
      "id": "component.{{ category }}.{{ name }}",
      "name": "{{ Component Name }}",
      "category": "{{ layout | navigation | data_display | forms | feedback | domain }}",
      "reused_count": {{ count }}
    }
  ],

  "navigation": {
    "type": "{{ sidebar | top_nav | bottom_tabs | hamburger }}",
    "routes": [
      {
        "path": "/{{ path }}",
        "screen": "screen.{{ namespace }}.{{ name }}",
        "params": ["{{ param }}"]
      }
    ]
  }
}
```

### Node Generation

For each screen, create a node entry:

```json
{
  "id": "screen.{{ namespace }}.{{ name }}",
  "name": "{{ Screen Name }}",
  "type": "screen",
  "namespace": "{{ namespace }}",
  "tags": ["user-facing", "{{ module }}"],
  "status": "discovered",

  "requires": [
    "data.{{ namespace }}.{{ entity1 }}",
    "data.{{ namespace }}.{{ entity2 }}"
  ],
  "parallel_hints": ["{{ other screens in same namespace with no data overlap }}"],

  "spec": {
    "purpose": "{{ screen purpose }}",
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Displays {{ entity }} data correctly", "verification_method": "manual" },
      { "id": "AC-2", "description": "{{ Primary action }} works", "verification_method": "automated" },
      { "id": "AC-3", "description": "Responsive on mobile", "verification_method": "manual" }
    ],
    "context_files": ["{{ related components }}"],
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
    "source_round": 4,
    "confidence": "{{ high | medium | low }}",
    "inferred_from": [
      "workflow: WF-001 step 3",
      "entity: data.namespace.entity needs CRUD"
    ],
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  },

  "build": {
    "estimated_effort": "{{ xs | s | m | l | xl }}",
    "files": {
      "creates": ["src/screens/{{ ScreenName }}.tsx", "src/screens/{{ ScreenName }}.test.tsx"],
      "modifies": ["src/App.tsx", "src/routes.ts"],
      "reads": ["src/api/{{ entity }}.ts", "src/components/{{ Component }}.tsx"]
    },
    "testing": {
      "unit_tests_required": true,
      "integration_tests_required": false,
      "smoke_commands": ["npm run test -- {{ ScreenName }}"]
    }
  }
}
```

---

## Cross-Reference with R2/R3

After completing screen discovery, validate against earlier rounds:

### R2 (Entities) Cross-Check

| Check | Action if Failed |
|-------|------------------|
| Every entity has screen coverage | Add missing screens or document embedding |
| Screen field lists match entity attributes | Add missing attributes to R2 or remove from screen |
| Relationships reflected in navigation | Add navigation between related entity screens |

### R3 (Workflows) Cross-Check

| Check | Action if Failed |
|-------|------------------|
| Every workflow step has screen/component | Add missing screens or mark as background process |
| Decision points have UI triggers | Add buttons, modals, or confirm dialogs |
| Error paths have error screens | Add error states or recovery screens |
| Workflow track screens don't conflict | Validate with parallelization from R3 |

### Feedback Loop

If R4 discovers gaps in R2/R3:
1. Document the gap in R4 output
2. Add to `blocking_issues` if critical
3. Note what needs to be added to R2/R3
4. R5 (Edge Cases) will stress-test these gaps

---

## Key Principles

### 1. Show, Don't Tell

Screens are validation tools. Users can't critique "an entity with attributes" but they can critique "a form with these fields in this order."

### 2. UI-First Derivation

Work backwards:
- What does the user need to see? → Data requirements
- What does the user need to do? → Actions and navigation
- What could go wrong? → Error states

### 3. Progressive Disclosure

Don't show everything at once:
- List screens show summary
- Detail screens show more
- Edit mode shows input fields
- Advanced options are collapsed or secondary

### 4. Mobile-First or Desktop-First

Based on R1 decisions:
- **Mobile-first**: Design smallest screen first, scale up
- **Desktop-first**: Design full experience first, simplify down

Document which approach and stick to it.

### 5. Each Screen = Node

Every screen becomes a `screen` type node with:
- Dependencies on data nodes (entities it needs)
- Dependencies on other screens (navigation chains)
- Parallel hints (screens that can build simultaneously)

---

## Next Steps

After R4 completes:

1. Save as `discovery/R4_SCREENS.md`
2. Update `discovery-state.json` with screens, components, navigation
3. Validate cross-references with R2 and R3
4. Announce completion:
   > "Screen discovery complete. Found {{ screen_count }} screens with {{ component_count }} shared components. {{ route_count }} routes defined. Proceeding to R5 (Edge Cases) to stress-test the design."
5. Proceed to R5: Edge Cases

---

## Quick Reference

### Screen Types

| Type | Purpose | Common Patterns |
|------|---------|-----------------|
| list | Show multiple records | Table, Cards, Infinite scroll |
| detail | Show single record | Sections, Tabs, Accordions |
| form | Create/edit record | Vertical form, Multi-column, Wizard |
| dashboard | Overview/summary | Stats, Charts, Quick actions |
| wizard | Multi-step process | Steps, Progress bar, Back/Next |
| settings | Configuration | Grouped fields, Toggles |
| report | Read-only analysis | Tables, Charts, Filters |
| modal | Overlay interaction | Confirmation, Quick form, Preview |

### Screen Node ID Pattern

```
screen.{namespace}.{name}
```

Examples:
- `screen.invoicing.client_list`
- `screen.invoicing.client_detail`
- `screen.invoicing.client_form`
- `screen.core.dashboard`
- `screen.admin.settings`

### Minimal Screen YAML Template

```yaml
screen:
  id: screen.{{ namespace }}.{{ name }}
  name: ""
  type: list | detail | form | dashboard | wizard
  namespace: ""

  purpose: ""

  actors:
    - name: ""
      permissions: [view]

  entry_points:
    - from: ""
      trigger: ""

  data_requirements:
    entities:
      - entity: ""
        usage: display
        fields: []

  actions:
    primary:
      - label: ""
        action: ""

  states:
    loading:
      type: skeleton
    empty:
      message: ""

  metadata:
    confidence: medium
    derived_from:
      workflows: []
      entities: []
```
