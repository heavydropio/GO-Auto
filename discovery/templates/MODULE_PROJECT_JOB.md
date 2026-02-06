# Project & Job Module Catalog

**Module**: Project & Job
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Project & Job module covers work organization, resource allocation, time tracking, and cost management. This module enables businesses to plan work, assign resources, track progress, capture time and expenses against projects, and measure profitability.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "project", "job", "engagement" | Project Manager, Team Lead | Organize and track work delivery |
| "time tracking", "timesheet", "hours" | Employees, Contractors | Capture billable and non-billable time |
| "resource allocation", "staffing", "assignment" | Resource Manager, PM | Assign people to work |
| "milestone", "deliverable", "phase" | PM, Client, Executive | Track progress checkpoints |
| "project expense", "job cost", "cost tracking" | PM, Finance | Track spending against projects |
| "budget", "burn rate", "project profitability" | PM, Finance, Executive | Monitor financial health of work |

### Module Dependencies

```
Project & Job Module
├── REQUIRES: Administrative (for settings, user preferences)
├── REQUIRES: Documents (for deliverables, attachments)
├── INTEGRATES_WITH: Financial (invoicing billable time/expenses)
├── INTEGRATES_WITH: CRM (client/opportunity to project conversion)
├── INTEGRATES_WITH: HR (employee availability, cost rates)
├── INTEGRATES_WITH: Calendar (scheduling, availability)
```

---

## Core Design Principles

### Rate Snapshotting

**Critical**: Always snapshot billing rates and cost rates at time of entry creation, not at invoice or report generation time.

```
TimeEntry.billing_rate = User.billing_rate_at_entry_date
TimeEntry.cost_rate = User.cost_rate_at_entry_date
```

This ensures:
- Historical accuracy when rates change
- Correct project profitability calculations
- Audit trail of actual costs

### Hierarchy Limits

Avoid hierarchies deeper than 3 levels:

```
Project (Level 1)
  └── Task (Level 2)
        └── Subtask (Level 3)
```

Deeper nesting creates:
- UI complexity
- Reporting confusion
- Rollup calculation overhead

### What NOT to Model

| Anti-pattern | Why to Avoid | Alternative |
|--------------|--------------|-------------|
| Separate Phase entity | Adds complexity without value | Use Task with `is_phase=true` or tags |
| Gantt dependencies as entities | Creates rigid coupling | Store as task field `depends_on_task_ids` |
| Hierarchy deeper than 3 levels | Cognitive and performance overhead | Flatten or use tags |
| Real-time rate lookup | Historical inaccuracy | Snapshot at entry time |

---

## Packages

This module contains 5 packages:

1. **projects** - Project/job lifecycle management
2. **tasks** - Work breakdown and assignment
3. **time_tracking** - Capturing time worked
4. **expenses** - Project-specific expense tracking
5. **resource_allocation** - Staffing and capacity management

---

## Package 1: Projects

### Purpose

Create, manage, and track projects or jobs from inception to completion. Supports multiple billing models and client relationships.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What do you call work engagements? (project, job, matter, engagement)
- What billing models do you use? (fixed price, T&M, milestone, retainer)
- Do projects have budgets? (hours, dollars, both)
- Do you use project templates for recurring work types?
- What information do you track per project? (team, dates, budgets, custom fields)

**Workflow Discovery**:
- How are projects initiated? (won opportunity, signed contract, internal request)
- Who approves new projects?
- How do you track project status/phases?
- When is a project considered complete?
- How do you handle scope changes?

**Edge Case Probing**:
- Can a project have multiple clients?
- What happens when a project is paused or canceled?
- How do you handle projects that span fiscal years?

### Entity Templates

#### Project

```json
{
  "id": "data.projects.project",
  "name": "Project",
  "type": "data",
  "namespace": "projects",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a body of work performed for a client or internal purpose.",
    "fields": [
      { "name": "project_number", "type": "string", "required": true, "description": "Unique sequential identifier (e.g., PRJ-2026-0001)" },
      { "name": "name", "type": "string", "required": true, "description": "Project name" },
      { "name": "client_id", "type": "uuid", "required": false, "description": "Client this project is for (null for internal)" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "active", "on_hold", "completed", "canceled", "archived"], "description": "Current project state" },
      { "name": "billing_model", "type": "enum", "required": true, "values": ["time_and_materials", "fixed_price", "milestone", "retainer", "non_billable"], "description": "How this project is billed" },
      { "name": "start_date", "type": "date", "required": false, "description": "Planned or actual start date" },
      { "name": "target_end_date", "type": "date", "required": false, "description": "Planned completion date" },
      { "name": "actual_end_date", "type": "date", "required": false, "description": "Actual completion date" },
      { "name": "budget_hours", "type": "decimal", "required": false, "description": "Budgeted hours (BAC in hours)" },
      { "name": "budget_amount", "type": "decimal", "required": false, "description": "Budgeted cost/revenue (BAC in dollars)" },
      { "name": "currency", "type": "string", "required": true, "description": "ISO 4217 currency code" },
      { "name": "project_manager_id", "type": "uuid", "required": false, "description": "Primary project manager" },
      { "name": "description", "type": "text", "required": false, "description": "Project description and scope" },
      { "name": "is_internal", "type": "boolean", "required": true, "description": "Internal vs client-facing project" },
      { "name": "billable", "type": "boolean", "required": true, "description": "Whether work is billable to client" },
      { "name": "template_id", "type": "uuid", "required": false, "description": "Template this project was created from" },
      { "name": "tags", "type": "array", "required": false, "description": "Project tags for categorization" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false, "alias": "project_manager" },
      { "entity": "Task", "type": "one_to_many", "required": false },
      { "entity": "TimeEntry", "type": "one_to_many", "required": false },
      { "entity": "Expense", "type": "one_to_many", "required": false },
      { "entity": "Milestone", "type": "one_to_many", "required": false },
      { "entity": "ResourceAllocation", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.projects",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ProjectTemplate

```json
{
  "id": "data.projects.project_template",
  "name": "Project Template",
  "type": "data",
  "namespace": "projects",
  "tags": ["core-entity", "configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Reusable template for creating projects with predefined structure.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Template name" },
      { "name": "description", "type": "text", "required": false, "description": "What this template is for" },
      { "name": "billing_model", "type": "enum", "required": true, "values": ["time_and_materials", "fixed_price", "milestone", "retainer", "non_billable"], "description": "Default billing model" },
      { "name": "default_budget_hours", "type": "decimal", "required": false, "description": "Typical hours for this project type" },
      { "name": "default_budget_amount", "type": "decimal", "required": false, "description": "Typical budget for this project type" },
      { "name": "task_templates", "type": "json", "required": false, "description": "Predefined task structure" },
      { "name": "milestone_templates", "type": "json", "required": false, "description": "Predefined milestones" },
      { "name": "default_team_roles", "type": "json", "required": false, "description": "Role types needed for this project" },
      { "name": "active", "type": "boolean", "required": true, "description": "Template is available for use" }
    ],
    "relationships": [
      { "entity": "Project", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "project_job.projects",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Milestone

```json
{
  "id": "data.projects.milestone",
  "name": "Milestone",
  "type": "data",
  "namespace": "projects",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Key checkpoint or deliverable within a project.",
    "fields": [
      { "name": "project_id", "type": "uuid", "required": true, "description": "Parent project" },
      { "name": "name", "type": "string", "required": true, "description": "Milestone name" },
      { "name": "description", "type": "text", "required": false, "description": "What this milestone represents" },
      { "name": "due_date", "type": "date", "required": true, "description": "Target completion date" },
      { "name": "completed_date", "type": "date", "required": false, "description": "Actual completion date" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "in_progress", "completed", "missed"], "description": "Current status" },
      { "name": "billing_amount", "type": "decimal", "required": false, "description": "Amount to invoice when complete (milestone billing)" },
      { "name": "billing_percent", "type": "decimal", "required": false, "description": "Percent of project total to invoice" },
      { "name": "invoiced", "type": "boolean", "required": false, "description": "Whether milestone has been billed" },
      { "name": "invoice_id", "type": "uuid", "required": false, "description": "Associated invoice if billed" },
      { "name": "sort_order", "type": "integer", "required": true, "description": "Display order" }
    ],
    "relationships": [
      { "entity": "Project", "type": "many_to_one", "required": true },
      { "entity": "Task", "type": "one_to_many", "required": false },
      { "entity": "Invoice", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.projects",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.projects.initiate_project

```yaml
workflow:
  id: "wf.projects.initiate_project"
  name: "Initiate New Project"
  trigger: "Won opportunity, signed contract, or internal request"
  actors: ["Sales", "Project Manager", "Resource Manager", "Finance"]

  steps:
    - step: 1
      name: "Create Project Record"
      actor: "Sales or Project Manager"
      action: "Create project from template or blank"
      inputs: ["Client", "Project details", "Template (optional)"]
      outputs: ["Draft project"]

    - step: 2
      name: "Define Scope and Budget"
      actor: "Project Manager"
      action: "Set budget, dates, billing model, milestones"
      inputs: ["Draft project", "Contract/SOW"]
      outputs: ["Scoped project"]

    - step: 3
      name: "Request Resources"
      actor: "Project Manager"
      action: "Identify and request team members"
      inputs: ["Scoped project", "Role requirements"]
      outputs: ["Resource requests"]

    - step: 4
      name: "Allocate Resources"
      actor: "Resource Manager"
      action: "Assign team members based on availability"
      inputs: ["Resource requests", "Availability data"]
      outputs: ["Resource allocations"]
      decision_point: "Resources available? Need alternatives?"

    - step: 5
      name: "Approve Project"
      actor: "Finance or Executive"
      action: "Review and approve project setup"
      inputs: ["Scoped project", "Resource allocations"]
      outputs: ["Approved project"]
      condition: "Project exceeds approval threshold"

    - step: 6
      name: "Activate Project"
      actor: "System"
      action: "Set status to active, notify team"
      inputs: ["Approved project"]
      outputs: ["Active project", "Team notifications"]
      automatable: true
```

#### wf.projects.close_project

```yaml
workflow:
  id: "wf.projects.close_project"
  name: "Close Project"
  trigger: "Project work completed or canceled"
  actors: ["Project Manager", "Finance", "Client"]

  steps:
    - step: 1
      name: "Verify Completeness"
      actor: "Project Manager"
      action: "Ensure all tasks complete, time submitted"
      inputs: ["Project", "Open tasks", "Pending time entries"]
      outputs: ["Completion checklist"]
      decision_point: "All work captured?"

    - step: 2
      name: "Final Billing Review"
      actor: "Finance"
      action: "Review unbilled time/expenses, generate final invoice"
      inputs: ["Unbilled items", "Project budget"]
      outputs: ["Final invoice"]

    - step: 3
      name: "Client Acceptance"
      actor: "Client"
      action: "Confirm deliverables received and accepted"
      inputs: ["Deliverables list", "Acceptance criteria"]
      outputs: ["Client sign-off"]
      condition: "Requires formal acceptance"

    - step: 4
      name: "Release Resources"
      actor: "System"
      action: "End resource allocations, update availability"
      inputs: ["Project allocations"]
      outputs: ["Released resources"]
      automatable: true

    - step: 5
      name: "Archive Project"
      actor: "Project Manager"
      action: "Set status to completed/archived"
      inputs: ["Closed project"]
      outputs: ["Archived project"]

    - step: 6
      name: "Conduct Retrospective"
      actor: "Project Manager"
      action: "Capture lessons learned, update templates"
      inputs: ["Project history", "Team feedback"]
      outputs: ["Retrospective notes"]
      condition: "Standard practice or significant project"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRJ-001 | **Project spans fiscal years** | Medium | Track budget and actuals by fiscal period; allow multi-year reporting |
| EC-PRJ-002 | **Client requests scope change mid-project** | High | Create change order workflow; update budget and milestones |
| EC-PRJ-003 | **Project put on hold indefinitely** | Medium | Freeze time entry; release resources; maintain audit trail |
| EC-PRJ-004 | **Key team member leaves mid-project** | High | Reallocate tasks; update resource plan; capture knowledge transfer |
| EC-PRJ-005 | **Budget exhausted before completion** | High | Alert PM; require approval to continue; renegotiate with client |
| EC-PRJ-006 | **Multiple clients on same project** | Medium | Support multiple client associations; split billing rules |
| EC-PRJ-007 | **Project template updated after projects created** | Low | Templates are snapshots; existing projects unchanged |
| EC-PRJ-008 | **Retainer project with unused hours** | Medium | Define rollover policy; track by period |
| EC-PRJ-009 | **Project canceled after partial work** | Medium | Bill for work completed; handle in-progress tasks |
| EC-PRJ-010 | **Time logged to wrong project** | Medium | Allow corrections with audit trail; recalculate totals |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRJ-001 | **Template suggestion** | Project description, client history | Recommended template | Speeds project setup |
| AI-PRJ-002 | **Budget estimation** | Project scope, historical data | Suggested hours/cost | More accurate estimates |
| AI-PRJ-003 | **Risk detection** | Project metrics, patterns | Risk alerts | Early intervention |
| AI-PRJ-004 | **Completion forecasting** | Progress, velocity, remaining work | Predicted end date | Proactive scheduling |
| AI-PRJ-005 | **Scope creep detection** | Hours vs budget trend | Scope creep warning | Budget protection |

---

## Package 2: Tasks

### Purpose

Break down projects into manageable work items, assign owners, and track progress. Supports 2-level hierarchy (tasks and subtasks).

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How granular is your task breakdown? (phases, tasks, subtasks)
- What task statuses do you use?
- Do tasks have estimates? (hours, story points)
- Do tasks have dependencies on other tasks?
- What fields do you track per task?

**Workflow Discovery**:
- Who creates tasks? (PM only, team members)
- How are tasks assigned?
- How do you track task progress?
- Do you use boards/kanban views?

**Edge Case Probing**:
- Can a task be assigned to multiple people?
- What happens when a task is blocked?
- Can tasks move between projects?

### Entity Templates

#### Task

```json
{
  "id": "data.tasks.task",
  "name": "Task",
  "type": "data",
  "namespace": "tasks",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A unit of work within a project.",
    "fields": [
      { "name": "project_id", "type": "uuid", "required": true, "description": "Parent project" },
      { "name": "parent_task_id", "type": "uuid", "required": false, "description": "Parent task if subtask (max 1 level)" },
      { "name": "milestone_id", "type": "uuid", "required": false, "description": "Associated milestone" },
      { "name": "name", "type": "string", "required": true, "description": "Task name" },
      { "name": "description", "type": "text", "required": false, "description": "Task details" },
      { "name": "status", "type": "enum", "required": true, "values": ["backlog", "todo", "in_progress", "review", "blocked", "completed", "canceled"], "description": "Current status" },
      { "name": "priority", "type": "enum", "required": false, "values": ["low", "medium", "high", "urgent"], "description": "Task priority" },
      { "name": "assignee_id", "type": "uuid", "required": false, "description": "Primary person responsible" },
      { "name": "estimated_hours", "type": "decimal", "required": false, "description": "Estimated effort in hours" },
      { "name": "actual_hours", "type": "decimal", "required": false, "description": "Computed from time entries" },
      { "name": "due_date", "type": "date", "required": false, "description": "Task due date" },
      { "name": "start_date", "type": "date", "required": false, "description": "Planned start date" },
      { "name": "completed_date", "type": "date", "required": false, "description": "Actual completion date" },
      { "name": "depends_on_task_ids", "type": "array", "required": false, "description": "Tasks that must complete first" },
      { "name": "is_phase", "type": "boolean", "required": false, "description": "Task represents a project phase" },
      { "name": "billable", "type": "boolean", "required": true, "description": "Time against this task is billable" },
      { "name": "sort_order", "type": "integer", "required": false, "description": "Display order within parent" },
      { "name": "tags", "type": "array", "required": false, "description": "Task tags" }
    ],
    "relationships": [
      { "entity": "Project", "type": "many_to_one", "required": true },
      { "entity": "Task", "type": "many_to_one", "required": false, "alias": "parent_task" },
      { "entity": "Task", "type": "one_to_many", "required": false, "alias": "subtasks" },
      { "entity": "Milestone", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false, "alias": "assignee" },
      { "entity": "TimeEntry", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.tasks",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.tasks.manage_task_lifecycle

```yaml
workflow:
  id: "wf.tasks.manage_task_lifecycle"
  name: "Task Lifecycle Management"
  trigger: "Task status changes"
  actors: ["Assignee", "Project Manager", "System"]

  steps:
    - step: 1
      name: "Create Task"
      actor: "Project Manager or Assignee"
      action: "Define task with estimates and due date"
      inputs: ["Project", "Task details"]
      outputs: ["New task in backlog/todo"]

    - step: 2
      name: "Assign Task"
      actor: "Project Manager"
      action: "Assign to team member"
      inputs: ["Task", "Available team members"]
      outputs: ["Assigned task"]

    - step: 3
      name: "Start Work"
      actor: "Assignee"
      action: "Move to in_progress, begin tracking time"
      inputs: ["Assigned task"]
      outputs: ["In-progress task"]

    - step: 4
      name: "Track Blockers"
      actor: "Assignee"
      action: "Mark as blocked if dependencies or issues arise"
      inputs: ["In-progress task", "Blocking reason"]
      outputs: ["Blocked task with reason"]
      condition: "Work cannot proceed"

    - step: 5
      name: "Complete Work"
      actor: "Assignee"
      action: "Mark as complete or move to review"
      inputs: ["Task with all time logged"]
      outputs: ["Completed/review task"]

    - step: 6
      name: "Update Rollups"
      actor: "System"
      action: "Recalculate project progress, milestone status"
      inputs: ["Completed task"]
      outputs: ["Updated project metrics"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-TSK-001 | **Task assigned to unavailable person** | Medium | Check availability at assignment; allow override with warning |
| EC-TSK-002 | **Subtask created under completed parent** | Low | Prevent or reopen parent automatically |
| EC-TSK-003 | **Circular dependency created** | High | Validate dependencies on save; prevent cycles |
| EC-TSK-004 | **Task moved to different project** | Medium | Move time entries with it; update allocations |
| EC-TSK-005 | **Completed task has open subtasks** | Medium | Require subtasks complete first or auto-complete |
| EC-TSK-006 | **Time logged exceeds estimate significantly** | Medium | Alert PM; track variance for future estimates |
| EC-TSK-007 | **Blocked task with no blocking reason** | Low | Require reason when setting blocked status |
| EC-TSK-008 | **Multiple assignees needed** | Medium | Use watchers or create subtasks; single primary owner |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-TSK-001 | **Effort estimation** | Task description, historical tasks | Suggested hours | Better planning |
| AI-TSK-002 | **Assignee recommendation** | Task requirements, team skills | Suggested assignee | Optimal matching |
| AI-TSK-003 | **Dependency detection** | Task descriptions | Suggested dependencies | Catches missing links |
| AI-TSK-004 | **Duplicate detection** | New task, existing tasks | Potential duplicates | Prevents redundancy |

---

## Package 3: Time Tracking

### Purpose

Capture time worked by employees and contractors against projects and tasks. Support multiple entry methods and approval workflows.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How do employees enter time? (timer, manual, weekly timesheet)
- What time increments do you use? (minutes, quarter-hours, hours)
- Do you distinguish billable vs non-billable time?
- Do you track activity types? (meetings, development, admin)
- Do you have minimum daily/weekly requirements?

**Workflow Discovery**:
- When is time submitted? (daily, weekly, project completion)
- Who approves timesheets? (PM, manager, auto-approve)
- Can approved time be edited?
- How does time flow to invoicing?

**Edge Case Probing**:
- Can time be logged for past dates? How far back?
- What if someone logs time to a closed project?
- How do you handle overtime or after-hours work?

### Entity Templates

#### TimeEntry

```json
{
  "id": "data.time_tracking.time_entry",
  "name": "Time Entry",
  "type": "data",
  "namespace": "time_tracking",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of time worked on a project or task.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Who performed the work" },
      { "name": "project_id", "type": "uuid", "required": true, "description": "Project time is logged to" },
      { "name": "task_id", "type": "uuid", "required": false, "description": "Specific task if applicable" },
      { "name": "date", "type": "date", "required": true, "description": "Date work was performed" },
      { "name": "hours", "type": "decimal", "required": true, "description": "Duration in hours" },
      { "name": "description", "type": "text", "required": true, "description": "Work description" },
      { "name": "activity_type", "type": "enum", "required": false, "values": ["development", "design", "meeting", "planning", "review", "admin", "travel", "other"], "description": "Type of activity" },
      { "name": "billable", "type": "boolean", "required": true, "description": "Time is billable to client" },
      { "name": "billing_rate", "type": "decimal", "required": false, "description": "Rate per hour (snapshotted at entry)" },
      { "name": "cost_rate", "type": "decimal", "required": false, "description": "Internal cost rate (snapshotted at entry)" },
      { "name": "billing_amount", "type": "decimal", "required": false, "description": "hours * billing_rate" },
      { "name": "cost_amount", "type": "decimal", "required": false, "description": "hours * cost_rate" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "rejected", "billed", "locked"], "description": "Workflow status" },
      { "name": "timesheet_id", "type": "uuid", "required": false, "description": "Parent timesheet if grouped" },
      { "name": "invoice_line_id", "type": "uuid", "required": false, "description": "Link to invoice if billed" },
      { "name": "start_time", "type": "time", "required": false, "description": "Start time if using timer" },
      { "name": "end_time", "type": "time", "required": false, "description": "End time if using timer" },
      { "name": "timer_running", "type": "boolean", "required": false, "description": "Timer currently active" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why entry was rejected" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Project", "type": "many_to_one", "required": true },
      { "entity": "Task", "type": "many_to_one", "required": false },
      { "entity": "Timesheet", "type": "many_to_one", "required": false },
      { "entity": "InvoiceLine", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.time_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Timesheet

```json
{
  "id": "data.time_tracking.timesheet",
  "name": "Timesheet",
  "type": "data",
  "namespace": "time_tracking",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Weekly collection of time entries for approval.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Employee submitting timesheet" },
      { "name": "period_start", "type": "date", "required": true, "description": "First day of period (usually Monday)" },
      { "name": "period_end", "type": "date", "required": true, "description": "Last day of period (usually Sunday)" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "rejected", "locked"], "description": "Approval status" },
      { "name": "total_hours", "type": "decimal", "required": true, "description": "Sum of all time entries" },
      { "name": "billable_hours", "type": "decimal", "required": true, "description": "Sum of billable entries" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When submitted for approval" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "Who approved" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "Approval timestamp" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why rejected" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "TimeEntry", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "project_job.time_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### UserRate

```json
{
  "id": "data.time_tracking.user_rate",
  "name": "User Rate",
  "type": "data",
  "namespace": "time_tracking",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Billing and cost rates for a user, effective dated.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "User this rate applies to" },
      { "name": "effective_date", "type": "date", "required": true, "description": "When rate becomes active" },
      { "name": "billing_rate", "type": "decimal", "required": true, "description": "Default billing rate per hour" },
      { "name": "cost_rate", "type": "decimal", "required": true, "description": "Internal cost rate per hour" },
      { "name": "currency", "type": "string", "required": true, "description": "Rate currency" },
      { "name": "rate_type", "type": "enum", "required": false, "values": ["standard", "overtime", "weekend", "holiday"], "description": "Type of rate" },
      { "name": "notes", "type": "text", "required": false, "description": "Rate change notes" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "Rates are looked up by effective_date to snapshot into TimeEntry at creation."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.time_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.time_tracking.submit_timesheet

```yaml
workflow:
  id: "wf.time_tracking.submit_timesheet"
  name: "Submit and Approve Timesheet"
  trigger: "End of time period or manual submission"
  actors: ["Employee", "Manager", "System"]

  steps:
    - step: 1
      name: "Enter Time"
      actor: "Employee"
      action: "Log time entries throughout week"
      inputs: ["Projects", "Tasks", "Work performed"]
      outputs: ["Draft time entries"]

    - step: 2
      name: "Validate Entries"
      actor: "System"
      action: "Check for required hours, missing descriptions, project status"
      inputs: ["Draft time entries", "Policies"]
      outputs: ["Validation warnings"]
      automatable: true

    - step: 3
      name: "Submit Timesheet"
      actor: "Employee"
      action: "Review and submit for approval"
      inputs: ["Validated entries"]
      outputs: ["Submitted timesheet"]

    - step: 4
      name: "Route for Approval"
      actor: "System"
      action: "Send to appropriate approver(s)"
      inputs: ["Submitted timesheet", "Approval rules"]
      outputs: ["Approval request"]
      automatable: true

    - step: 5
      name: "Review and Approve"
      actor: "Manager"
      action: "Review entries, approve or reject"
      inputs: ["Submitted timesheet"]
      outputs: ["Approval decision"]
      decision_point: "Approve all? Reject specific entries?"

    - step: 6a
      name: "Lock Timesheet"
      actor: "System"
      action: "Mark approved, prevent edits, update task actuals"
      inputs: ["Approved timesheet"]
      outputs: ["Locked timesheet", "Updated project hours"]
      condition: "Approved"
      automatable: true

    - step: 6b
      name: "Return for Correction"
      actor: "System"
      action: "Notify employee of rejection, unlock for edits"
      inputs: ["Rejected timesheet", "Rejection reason"]
      outputs: ["Unlocked timesheet", "Rejection notification"]
      condition: "Rejected"
      automatable: true
```

#### wf.time_tracking.bill_time

```yaml
workflow:
  id: "wf.time_tracking.bill_time"
  name: "Bill Approved Time"
  trigger: "Billing cycle or manual invoice creation"
  actors: ["Accountant", "System"]

  steps:
    - step: 1
      name: "Select Unbilled Time"
      actor: "Accountant"
      action: "Query approved, unbilled time entries"
      inputs: ["Client", "Project", "Date range"]
      outputs: ["Billable time entries"]

    - step: 2
      name: "Review and Adjust"
      actor: "Accountant"
      action: "Adjust descriptions, apply discounts, write off entries"
      inputs: ["Billable time entries"]
      outputs: ["Invoice-ready entries"]
      decision_point: "Any adjustments needed?"

    - step: 3
      name: "Generate Invoice Lines"
      actor: "System"
      action: "Create invoice with time entry line items"
      inputs: ["Invoice-ready entries"]
      outputs: ["Draft invoice"]
      automatable: true

    - step: 4
      name: "Mark Time as Billed"
      actor: "System"
      action: "Update time entry status, link to invoice"
      inputs: ["Sent invoice"]
      outputs: ["Billed time entries"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-TIM-001 | **Time logged to closed project** | Medium | Warn user; allow with PM override or reject |
| EC-TIM-002 | **Retroactive time entry past lock date** | Medium | Require manager approval for past entries beyond threshold |
| EC-TIM-003 | **Timer left running overnight** | Low | Alert on excessive duration; cap at configurable max |
| EC-TIM-004 | **Rate changed after time logged** | Low | Rates are snapshotted; no retroactive changes |
| EC-TIM-005 | **Approved time needs correction** | Medium | Unlock requires manager approval; maintain audit trail |
| EC-TIM-006 | **Billable time on non-billable project** | Low | Use project billable flag as default; allow override per entry |
| EC-TIM-007 | **User logs to project they're not allocated to** | Low | Allow with warning; report unallocated time |
| EC-TIM-008 | **Timesheet submitted without minimum hours** | Medium | Warn but allow; track for compliance reporting |
| EC-TIM-009 | **Billed time entry needs write-off** | Medium | Create credit memo; reverse billing status |
| EC-TIM-010 | **Duplicate time entries for same period** | Medium | Detect overlapping times; warn user |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-TIM-001 | **Description enhancement** | Raw notes | Professional description | Better invoice quality |
| AI-TIM-002 | **Missing time detection** | Calendar, expected hours | Gap alerts | Improve time capture |
| AI-TIM-003 | **Project suggestion** | Description, history | Likely project/task | Faster entry |
| AI-TIM-004 | **Anomaly detection** | Entry patterns | Unusual entries flagged | Catch errors |
| AI-TIM-005 | **Rounding optimization** | Raw time, billing rules | Optimal rounding | Maximize revenue |

---

## Package 4: Expenses

### Purpose

Track project-related expenses separately from employee reimbursement. Expenses can be billable to clients or absorbed as project costs.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What expense categories apply to projects? (travel, materials, subcontractors)
- Are expenses marked up before billing?
- Do you require receipts for project expenses?
- Do you track vendor/supplier for expenses?

**Workflow Discovery**:
- Who submits project expenses? (PM, team members, AP)
- What approval is needed?
- How do expenses flow to invoicing?
- Do you track against project budget?

**Edge Case Probing**:
- Expense incurred on multiple projects?
- Expense exceeds project budget?
- Vendor credit applied to previously billed expense?

### Entity Templates

#### ProjectExpense

```json
{
  "id": "data.expenses.project_expense",
  "name": "Project Expense",
  "type": "data",
  "namespace": "expenses",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "An expense incurred for a specific project.",
    "fields": [
      { "name": "project_id", "type": "uuid", "required": true, "description": "Project this expense is for" },
      { "name": "task_id", "type": "uuid", "required": false, "description": "Specific task if applicable" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "Who incurred or submitted expense" },
      { "name": "date", "type": "date", "required": true, "description": "Date expense incurred" },
      { "name": "category", "type": "string", "required": true, "description": "Expense category" },
      { "name": "description", "type": "string", "required": true, "description": "Expense description" },
      { "name": "vendor", "type": "string", "required": false, "description": "Vendor/supplier name" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Expense amount" },
      { "name": "currency", "type": "string", "required": true, "description": "Original currency" },
      { "name": "billable", "type": "boolean", "required": true, "description": "Billable to client" },
      { "name": "markup_percent", "type": "decimal", "required": false, "description": "Markup applied to billing" },
      { "name": "billing_amount", "type": "decimal", "required": false, "description": "Amount to bill (amount * (1 + markup))" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "rejected", "billed"], "description": "Workflow status" },
      { "name": "receipt_path", "type": "string", "required": false, "description": "Path to receipt document" },
      { "name": "invoice_line_id", "type": "uuid", "required": false, "description": "Link to invoice if billed" },
      { "name": "approval_note", "type": "text", "required": false, "description": "Approver notes" }
    ],
    "relationships": [
      { "entity": "Project", "type": "many_to_one", "required": true },
      { "entity": "Task", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "InvoiceLine", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.expenses",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.expenses.submit_project_expense

```yaml
workflow:
  id: "wf.expenses.submit_project_expense"
  name: "Submit and Approve Project Expense"
  trigger: "Expense incurred on project"
  actors: ["Team Member", "Project Manager", "System"]

  steps:
    - step: 1
      name: "Enter Expense"
      actor: "Team Member"
      action: "Log expense with receipt"
      inputs: ["Project", "Expense details", "Receipt"]
      outputs: ["Draft expense"]

    - step: 2
      name: "Validate Against Budget"
      actor: "System"
      action: "Check expense against remaining project budget"
      inputs: ["Draft expense", "Project budget"]
      outputs: ["Budget check result"]
      automatable: true

    - step: 3
      name: "Submit for Approval"
      actor: "Team Member"
      action: "Submit expense to project manager"
      inputs: ["Validated expense"]
      outputs: ["Pending expense"]

    - step: 4
      name: "Approve Expense"
      actor: "Project Manager"
      action: "Review and approve or reject"
      inputs: ["Pending expense", "Budget status"]
      outputs: ["Approval decision"]
      decision_point: "Approve? Within budget?"

    - step: 5
      name: "Update Project Costs"
      actor: "System"
      action: "Add to project actuals, update budget consumed"
      inputs: ["Approved expense"]
      outputs: ["Updated project financials"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-EXP-001 | **Expense exceeds project budget** | Medium | Alert PM; require approval with budget exception |
| EC-EXP-002 | **Expense split across projects** | Medium | Create linked entries; allocate by percentage |
| EC-EXP-003 | **Markup rate changes** | Low | Apply rate at billing time; store original amount |
| EC-EXP-004 | **Receipt missing for billable expense** | Medium | Flag for follow-up; may affect billing |
| EC-EXP-005 | **Vendor credit for billed expense** | Medium | Create credit memo; reverse billing |
| EC-EXP-006 | **Expense on closed project** | Low | Allow with PM approval; reopen for corrections |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-EXP-001 | **Receipt OCR** | Receipt image | Extracted data | Reduce manual entry |
| AI-EXP-002 | **Category suggestion** | Vendor, description | Suggested category | Faster classification |
| AI-EXP-003 | **Duplicate detection** | New expense, history | Potential duplicates | Prevent double entry |

---

## Package 5: Resource Allocation

### Purpose

Plan and track assignment of people to projects. Manage capacity, availability, and utilization.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How do you track resource assignments? (hours/day, percentage, dedicated)
- Do you forecast vs track actual allocation?
- What skills/roles do you track for matching?
- How do you handle contractor vs employee allocation?

**Workflow Discovery**:
- Who requests resources?
- Who approves allocations?
- How do you handle conflicts (over-allocation)?
- How far ahead do you plan?

**Edge Case Probing**:
- Resource assigned to overlapping projects?
- Resource leaves mid-project?
- Skills needed that no one has?

### Entity Templates

#### ResourceAllocation

```json
{
  "id": "data.resource_allocation.allocation",
  "name": "Resource Allocation",
  "type": "data",
  "namespace": "resource_allocation",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Assignment of a person to a project for a time period.",
    "fields": [
      { "name": "project_id", "type": "uuid", "required": true, "description": "Project being staffed" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "Person being allocated" },
      { "name": "role", "type": "string", "required": false, "description": "Role on this project" },
      { "name": "start_date", "type": "date", "required": true, "description": "Allocation start date" },
      { "name": "end_date", "type": "date", "required": true, "description": "Allocation end date" },
      { "name": "hours_per_day", "type": "decimal", "required": false, "description": "Daily hours allocated" },
      { "name": "percentage", "type": "decimal", "required": false, "description": "Percentage of capacity (alternative to hours)" },
      { "name": "total_hours", "type": "decimal", "required": false, "description": "Computed total hours for period" },
      { "name": "status", "type": "enum", "required": true, "values": ["tentative", "confirmed", "completed", "canceled"], "description": "Allocation status" },
      { "name": "billing_rate", "type": "decimal", "required": false, "description": "Billing rate for this allocation" },
      { "name": "cost_rate", "type": "decimal", "required": false, "description": "Cost rate for this allocation" },
      { "name": "notes", "type": "text", "required": false, "description": "Allocation notes" }
    ],
    "relationships": [
      { "entity": "Project", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "project_job.resource_allocation",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ResourceCapacity

```json
{
  "id": "data.resource_allocation.capacity",
  "name": "Resource Capacity",
  "type": "data",
  "namespace": "resource_allocation",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Available work capacity for a person by period.",
    "fields": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Person" },
      { "name": "period_start", "type": "date", "required": true, "description": "Start of capacity period" },
      { "name": "period_end", "type": "date", "required": true, "description": "End of capacity period" },
      { "name": "total_hours", "type": "decimal", "required": true, "description": "Total available hours" },
      { "name": "allocated_hours", "type": "decimal", "required": false, "description": "Hours already allocated" },
      { "name": "available_hours", "type": "decimal", "required": false, "description": "Remaining available hours" },
      { "name": "utilization_target", "type": "decimal", "required": false, "description": "Target utilization percentage" },
      { "name": "time_off_hours", "type": "decimal", "required": false, "description": "PTO/holiday hours in period" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "project_job.resource_allocation",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.resource_allocation.request_and_allocate

```yaml
workflow:
  id: "wf.resource_allocation.request_and_allocate"
  name: "Request and Allocate Resources"
  trigger: "New project or resource need identified"
  actors: ["Project Manager", "Resource Manager", "System"]

  steps:
    - step: 1
      name: "Submit Resource Request"
      actor: "Project Manager"
      action: "Define roles, skills, and time needed"
      inputs: ["Project", "Role requirements", "Date range"]
      outputs: ["Resource request"]

    - step: 2
      name: "Find Available Resources"
      actor: "System"
      action: "Query available people matching requirements"
      inputs: ["Resource request", "Capacity data", "Skills"]
      outputs: ["Available candidates"]
      automatable: true

    - step: 3
      name: "Propose Allocation"
      actor: "Resource Manager"
      action: "Select and propose team members"
      inputs: ["Available candidates", "Project priorities"]
      outputs: ["Proposed allocations"]
      decision_point: "Best fit vs availability tradeoffs?"

    - step: 4
      name: "Confirm Allocation"
      actor: "Project Manager"
      action: "Accept or negotiate proposed team"
      inputs: ["Proposed allocations"]
      outputs: ["Confirmed allocations"]

    - step: 5
      name: "Update Capacity"
      actor: "System"
      action: "Reduce available hours for allocated users"
      inputs: ["Confirmed allocations"]
      outputs: ["Updated capacity records"]
      automatable: true

    - step: 6
      name: "Notify Resources"
      actor: "System"
      action: "Send assignment notifications"
      inputs: ["Confirmed allocations"]
      outputs: ["Assignment notifications"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-RES-001 | **Resource over-allocated (>100%)** | High | Warn on allocation; allow with approval for surge capacity |
| EC-RES-002 | **No resources available with required skills** | High | Flag to resource manager; suggest training or contractor |
| EC-RES-003 | **Resource leaves organization** | High | End allocations; reassign work; notify PMs |
| EC-RES-004 | **Project delayed, allocation needs shift** | Medium | Update dates; recalculate capacity impact |
| EC-RES-005 | **Tentative vs confirmed conflicting** | Medium | Confirmed takes priority; resolve tentatives |
| EC-RES-006 | **Actual time differs from allocation** | Low | Track variance for planning improvement |
| EC-RES-007 | **Part-time resource availability changes** | Medium | Update capacity; revalidate allocations |
| EC-RES-008 | **Skills required for future not current team** | Medium | Identify training needs; plan hiring |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RES-001 | **Resource matching** | Project needs, skills, availability | Ranked candidates | Optimal staffing |
| AI-RES-002 | **Utilization forecasting** | Allocations, pipeline | Future utilization prediction | Capacity planning |
| AI-RES-003 | **Conflict detection** | Allocation changes | Over-allocation alerts | Prevent burnout |
| AI-RES-004 | **Skill gap analysis** | Demand forecast, current skills | Training recommendations | Build capabilities |

---

## Project Financial Formulas

### Earned Value Management (EVM)

| Metric | Formula | Description |
|--------|---------|-------------|
| **BAC** | Budget at Completion | Total budgeted cost for project |
| **AC** | Actual Cost | Sum of actual costs to date (time cost + expenses) |
| **EV** | BAC x % Complete | Earned value (budgeted cost of work performed) |
| **PV** | Planned Value | Budgeted cost of work scheduled to date |
| **CPI** | EV / AC | Cost Performance Index (>1 = under budget) |
| **SPI** | EV / PV | Schedule Performance Index (>1 = ahead of schedule) |
| **EAC** | BAC / CPI | Estimate at Completion (projected final cost) |
| **ETC** | EAC - AC | Estimate to Complete (remaining cost) |
| **VAC** | BAC - EAC | Variance at Completion (projected budget variance) |

### Burn Rate Calculations

```
Daily Burn Rate = AC / Working Days Elapsed
Weekly Burn Rate = AC / Weeks Elapsed
Runway (days) = (BAC - AC) / Daily Burn Rate
```

### Profitability Calculations

```
Revenue = Sum(TimeEntry.billing_amount) + Sum(Expense.billing_amount)
Cost = Sum(TimeEntry.cost_amount) + Sum(Expense.amount)
Gross Margin = Revenue - Cost
Margin % = Gross Margin / Revenue * 100
```

---

## Cross-Package Relationships

```
                    ┌─────────────────────────────────────────────┐
                    │                 PROJECTS                     │
                    │  (Container for all project work)            │
                    └─────────────────┬───────────────────────────┘
                                      │
          ┌───────────────────────────┼───────────────────────────┐
          │                           │                           │
          ▼                           ▼                           ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│     TASKS       │        │  TIME TRACKING  │        │    EXPENSES     │
│ (Work breakdown)│        │ (Hours worked)  │        │ (Costs incurred)│
└────────┬────────┘        └────────┬────────┘        └────────┬────────┘
         │                          │                          │
         └──────────────────────────┼──────────────────────────┘
                                    │
                                    ▼
                         ┌─────────────────────┐
                         │ RESOURCE ALLOCATION │
                         │ (Who works on what) │
                         └─────────────────────┘
```

### Key Integration Points

| From | To | Integration |
|------|-----|-------------|
| Projects | Tasks | Project contains tasks and subtasks |
| Projects | TimeTracking | Time logged against project and tasks |
| Projects | Expenses | Expenses charged to project budget |
| Projects | ResourceAllocation | People assigned to project |
| Tasks | TimeTracking | Time optionally linked to specific task |
| Tasks | Expenses | Expenses optionally linked to task |
| ResourceAllocation | TimeTracking | Compare planned vs actual hours |
| TimeTracking | Financial.Invoicing | Approved time becomes invoice lines |
| Expenses | Financial.Invoicing | Billable expenses become invoice lines |

---

## Integration Points (External Systems)

### HR Systems

| System | Use Case | Notes |
|--------|----------|-------|
| **Workday** | Employee data, availability | Full-featured HRIS |
| **BambooHR** | Small-medium HR | Good API |
| **ADP** | Payroll integration | Time flows to payroll |
| **Gusto** | Payroll for SMB | Time integration |

### CRM Systems

| System | Use Case | Notes |
|--------|----------|-------|
| **Salesforce** | Opportunity to project | Won deals become projects |
| **HubSpot** | Deal to project | Similar workflow |

### Accounting Systems

| System | Use Case | Notes |
|--------|----------|-------|
| **QuickBooks** | Invoice sync | Time flows to invoices |
| **Xero** | Invoice sync | International support |
| **NetSuite** | Full GL integration | Enterprise |

### Project/PM Tools

| System | Use Case | Notes |
|--------|----------|-------|
| **Asana** | Task management reference | Hierarchy model |
| **Jira** | Issue tracking | Dev-focused |
| **Monday.com** | Work management | Visual boards |

### Time Tracking Tools

| System | Use Case | Notes |
|--------|----------|-------|
| **Harvest** | Time + invoicing reference | Best-in-class UX |
| **Toggl** | Timer-based tracking | Simple entry |
| **Clockify** | Free tier option | Basic features |

### Calendar Systems

| System | Use Case | Notes |
|--------|----------|-------|
| **Google Calendar** | Availability, scheduling | Common integration |
| **Outlook/Exchange** | Enterprise calendar | Microsoft ecosystem |

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Projects | Project, Milestone | ProjectTemplate |
| Tasks | Task | (uses Project, Milestone) |
| Time Tracking | TimeEntry, Timesheet | UserRate |
| Expenses | ProjectExpense | (Receipt via Documents) |
| Resource Allocation | ResourceAllocation | ResourceCapacity |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.projects.initiate_project | Initiate New Project | Won opportunity or request |
| wf.projects.close_project | Close Project | Project work completed |
| wf.tasks.manage_task_lifecycle | Task Lifecycle | Task status changes |
| wf.time_tracking.submit_timesheet | Submit Timesheet | End of time period |
| wf.time_tracking.bill_time | Bill Approved Time | Billing cycle |
| wf.expenses.submit_project_expense | Submit Project Expense | Expense incurred |
| wf.resource_allocation.request_and_allocate | Request Resources | New project or need |

### Billing Model Summary

| Model | How It Works | When to Use |
|-------|--------------|-------------|
| **Time & Materials** | Bill actual hours * rate | Variable scope, ongoing work |
| **Fixed Price** | Bill total price regardless of hours | Well-defined deliverables |
| **Milestone** | Bill at checkpoint completion | Phased delivery |
| **Retainer** | Bill fixed monthly amount | Ongoing availability |
| **Non-Billable** | Internal cost only | Internal projects |

### Common Edge Case Themes

1. **Rate changes** - Snapshot at entry time to preserve accuracy
2. **Budget overruns** - Alert and approval workflows
3. **Status transitions** - Prevent invalid states (time on closed projects)
4. **Resource conflicts** - Over-allocation detection and resolution
5. **Cross-project allocation** - Expenses and time spanning multiple projects
6. **Historical corrections** - Audit trail for post-approval changes
7. **Termination handling** - Resources leaving, projects canceled

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
