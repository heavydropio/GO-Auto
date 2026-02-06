# Reporting Module Catalog

**Module**: Reporting
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Reporting module covers all data visualization and analytics within an application: creating reports, building dashboards, defining metrics, and enabling self-service data exploration. This module is foundational for any business application that needs to transform raw data into actionable insights.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "report", "analytics", "metrics" | Analyst, Manager, Executive | Generate insights from business data |
| "dashboard", "KPI", "visualization" | Manager, Executive, Operations | Monitor key performance indicators |
| "scheduled report", "email report" | All users, Automation | Deliver recurring reports automatically |
| "ad-hoc query", "self-service", "explore data" | Analyst, Power user | Enable users to answer their own questions |
| "drill-down", "slice and dice", "pivot" | Analyst, Manager | Analyze data from multiple dimensions |

### Module Dependencies

```
Reporting Module
├── REQUIRES: Administrative (for user preferences, permissions)
├── REQUIRES: Documents (for PDF export, file storage)
├── INTEGRATES_WITH: Financial (revenue reports, AR aging)
├── INTEGRATES_WITH: CRM (pipeline reports, customer analytics)
├── INTEGRATES_WITH: Operations (performance metrics, utilization)
```

---

## Core Architecture

### Data Flow

```
DataSource → Query → Report → Widget → Dashboard
     │          │        │        │          │
     │          │        │        │          └── Collection of widgets
     │          │        │        └── Visual component (chart, table, KPI)
     │          │        └── Reusable data query with formatting
     │          └── SQL or semantic query definition
     └── Database, API, or file connection
```

### Semantic Layer Concept

The semantic layer provides a business-friendly abstraction over raw database tables:

| Layer | Purpose | Example |
|-------|---------|---------|
| Raw Tables | Database schema | `orders`, `order_items`, `customers` |
| Semantic Model | Business objects | "Sales", "Customer", "Product" |
| Metrics | Calculated measures | "Total Revenue", "Average Order Value" |
| Dimensions | Grouping attributes | "Region", "Product Category", "Time Period" |

**Why use a semantic layer?**
- Users query business concepts, not database tables
- Centralized metric definitions ensure consistency
- Curated joins prevent incorrect data combinations
- Security rules applied at semantic level

### Caching Strategy

```
Query Request
     │
     ├── Query Cache (seconds to minutes)
     │   └── Exact query match, same parameters
     │
     ├── Materialized Views (minutes to hours)
     │   └── Pre-computed aggregations
     │
     └── Pre-aggregation Tables (hours to days)
         └── Summary tables for common patterns
```

---

## Packages

This module contains 4 packages:

1. **reports** - Creating and managing report definitions
2. **dashboards** - Building interactive dashboards
3. **metrics** - Defining and computing business metrics
4. **delivery** - Scheduling and distributing reports

---

## Package 1: Reports

### Purpose

Define, generate, and render reports that transform raw data into formatted output. Supports tables, charts, and mixed layouts with filtering and parameterization.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of reports do users need? (tabular, charts, mixed layouts)
- What data sources power your reports? (database, APIs, files)
- Do reports need parameters? (date ranges, filters, user selection)
- What output formats are required? (screen, PDF, Excel, CSV)
- Do you have calculated fields or custom formulas?

**Workflow Discovery**:
- Who creates reports? (IT only, analysts, end users)
- Do reports require approval before publishing?
- How are report versions managed?
- Can users modify shared reports or only create copies?
- What happens when underlying data schema changes?

**Edge Case Probing**:
- Reports with millions of rows?
- Reports that take too long to run?
- Users need different views of same report?
- Report results differ between runs?

### Entity Templates

#### Report

```json
{
  "id": "data.reports.report",
  "name": "Report",
  "type": "data",
  "namespace": "reports",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A saved report definition that can be executed to produce formatted results.",
    "fields": [
      { "name": "report_id", "type": "uuid", "required": true, "description": "Unique report identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Report display name" },
      { "name": "description", "type": "text", "required": false, "description": "Report purpose and usage notes" },
      { "name": "folder_id", "type": "uuid", "required": false, "description": "Parent folder for organization" },
      { "name": "data_source_id", "type": "uuid", "required": true, "description": "Primary data source connection" },
      { "name": "query_definition", "type": "json", "required": true, "description": "Query specification (SQL or semantic)" },
      { "name": "layout_type", "type": "enum", "required": true, "values": ["tabular", "chart", "mixed", "pivot"], "description": "Report layout format" },
      { "name": "columns", "type": "json", "required": true, "description": "Column definitions with formatting" },
      { "name": "filters", "type": "json", "required": false, "description": "Available filter definitions" },
      { "name": "parameters", "type": "json", "required": false, "description": "User-input parameters" },
      { "name": "default_sort", "type": "json", "required": false, "description": "Default sort order" },
      { "name": "row_limit", "type": "integer", "required": false, "description": "Maximum rows returned" },
      { "name": "cache_ttl_seconds", "type": "integer", "required": false, "description": "Query cache duration" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "published", "archived", "deprecated"], "description": "Report lifecycle status" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "Report author" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last modification timestamp" },
      { "name": "version", "type": "integer", "required": true, "description": "Report definition version" }
    ],
    "relationships": [
      { "entity": "DataSource", "type": "many_to_one", "required": true },
      { "entity": "Folder", "type": "many_to_one", "required": false },
      { "entity": "ReportPermission", "type": "one_to_many", "required": false },
      { "entity": "ScheduledReport", "type": "one_to_many", "required": false },
      { "entity": "Widget", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.reports",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DataSource

```json
{
  "id": "data.reports.data_source",
  "name": "Data Source",
  "type": "data",
  "namespace": "reports",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Connection to a data repository used by reports.",
    "fields": [
      { "name": "data_source_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Display name" },
      { "name": "type", "type": "enum", "required": true, "values": ["database", "api", "file", "warehouse", "semantic_model"], "description": "Source type" },
      { "name": "connection_string", "type": "encrypted_string", "required": false, "description": "Database connection (encrypted)" },
      { "name": "host", "type": "string", "required": false, "description": "Server hostname" },
      { "name": "port", "type": "integer", "required": false, "description": "Connection port" },
      { "name": "database_name", "type": "string", "required": false, "description": "Database/schema name" },
      { "name": "credentials_id", "type": "uuid", "required": false, "description": "Reference to stored credentials" },
      { "name": "schema_cache", "type": "json", "required": false, "description": "Cached table/column metadata" },
      { "name": "schema_cached_at", "type": "datetime", "required": false, "description": "When schema was last refreshed" },
      { "name": "max_query_time_seconds", "type": "integer", "required": false, "description": "Query timeout limit" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "inactive", "error"], "description": "Connection status" },
      { "name": "last_tested_at", "type": "datetime", "required": false, "description": "Last connection test" }
    ],
    "relationships": [
      { "entity": "Report", "type": "one_to_many", "required": false },
      { "entity": "Metric", "type": "one_to_many", "required": false }
    ],
    "notes": "NEVER store unencrypted credentials. Use credential vault or encrypted connection strings."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.reports",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ReportExecution

```json
{
  "id": "data.reports.report_execution",
  "name": "Report Execution",
  "type": "data",
  "namespace": "reports",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Log of report run with performance metrics and parameters.",
    "fields": [
      { "name": "execution_id", "type": "uuid", "required": true, "description": "Unique execution identifier" },
      { "name": "report_id", "type": "uuid", "required": true, "description": "Report that was executed" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "User who ran the report" },
      { "name": "parameters_used", "type": "json", "required": false, "description": "Parameter values for this run" },
      { "name": "filters_applied", "type": "json", "required": false, "description": "Filters applied" },
      { "name": "started_at", "type": "datetime", "required": true, "description": "Execution start time" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "Execution end time" },
      { "name": "duration_ms", "type": "integer", "required": false, "description": "Total execution time in milliseconds" },
      { "name": "row_count", "type": "integer", "required": false, "description": "Number of rows returned" },
      { "name": "status", "type": "enum", "required": true, "values": ["running", "completed", "failed", "cancelled", "timeout"], "description": "Execution status" },
      { "name": "error_message", "type": "text", "required": false, "description": "Error details if failed" },
      { "name": "cache_hit", "type": "boolean", "required": false, "description": "Whether result came from cache" },
      { "name": "output_format", "type": "enum", "required": false, "values": ["screen", "pdf", "excel", "csv", "json"], "description": "Requested output format" }
    ],
    "relationships": [
      { "entity": "Report", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.reports",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ReportPermission

```json
{
  "id": "data.reports.report_permission",
  "name": "Report Permission",
  "type": "data",
  "namespace": "reports",
  "tags": ["core-entity", "security"],
  "status": "discovered",

  "spec": {
    "purpose": "Access control for reports at object or folder level.",
    "fields": [
      { "name": "permission_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "report_id", "type": "uuid", "required": false, "description": "Specific report (if object-level)" },
      { "name": "folder_id", "type": "uuid", "required": false, "description": "Folder (if folder-level)" },
      { "name": "principal_type", "type": "enum", "required": true, "values": ["user", "role", "group"], "description": "Who the permission applies to" },
      { "name": "principal_id", "type": "uuid", "required": true, "description": "User, role, or group ID" },
      { "name": "access_level", "type": "enum", "required": true, "values": ["view", "run", "edit", "manage", "owner"], "description": "Permission level" },
      { "name": "row_filter", "type": "json", "required": false, "description": "Row-Level Security filter expression" },
      { "name": "granted_by", "type": "uuid", "required": true, "description": "Who granted the permission" },
      { "name": "granted_at", "type": "datetime", "required": true, "description": "When permission was granted" },
      { "name": "expires_at", "type": "datetime", "required": false, "description": "Permission expiration (if temporary)" }
    ],
    "relationships": [
      { "entity": "Report", "type": "many_to_one", "required": false },
      { "entity": "Folder", "type": "many_to_one", "required": false }
    ],
    "notes": "Either report_id or folder_id must be set, but not both. Row-Level Security (RLS) filters data based on user context."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.reports",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.reports.create_and_publish

```yaml
workflow:
  id: "wf.reports.create_and_publish"
  name: "Create and Publish Report"
  trigger: "User initiates report creation"
  actors: ["Report Author", "Report Reviewer", "System"]

  steps:
    - step: 1
      name: "Select Data Source"
      actor: "Report Author"
      action: "Choose data source and browse available fields"
      inputs: ["Available data sources", "User permissions"]
      outputs: ["Selected data source", "Available fields"]

    - step: 2
      name: "Build Query"
      actor: "Report Author"
      action: "Define columns, filters, grouping, and calculations"
      inputs: ["Available fields", "Semantic model"]
      outputs: ["Query definition"]
      decision_point: "Use SQL or drag-drop builder?"

    - step: 3
      name: "Configure Layout"
      actor: "Report Author"
      action: "Set column formatting, chart type, and styling"
      inputs: ["Query definition"]
      outputs: ["Layout configuration"]

    - step: 4
      name: "Test Report"
      actor: "System"
      action: "Execute report with sample data"
      inputs: ["Query definition", "Layout configuration"]
      outputs: ["Preview results", "Performance metrics"]
      automatable: true

    - step: 5
      name: "Review and Approve"
      actor: "Report Reviewer"
      action: "Validate data accuracy and approve for publishing"
      inputs: ["Preview results", "Report definition"]
      outputs: ["Approval decision"]
      condition: "Report requires approval based on data sensitivity"
      decision_point: "Approve, request changes, or reject?"

    - step: 6
      name: "Publish Report"
      actor: "System"
      action: "Change status to published, set permissions"
      inputs: ["Approved report", "Target permissions"]
      outputs: ["Published report"]
      automatable: true

    - step: 7
      name: "Notify Users"
      actor: "System"
      action: "Send notification to users with access"
      inputs: ["Published report", "User list"]
      outputs: ["Notifications sent"]
      automatable: true
```

#### wf.reports.modify_existing

```yaml
workflow:
  id: "wf.reports.modify_existing"
  name: "Modify Existing Report"
  trigger: "User edits published report"
  actors: ["Report Author", "System"]

  steps:
    - step: 1
      name: "Create Draft Version"
      actor: "System"
      action: "Create draft copy preserving published version"
      inputs: ["Published report"]
      outputs: ["Draft report version"]
      automatable: true

    - step: 2
      name: "Make Changes"
      actor: "Report Author"
      action: "Modify query, layout, or settings"
      inputs: ["Draft report"]
      outputs: ["Modified draft"]

    - step: 3
      name: "Compare Versions"
      actor: "System"
      action: "Show diff between published and draft"
      inputs: ["Published version", "Draft version"]
      outputs: ["Change summary"]
      automatable: true

    - step: 4
      name: "Test Changes"
      actor: "System"
      action: "Run both versions and compare results"
      inputs: ["Published version", "Draft version"]
      outputs: ["Comparison results"]
      automatable: true

    - step: 5
      name: "Publish Update"
      actor: "Report Author"
      action: "Promote draft to new published version"
      inputs: ["Draft version", "Approval if required"]
      outputs: ["Updated published report", "Version history"]
      decision_point: "Publish now or save as draft?"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-RPT-001 | **Report returns millions of rows** | High | Enforce row limits; require export for full data; implement pagination |
| EC-RPT-002 | **Query exceeds timeout** | Medium | Implement query timeout; suggest optimization; offer async execution |
| EC-RPT-003 | **Underlying schema changes** | High | Detect schema drift; notify report owners; provide migration tools |
| EC-RPT-004 | **User lacks access to some data columns** | Medium | Apply column-level security; hide or mask restricted fields |
| EC-RPT-005 | **Report results inconsistent between runs** | High | Check for missing ORDER BY; verify data volatility; check cache state |
| EC-RPT-006 | **Export fails for large dataset** | Medium | Stream exports in chunks; use background job for large files |
| EC-RPT-007 | **Multiple users edit same report** | Medium | Implement optimistic locking; show conflict resolution UI |
| EC-RPT-008 | **Report using deprecated data source** | Low | Warn users; provide migration path; maintain read-only access |
| EC-RPT-009 | **Filter combinations produce zero results** | Low | Show helpful message; suggest removing filters; check filter logic |
| EC-RPT-010 | **Report references deleted metric** | High | Prevent deletion of in-use metrics; show dependency warnings |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RPT-001 | **Natural language to query** | User question in plain English | SQL or semantic query | Enables non-technical users to build reports |
| AI-RPT-002 | **Query optimization** | Slow query definition | Optimized query suggestions | Improves report performance |
| AI-RPT-003 | **Anomaly highlighting** | Report results | Flagged outliers and trends | Draws attention to important data points |
| AI-RPT-004 | **Auto-summarization** | Report data | Executive summary text | Saves time interpreting results |
| AI-RPT-005 | **Column suggestion** | Partial query, user intent | Recommended additional columns | Helps users discover relevant fields |

---

## Package 2: Dashboards

### Purpose

Combine multiple reports and visualizations into interactive, real-time monitoring interfaces. Supports layout customization, cross-widget filtering, and drill-down navigation.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What KPIs do executives monitor? (revenue, conversion, utilization)
- How frequently should dashboards refresh? (real-time, hourly, daily)
- What chart types are needed? (bar, line, pie, gauge, map)
- Do users need to interact with dashboards? (filter, drill-down)
- Should dashboards support dark mode or TV display?

**Workflow Discovery**:
- Who builds dashboards? (IT, analysts, managers)
- Can users customize shared dashboards?
- How are dashboards organized? (by department, function)
- What happens when a widget fails to load?
- Do dashboards need mobile-responsive layouts?

**Edge Case Probing**:
- Dashboard with 50+ widgets?
- Widget data conflicts with another widget?
- User wants personal dashboard variations?
- Dashboard displayed on public TV screen?

### Entity Templates

#### Dashboard

```json
{
  "id": "data.dashboards.dashboard",
  "name": "Dashboard",
  "type": "data",
  "namespace": "dashboards",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A collection of widgets arranged for visual monitoring and analysis.",
    "fields": [
      { "name": "dashboard_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Dashboard display name" },
      { "name": "description", "type": "text", "required": false, "description": "Dashboard purpose and usage" },
      { "name": "folder_id", "type": "uuid", "required": false, "description": "Organizational folder" },
      { "name": "layout", "type": "json", "required": true, "description": "Widget positions and sizes" },
      { "name": "theme", "type": "enum", "required": false, "values": ["light", "dark", "auto", "custom"], "description": "Visual theme" },
      { "name": "refresh_interval_seconds", "type": "integer", "required": false, "description": "Auto-refresh frequency" },
      { "name": "global_filters", "type": "json", "required": false, "description": "Filters applied to all widgets" },
      { "name": "time_range_default", "type": "json", "required": false, "description": "Default time window" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "published", "archived"], "description": "Dashboard status" },
      { "name": "is_default", "type": "boolean", "required": false, "description": "Default dashboard for user/role" },
      { "name": "is_public", "type": "boolean", "required": false, "description": "Accessible without login" },
      { "name": "public_token", "type": "string", "required": false, "description": "Token for public access URL" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "Dashboard creator" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last modification" }
    ],
    "relationships": [
      { "entity": "Widget", "type": "one_to_many", "required": true },
      { "entity": "Folder", "type": "many_to_one", "required": false },
      { "entity": "DashboardPermission", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.dashboards",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Widget

```json
{
  "id": "data.dashboards.widget",
  "name": "Widget",
  "type": "data",
  "namespace": "dashboards",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A visual component displaying data from a report or metric.",
    "fields": [
      { "name": "widget_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "dashboard_id", "type": "uuid", "required": true, "description": "Parent dashboard" },
      { "name": "name", "type": "string", "required": true, "description": "Widget title" },
      { "name": "widget_type", "type": "enum", "required": true, "values": ["kpi", "bar_chart", "line_chart", "pie_chart", "table", "gauge", "map", "text", "image", "iframe"], "description": "Visualization type" },
      { "name": "report_id", "type": "uuid", "required": false, "description": "Source report (if report-based)" },
      { "name": "metric_id", "type": "uuid", "required": false, "description": "Source metric (if metric-based)" },
      { "name": "custom_query", "type": "json", "required": false, "description": "Inline query (if not using report)" },
      { "name": "visualization_config", "type": "json", "required": true, "description": "Chart settings, colors, axes" },
      { "name": "position", "type": "json", "required": true, "description": "Grid position (x, y, width, height)" },
      { "name": "filters", "type": "json", "required": false, "description": "Widget-specific filters" },
      { "name": "drill_down_target", "type": "uuid", "required": false, "description": "Report or dashboard for drill-down" },
      { "name": "cache_ttl_seconds", "type": "integer", "required": false, "description": "Widget-level cache override" },
      { "name": "error_display", "type": "enum", "required": false, "values": ["show_error", "hide", "show_stale"], "description": "Behavior when data fetch fails" }
    ],
    "relationships": [
      { "entity": "Dashboard", "type": "many_to_one", "required": true },
      { "entity": "Report", "type": "many_to_one", "required": false },
      { "entity": "Metric", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.dashboards",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DashboardFilter

```json
{
  "id": "data.dashboards.dashboard_filter",
  "name": "Dashboard Filter",
  "type": "data",
  "namespace": "dashboards",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Interactive filter that applies to multiple widgets on a dashboard.",
    "fields": [
      { "name": "filter_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "dashboard_id", "type": "uuid", "required": true, "description": "Parent dashboard" },
      { "name": "name", "type": "string", "required": true, "description": "Filter display label" },
      { "name": "filter_type", "type": "enum", "required": true, "values": ["dropdown", "multi_select", "date_range", "text_search", "slider"], "description": "Filter input type" },
      { "name": "field_name", "type": "string", "required": true, "description": "Field this filter applies to" },
      { "name": "default_value", "type": "json", "required": false, "description": "Initial filter value" },
      { "name": "options_source", "type": "enum", "required": false, "values": ["static", "query", "metric"], "description": "Where to get dropdown options" },
      { "name": "options_query", "type": "json", "required": false, "description": "Query for dynamic options" },
      { "name": "static_options", "type": "json", "required": false, "description": "Predefined option list" },
      { "name": "applies_to_widgets", "type": "array", "required": false, "description": "Widget IDs this filter affects (null = all)" },
      { "name": "position", "type": "integer", "required": true, "description": "Display order" }
    ],
    "relationships": [
      { "entity": "Dashboard", "type": "many_to_one", "required": true }
    ],
    "notes": "Limit to 5 filters per dashboard to avoid overwhelming users."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "reporting.dashboards",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.dashboards.build_dashboard

```yaml
workflow:
  id: "wf.dashboards.build_dashboard"
  name: "Build Interactive Dashboard"
  trigger: "User initiates dashboard creation"
  actors: ["Dashboard Builder", "System"]

  steps:
    - step: 1
      name: "Define Dashboard Purpose"
      actor: "Dashboard Builder"
      action: "Specify name, description, and target audience"
      inputs: ["Business requirements"]
      outputs: ["Dashboard metadata"]

    - step: 2
      name: "Add Widgets"
      actor: "Dashboard Builder"
      action: "Drag-drop widgets from report library or create new"
      inputs: ["Available reports", "Metric library"]
      outputs: ["Widget configurations"]
      decision_point: "Use existing report or create custom query?"

    - step: 3
      name: "Configure Layout"
      actor: "Dashboard Builder"
      action: "Arrange widgets on grid, set sizes"
      inputs: ["Widget list"]
      outputs: ["Layout configuration"]

    - step: 4
      name: "Add Filters"
      actor: "Dashboard Builder"
      action: "Create global filters and link to widgets"
      inputs: ["Widget fields"]
      outputs: ["Filter configurations"]
      decision_point: "Which filters? Max 5 recommended."

    - step: 5
      name: "Configure Drill-Down"
      actor: "Dashboard Builder"
      action: "Link widgets to detail reports"
      inputs: ["Widget list", "Available reports"]
      outputs: ["Drill-down mappings"]

    - step: 6
      name: "Test Interactivity"
      actor: "System"
      action: "Validate filters, drill-downs, and refresh"
      inputs: ["Dashboard definition"]
      outputs: ["Test results"]
      automatable: true

    - step: 7
      name: "Set Permissions"
      actor: "Dashboard Builder"
      action: "Define who can view and edit"
      inputs: ["User/role list"]
      outputs: ["Permission assignments"]

    - step: 8
      name: "Publish Dashboard"
      actor: "System"
      action: "Make dashboard available to users"
      inputs: ["Complete dashboard"]
      outputs: ["Published dashboard"]
      automatable: true
```

#### wf.dashboards.public_display

```yaml
workflow:
  id: "wf.dashboards.public_display"
  name: "Configure Public Display"
  trigger: "Dashboard needs to be shown on TV or public screen"
  actors: ["Administrator", "System"]

  steps:
    - step: 1
      name: "Generate Public Token"
      actor: "System"
      action: "Create unique access token for dashboard"
      inputs: ["Dashboard ID"]
      outputs: ["Public URL with token"]
      automatable: true

    - step: 2
      name: "Configure Display Settings"
      actor: "Administrator"
      action: "Set auto-refresh, theme for TV display, hide controls"
      inputs: ["Dashboard settings"]
      outputs: ["Display configuration"]

    - step: 3
      name: "Review Data Sensitivity"
      actor: "Administrator"
      action: "Verify no sensitive data exposed without auth"
      inputs: ["Dashboard content"]
      outputs: ["Security approval"]
      decision_point: "Any sensitive data visible?"

    - step: 4
      name: "Enable Public Access"
      actor: "System"
      action: "Activate public URL"
      inputs: ["Security approval", "Display configuration"]
      outputs: ["Active public dashboard"]
      automatable: true

    - step: 5
      name: "Monitor Access"
      actor: "System"
      action: "Log anonymous views, detect abuse"
      inputs: ["Access logs"]
      outputs: ["Access metrics"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-RPT-011 | **Dashboard has 50+ widgets** | High | Warn about performance; suggest splitting; implement lazy loading |
| EC-RPT-012 | **Widget fails to load** | Medium | Show error state; option to hide; don't block other widgets |
| EC-RPT-013 | **Filter produces no matching widgets** | Low | Show informative message; suggest broadening filter |
| EC-RPT-014 | **Public dashboard exposed sensitive data** | Critical | Audit public dashboards; require explicit approval; mask data |
| EC-RPT-015 | **Dashboard refresh overwhelms database** | High | Implement request throttling; stagger widget refreshes |
| EC-RPT-016 | **Mobile layout breaks** | Medium | Provide responsive grid; allow mobile-specific layout |
| EC-RPT-017 | **User wants personal version of shared dashboard** | Low | Implement "save as copy"; support personal modifications |
| EC-RPT-018 | **Two widgets show conflicting numbers** | High | Trace data sources; document calculation differences; add tooltips |
| EC-RPT-019 | **Dashboard URL token leaked** | High | Regenerate token; audit access logs; consider token expiration |
| EC-RPT-020 | **Drill-down target report deleted** | Medium | Show warning; suggest alternative; prevent deletion of in-use reports |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RPT-006 | **Dashboard layout suggestion** | Widget list, screen size | Optimal arrangement | Creates balanced, readable layouts |
| AI-RPT-007 | **Alert threshold recommendation** | Historical metric data | Suggested alert thresholds | Reduces false alarms |
| AI-RPT-008 | **Widget type suggestion** | Data characteristics | Best visualization type | Picks appropriate charts for data |
| AI-RPT-009 | **Usage-based widget prioritization** | User interaction data | Widget importance scores | Places frequently used widgets prominently |

---

## Package 3: Metrics

### Purpose

Define, compute, and manage reusable business metrics that ensure consistent calculations across all reports and dashboards.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What are your key business metrics? (revenue, churn, NPS)
- How are metrics calculated? (sum, average, ratio, custom formula)
- Do metrics have targets or benchmarks?
- Are there different metric versions by time period?
- Do metrics aggregate differently at different levels?

**Workflow Discovery**:
- Who defines official metrics? (finance, data team)
- How are metric definitions approved?
- What happens when a metric definition changes?
- How do you handle metric versioning?
- Can users create personal metrics?

**Edge Case Probing**:
- Metric depends on another metric?
- Metric calculation changes historically?
- Same metric means different things to different teams?
- Metric involves data from multiple sources?

### Entity Templates

#### Metric

```json
{
  "id": "data.metrics.metric",
  "name": "Metric",
  "type": "data",
  "namespace": "metrics",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A defined business measure with consistent calculation logic.",
    "fields": [
      { "name": "metric_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Metric display name" },
      { "name": "code", "type": "string", "required": true, "description": "Unique short code (e.g., 'mrr', 'cac')" },
      { "name": "description", "type": "text", "required": true, "description": "Business definition and usage" },
      { "name": "category", "type": "string", "required": false, "description": "Grouping category (financial, operational)" },
      { "name": "data_source_id", "type": "uuid", "required": true, "description": "Primary data source" },
      { "name": "calculation_type", "type": "enum", "required": true, "values": ["sum", "count", "average", "min", "max", "ratio", "formula", "distinct_count"], "description": "Aggregation method" },
      { "name": "formula", "type": "text", "required": false, "description": "Custom calculation formula" },
      { "name": "base_field", "type": "string", "required": false, "description": "Field to aggregate" },
      { "name": "filters", "type": "json", "required": false, "description": "Default filters applied" },
      { "name": "unit", "type": "string", "required": false, "description": "Display unit (currency, percent, count)" },
      { "name": "format", "type": "string", "required": false, "description": "Number format pattern" },
      { "name": "target_value", "type": "decimal", "required": false, "description": "Goal or benchmark" },
      { "name": "target_direction", "type": "enum", "required": false, "values": ["higher_is_better", "lower_is_better", "target_exact"], "description": "How to interpret vs target" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "approved", "deprecated"], "description": "Metric lifecycle status" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Metric owner (for changes)" },
      { "name": "version", "type": "integer", "required": true, "description": "Definition version" },
      { "name": "effective_date", "type": "date", "required": false, "description": "When this definition takes effect" }
    ],
    "relationships": [
      { "entity": "DataSource", "type": "many_to_one", "required": true },
      { "entity": "MetricDimension", "type": "one_to_many", "required": false },
      { "entity": "Widget", "type": "one_to_many", "required": false },
      { "entity": "MetricHistory", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.metrics",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### MetricDimension

```json
{
  "id": "data.metrics.metric_dimension",
  "name": "Metric Dimension",
  "type": "data",
  "namespace": "metrics",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Defines how a metric can be sliced or grouped.",
    "fields": [
      { "name": "dimension_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "metric_id", "type": "uuid", "required": true, "description": "Parent metric" },
      { "name": "name", "type": "string", "required": true, "description": "Dimension display name" },
      { "name": "field_name", "type": "string", "required": true, "description": "Source field for grouping" },
      { "name": "dimension_type", "type": "enum", "required": true, "values": ["categorical", "temporal", "hierarchical", "geographic"], "description": "Dimension category" },
      { "name": "hierarchy_levels", "type": "json", "required": false, "description": "Drill-down levels for hierarchical dimensions" },
      { "name": "default_granularity", "type": "string", "required": false, "description": "Default level (day, week, month for temporal)" },
      { "name": "is_default", "type": "boolean", "required": false, "description": "Show by default in reports" }
    ],
    "relationships": [
      { "entity": "Metric", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "reporting.metrics",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### MetricSnapshot

```json
{
  "id": "data.metrics.metric_snapshot",
  "name": "Metric Snapshot",
  "type": "data",
  "namespace": "metrics",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Point-in-time capture of metric value for historical tracking.",
    "fields": [
      { "name": "snapshot_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "metric_id", "type": "uuid", "required": true, "description": "Metric captured" },
      { "name": "snapshot_date", "type": "date", "required": true, "description": "Date of snapshot" },
      { "name": "period_type", "type": "enum", "required": true, "values": ["daily", "weekly", "monthly", "quarterly", "yearly"], "description": "Time period type" },
      { "name": "period_start", "type": "date", "required": true, "description": "Period start date" },
      { "name": "period_end", "type": "date", "required": true, "description": "Period end date" },
      { "name": "value", "type": "decimal", "required": true, "description": "Metric value" },
      { "name": "dimension_values", "type": "json", "required": false, "description": "Dimension breakdown if captured" },
      { "name": "target_value", "type": "decimal", "required": false, "description": "Target at time of snapshot" },
      { "name": "variance_from_target", "type": "decimal", "required": false, "description": "Difference from target" },
      { "name": "prior_period_value", "type": "decimal", "required": false, "description": "Previous period for comparison" },
      { "name": "period_over_period_change", "type": "decimal", "required": false, "description": "Change from prior period" }
    ],
    "relationships": [
      { "entity": "Metric", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.metrics",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.metrics.define_metric

```yaml
workflow:
  id: "wf.metrics.define_metric"
  name: "Define Business Metric"
  trigger: "Business needs new standardized metric"
  actors: ["Metric Owner", "Data Steward", "System"]

  steps:
    - step: 1
      name: "Draft Definition"
      actor: "Metric Owner"
      action: "Document business meaning, calculation, and data source"
      inputs: ["Business requirements"]
      outputs: ["Draft metric definition"]

    - step: 2
      name: "Technical Review"
      actor: "Data Steward"
      action: "Validate data availability and calculation feasibility"
      inputs: ["Draft definition", "Data catalog"]
      outputs: ["Technical assessment"]
      decision_point: "Data available? Calculation correct?"

    - step: 3
      name: "Build Calculation"
      actor: "Data Steward"
      action: "Implement calculation in semantic layer"
      inputs: ["Approved definition"]
      outputs: ["Metric implementation"]

    - step: 4
      name: "Validate Results"
      actor: "Metric Owner"
      action: "Compare metric output to expected values"
      inputs: ["Test results", "Known benchmarks"]
      outputs: ["Validation status"]
      decision_point: "Results match expectations?"

    - step: 5
      name: "Define Dimensions"
      actor: "Data Steward"
      action: "Specify how metric can be sliced"
      inputs: ["Metric definition"]
      outputs: ["Dimension configurations"]

    - step: 6
      name: "Set Target"
      actor: "Metric Owner"
      action: "Define target value and direction"
      inputs: ["Business goals"]
      outputs: ["Target configuration"]

    - step: 7
      name: "Approve and Publish"
      actor: "Data Steward"
      action: "Mark metric as official, add to catalog"
      inputs: ["Complete metric"]
      outputs: ["Published metric"]
```

#### wf.metrics.update_definition

```yaml
workflow:
  id: "wf.metrics.update_definition"
  name: "Update Metric Definition"
  trigger: "Metric calculation needs to change"
  actors: ["Metric Owner", "Data Steward", "Affected Users", "System"]

  steps:
    - step: 1
      name: "Assess Impact"
      actor: "System"
      action: "Find all reports and dashboards using this metric"
      inputs: ["Metric ID"]
      outputs: ["Impact report"]
      automatable: true

    - step: 2
      name: "Notify Stakeholders"
      actor: "System"
      action: "Alert affected report owners"
      inputs: ["Impact report"]
      outputs: ["Notifications sent"]
      automatable: true

    - step: 3
      name: "Create New Version"
      actor: "Data Steward"
      action: "Define updated calculation, preserve old version"
      inputs: ["Change request"]
      outputs: ["Draft new version"]

    - step: 4
      name: "Compare Versions"
      actor: "System"
      action: "Run both calculations, show differences"
      inputs: ["Old version", "New version"]
      outputs: ["Comparison report"]
      automatable: true

    - step: 5
      name: "Review Changes"
      actor: "Metric Owner"
      action: "Approve calculation changes"
      inputs: ["Comparison report"]
      outputs: ["Approval decision"]
      decision_point: "Changes acceptable? Effective date?"

    - step: 6
      name: "Publish New Version"
      actor: "System"
      action: "Activate new version, deprecate old"
      inputs: ["Approval", "Effective date"]
      outputs: ["Updated metric"]
      automatable: true

    - step: 7
      name: "Document Change"
      actor: "Data Steward"
      action: "Record reason for change in metric history"
      inputs: ["Change details"]
      outputs: ["Change log entry"]
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-RPT-021 | **Metric depends on deprecated metric** | High | Show dependency chain; prevent deprecation until resolved |
| EC-RPT-022 | **Historical metric recalculation needed** | High | Support backfill with new definition; preserve original snapshots |
| EC-RPT-023 | **Same metric name used differently by teams** | High | Enforce unique codes; allow aliases; document in glossary |
| EC-RPT-024 | **Metric formula has division by zero** | Medium | Handle nulls gracefully; show N/A instead of error |
| EC-RPT-025 | **Metric aggregates incorrectly across dimensions** | High | Define aggregation rules per dimension; prevent double-counting |
| EC-RPT-026 | **Target changes mid-period** | Low | Track target history; compare to target at snapshot time |
| EC-RPT-027 | **Metric requires data from multiple sources** | Medium | Use semantic layer joins; document data latency differences |
| EC-RPT-028 | **Circular metric dependencies** | Critical | Detect cycles at save time; reject circular definitions |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RPT-010 | **Metric definition suggestion** | Business question | Draft metric definition | Accelerates metric creation |
| AI-RPT-011 | **Target recommendation** | Historical metric values | Suggested targets | Sets realistic goals based on trends |
| AI-RPT-012 | **Anomaly detection** | Metric time series | Flagged anomalies with explanations | Catches data quality issues early |
| AI-RPT-013 | **Metric correlation analysis** | Multiple metrics | Related metrics and potential drivers | Helps understand metric relationships |

---

## Package 4: Delivery

### Purpose

Schedule automated report generation and distribution via email, file drops, and integrations. Manage subscriptions and track delivery status.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What reports are sent on a schedule? (daily sales, weekly status)
- What delivery methods are needed? (email, SFTP, Slack, portal)
- Do different users receive different report parameters?
- What file formats are required? (PDF, Excel, CSV)
- Should reports include conditional logic? (only send if data exists)

**Workflow Discovery**:
- Who manages report schedules? (IT, report owners, end users)
- Can users subscribe themselves to reports?
- What happens when scheduled report fails?
- How are delivery failures retried?
- Do users need delivery confirmations?

**Edge Case Probing**:
- Report has no data for this period?
- Recipient email address invalid?
- Report takes longer than schedule interval?
- Time zone differences for global recipients?

### Entity Templates

#### ScheduledReport

```json
{
  "id": "data.delivery.scheduled_report",
  "name": "Scheduled Report",
  "type": "data",
  "namespace": "delivery",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Configuration for automated report generation and delivery.",
    "fields": [
      { "name": "schedule_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Schedule display name" },
      { "name": "report_id", "type": "uuid", "required": true, "description": "Report to execute" },
      { "name": "parameters", "type": "json", "required": false, "description": "Fixed parameter values" },
      { "name": "cron_expression", "type": "string", "required": true, "description": "Schedule timing (cron format)" },
      { "name": "timezone", "type": "string", "required": true, "description": "Timezone for schedule (e.g., America/New_York)" },
      { "name": "output_format", "type": "enum", "required": true, "values": ["pdf", "excel", "csv", "html", "json"], "description": "File format" },
      { "name": "delivery_method", "type": "enum", "required": true, "values": ["email", "sftp", "s3", "slack", "webhook", "portal"], "description": "How to deliver" },
      { "name": "delivery_config", "type": "json", "required": true, "description": "Method-specific settings" },
      { "name": "conditional_send", "type": "json", "required": false, "description": "Conditions for sending (e.g., only if rows > 0)" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "paused", "disabled"], "description": "Schedule status" },
      { "name": "next_run_at", "type": "datetime", "required": false, "description": "Next scheduled execution" },
      { "name": "last_run_at", "type": "datetime", "required": false, "description": "Last execution time" },
      { "name": "last_run_status", "type": "enum", "required": false, "values": ["success", "failed", "skipped"], "description": "Last run outcome" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "Schedule creator" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "Creation timestamp" }
    ],
    "relationships": [
      { "entity": "Report", "type": "many_to_one", "required": true },
      { "entity": "Subscription", "type": "one_to_many", "required": false },
      { "entity": "DeliveryLog", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Subscription

```json
{
  "id": "data.delivery.subscription",
  "name": "Subscription",
  "type": "data",
  "namespace": "delivery",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Links a user to a scheduled report with personalization options.",
    "fields": [
      { "name": "subscription_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "schedule_id", "type": "uuid", "required": true, "description": "Parent scheduled report" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "Subscribed user" },
      { "name": "personalized_parameters", "type": "json", "required": false, "description": "User-specific parameter overrides" },
      { "name": "delivery_email", "type": "email", "required": false, "description": "Override delivery email" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "paused", "unsubscribed"], "description": "Subscription status" },
      { "name": "subscribed_at", "type": "datetime", "required": true, "description": "When subscribed" },
      { "name": "unsubscribed_at", "type": "datetime", "required": false, "description": "When unsubscribed" }
    ],
    "relationships": [
      { "entity": "ScheduledReport", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "reporting.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### DeliveryLog

```json
{
  "id": "data.delivery.delivery_log",
  "name": "Delivery Log",
  "type": "data",
  "namespace": "delivery",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of each report delivery attempt and outcome.",
    "fields": [
      { "name": "log_id", "type": "uuid", "required": true, "description": "Unique identifier" },
      { "name": "schedule_id", "type": "uuid", "required": true, "description": "Source schedule" },
      { "name": "execution_id", "type": "uuid", "required": false, "description": "Report execution that generated content" },
      { "name": "triggered_at", "type": "datetime", "required": true, "description": "When delivery was triggered" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When delivery completed" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "generating", "delivering", "success", "failed", "skipped"], "description": "Delivery status" },
      { "name": "skip_reason", "type": "string", "required": false, "description": "Why delivery was skipped" },
      { "name": "recipient_count", "type": "integer", "required": false, "description": "Number of recipients" },
      { "name": "file_size_bytes", "type": "integer", "required": false, "description": "Generated file size" },
      { "name": "delivery_details", "type": "json", "required": false, "description": "Per-recipient delivery status" },
      { "name": "error_message", "type": "text", "required": false, "description": "Error details if failed" },
      { "name": "retry_count", "type": "integer", "required": false, "description": "Number of retry attempts" },
      { "name": "retry_scheduled_at", "type": "datetime", "required": false, "description": "Next retry time" }
    ],
    "relationships": [
      { "entity": "ScheduledReport", "type": "many_to_one", "required": true },
      { "entity": "ReportExecution", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "reporting.delivery",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.delivery.schedule_report

```yaml
workflow:
  id: "wf.delivery.schedule_report"
  name: "Schedule Report Delivery"
  trigger: "User configures automated report distribution"
  actors: ["Report Owner", "System"]

  steps:
    - step: 1
      name: "Select Report"
      actor: "Report Owner"
      action: "Choose report to schedule"
      inputs: ["Available reports"]
      outputs: ["Selected report"]

    - step: 2
      name: "Configure Parameters"
      actor: "Report Owner"
      action: "Set fixed or dynamic parameter values"
      inputs: ["Report parameters"]
      outputs: ["Parameter configuration"]
      decision_point: "Fixed values or relative dates?"

    - step: 3
      name: "Define Schedule"
      actor: "Report Owner"
      action: "Set frequency, time, and timezone"
      inputs: ["Scheduling options"]
      outputs: ["Cron expression", "Timezone"]

    - step: 4
      name: "Configure Delivery"
      actor: "Report Owner"
      action: "Select method and recipients"
      inputs: ["Delivery options", "User list"]
      outputs: ["Delivery configuration"]
      decision_point: "Email, SFTP, or integration?"

    - step: 5
      name: "Set Conditions"
      actor: "Report Owner"
      action: "Define when to skip delivery"
      inputs: ["Conditional options"]
      outputs: ["Conditional rules"]

    - step: 6
      name: "Test Delivery"
      actor: "System"
      action: "Execute report and send to owner"
      inputs: ["Schedule configuration"]
      outputs: ["Test delivery"]
      automatable: true

    - step: 7
      name: "Activate Schedule"
      actor: "System"
      action: "Enable scheduled execution"
      inputs: ["Validated configuration"]
      outputs: ["Active schedule"]
      automatable: true
```

#### wf.delivery.handle_failure

```yaml
workflow:
  id: "wf.delivery.handle_failure"
  name: "Handle Delivery Failure"
  trigger: "Scheduled report fails to generate or deliver"
  actors: ["System", "Report Owner"]

  steps:
    - step: 1
      name: "Log Failure"
      actor: "System"
      action: "Record error details in delivery log"
      inputs: ["Error information"]
      outputs: ["Failure log entry"]
      automatable: true

    - step: 2
      name: "Attempt Retry"
      actor: "System"
      action: "Retry delivery up to max attempts"
      inputs: ["Failure details", "Retry policy"]
      outputs: ["Retry result"]
      automatable: true
      decision_point: "Retry count < max?"

    - step: 3
      name: "Notify Owner"
      actor: "System"
      action: "Alert report owner of persistent failure"
      inputs: ["Failure details", "Schedule info"]
      outputs: ["Notification sent"]
      automatable: true
      condition: "All retries exhausted"

    - step: 4
      name: "Pause Schedule"
      actor: "System"
      action: "Automatically pause after consecutive failures"
      inputs: ["Failure history"]
      outputs: ["Paused schedule"]
      automatable: true
      condition: "Consecutive failures > threshold"

    - step: 5
      name: "Investigate and Resolve"
      actor: "Report Owner"
      action: "Fix underlying issue"
      inputs: ["Failure details", "Report definition"]
      outputs: ["Resolution"]

    - step: 6
      name: "Resume Schedule"
      actor: "Report Owner"
      action: "Reactivate schedule after fix"
      inputs: ["Fixed schedule"]
      outputs: ["Active schedule"]
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-RPT-029 | **Report has no data this period** | Low | Configurable: skip, send empty, or send with message |
| EC-RPT-030 | **Recipient email bounces** | Medium | Mark as invalid; notify owner; retry different email |
| EC-RPT-031 | **Report execution exceeds schedule interval** | Medium | Prevent overlap; skip next run; alert owner |
| EC-RPT-032 | **SFTP server unavailable** | Medium | Retry with backoff; store for manual pickup; notify owner |
| EC-RPT-033 | **Time zone ambiguity (DST transition)** | Low | Use explicit timezone rules; document behavior |
| EC-RPT-034 | **Large report file exceeds email limit** | Medium | Split into parts; use download link; send to file share |
| EC-RPT-035 | **Subscription to report user cannot access** | High | Validate permissions at subscribe time; check before delivery |
| EC-RPT-036 | **Schedule configured for past time** | Low | Run immediately or next valid occurrence; warn user |
| EC-RPT-037 | **Hundreds of subscribers on single report** | Medium | Batch deliveries; throttle to avoid rate limits |
| EC-RPT-038 | **User unsubscribes but keeps receiving** | Medium | Clear caches; verify subscription status; audit delivery |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-RPT-014 | **Optimal send time suggestion** | User engagement data | Best delivery time per user | Increases report open rates |
| AI-RPT-015 | **Report summarization** | Report data | Email-friendly summary | Provides quick insights without opening file |
| AI-RPT-016 | **Delivery failure prediction** | Delivery history | Risk of failure | Proactive issue prevention |
| AI-RPT-017 | **Subscription recommendation** | User role, activity | Suggested reports to subscribe | Helps users discover relevant reports |

---

## Self-Service Considerations

### Design Principles

1. **Drag-drop interface** - No SQL knowledge required for basic reports
2. **Natural language filters** - "Sales last quarter" instead of date pickers
3. **Curated joins** - Pre-defined relationships prevent incorrect data combinations
4. **Progressive disclosure** - Simple by default, advanced options available

### Filter Best Practices

| Guideline | Reason |
|-----------|--------|
| Maximum 5 filters per dashboard | More filters overwhelm users and slow performance |
| Use dropdowns over free text | Prevents typos and invalid values |
| Show filter counts | "Region (5 selected)" helps users understand state |
| Remember filter selections | Users expect persistence across sessions |
| Provide filter reset | Easy way to clear all filters |

### What to Avoid

| Anti-Pattern | Why It's Problematic |
|--------------|---------------------|
| Custom query languages | Users won't learn proprietary syntax |
| Real-time everything | Unnecessary cost; most data doesn't need sub-second refresh |
| Unlimited filters | Performance degrades; users get lost |
| Exposing raw tables | Users make incorrect joins; security risk |
| No row limits | Single query can crash database |

---

## Cross-Package Relationships

```
                    ┌─────────────────────────────────────────────┐
                    │              DATA SOURCES                    │
                    │  (Connections to databases, APIs, files)     │
                    └─────────────────┬───────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────────────────┐
                    │               METRICS                        │
                    │  (Business measures with standard calcs)     │
                    └─────────────────┬───────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    │                 │                 │
                    ▼                 ▼                 ▼
┌───────────────────────┐  ┌───────────────────┐  ┌───────────────────┐
│       REPORTS         │  │     WIDGETS       │  │    DASHBOARDS     │
│  (Data + Formatting)  │──│  (Visualizations) │──│  (Widget layouts) │
└───────────────────────┘  └───────────────────┘  └───────────────────┘
          │
          ▼
┌───────────────────────────────────────────────────────────────────┐
│                         DELIVERY                                   │
│  (Schedules, Subscriptions, Distribution)                          │
└───────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Reporting

| From | To | Integration |
|------|-----|-------------|
| DataSource | Report | Report queries data source |
| DataSource | Metric | Metric calculates from data source |
| Metric | Widget | Widget displays metric value |
| Metric | Report | Report includes metric calculations |
| Report | Widget | Widget renders report results |
| Report | ScheduledReport | Schedule executes report |
| Widget | Dashboard | Dashboard contains widgets |
| Dashboard | DashboardFilter | Filter applies to dashboard widgets |

---

## Integration Points (External Systems)

### BI Tools

| System | Use Case | Notes |
|--------|----------|-------|
| **Tableau** | Enterprise visualization | Strong for complex analytics |
| **Power BI** | Microsoft ecosystem | Good Excel integration |
| **Looker** | Semantic layer focus | Strong data modeling |
| **Metabase** | Open source BI | Good for simpler needs |
| **Superset** | Open source, SQL-focused | Highly customizable |

### Data Warehouses

| System | Use Case | Notes |
|--------|----------|-------|
| **Snowflake** | Cloud data warehouse | Excellent performance scaling |
| **BigQuery** | Google ecosystem | Serverless, good for analytics |
| **Redshift** | AWS ecosystem | Tight AWS integration |
| **Databricks** | Data lakehouse | ML + BI combined |
| **PostgreSQL** | Operational analytics | Good for smaller scale |

### Delivery Channels

| System | Use Case | Notes |
|--------|----------|-------|
| **Email (SMTP)** | Standard delivery | Most common method |
| **Slack** | Team notifications | Good for alerts |
| **Microsoft Teams** | Enterprise collaboration | Growing adoption |
| **SFTP/S3** | File drops | For downstream systems |
| **Webhooks** | Custom integrations | Flexible but requires dev |

---

## Security Considerations

### Permission Levels

| Level | Description | Capabilities |
|-------|-------------|--------------|
| **View** | Can see report output | Run published reports |
| **Run** | Can execute with parameters | Change filters, export |
| **Edit** | Can modify report definition | Change query, layout |
| **Manage** | Can control access | Grant/revoke permissions |
| **Owner** | Full control | Delete, transfer ownership |

### Row-Level Security (RLS)

RLS filters data based on user context:

```
User: regional_manager_west
RLS Filter: region = 'West'
Result: User only sees West region data
```

**Implementation approaches**:
1. Filter at query time (dynamic)
2. Separate views per user group (static)
3. Attribute-based access control (ABAC)

### Data Masking

| Technique | Use Case | Example |
|-----------|----------|---------|
| Full masking | Hide completely | `*****` |
| Partial masking | Show pattern | `***-**-1234` |
| Tokenization | Reversible for authorized users | `tok_abc123` |
| Aggregation only | No individual records | Averages only |

---

## Performance Guidelines

### Query Optimization

| Technique | When to Use |
|-----------|-------------|
| Column indexing | Frequently filtered/sorted fields |
| Materialized views | Repeated aggregations |
| Query caching | Identical queries within time window |
| Pre-aggregation | Dashboard KPIs, common rollups |
| Partition pruning | Large date-based tables |

### Dashboard Performance

| Guideline | Target |
|-----------|--------|
| Initial load | < 3 seconds |
| Widget refresh | < 1 second |
| Maximum widgets | 20-25 per dashboard |
| Query concurrency | Stagger to avoid DB overload |

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Reports | Report, DataSource, ReportExecution | ReportPermission |
| Dashboards | Dashboard, Widget | DashboardFilter |
| Metrics | Metric, MetricDimension | MetricSnapshot |
| Delivery | ScheduledReport, DeliveryLog | Subscription |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.reports.create_and_publish | Create and Publish Report | User initiates |
| wf.reports.modify_existing | Modify Existing Report | User edits published report |
| wf.dashboards.build_dashboard | Build Interactive Dashboard | User initiates |
| wf.dashboards.public_display | Configure Public Display | TV/public screen needed |
| wf.metrics.define_metric | Define Business Metric | Business needs standardized metric |
| wf.metrics.update_definition | Update Metric Definition | Calculation needs to change |
| wf.delivery.schedule_report | Schedule Report Delivery | Automated distribution needed |
| wf.delivery.handle_failure | Handle Delivery Failure | Report fails to deliver |

### Common Edge Case Themes

1. **Scale issues** - Too many rows, widgets, or subscribers
2. **Data freshness** - Cache vs real-time trade-offs
3. **Permission complexity** - Row-level, column-level, object-level
4. **Delivery reliability** - Network failures, invalid recipients
5. **Schema drift** - Underlying data changes breaking reports
6. **Calculation consistency** - Same metric, different results
7. **User experience** - Performance, complexity, discoverability

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
