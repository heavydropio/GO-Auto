# Round 1.5: Module Selection

**Project**: {{ project_name }}
**Date**: {{ ISO_DATE }}
**Status**: Pending | In Progress | Complete
**Duration**: 5 minutes

---

## Purpose

Round 1.5 bridges context (R1) and detailed discovery (R2-R7). Based on what we learned about the problem, actors, and environment, we select which **module catalogs** apply. Each module brings:

- Pre-built discovery questions (reduces "blank page" syndrome)
- Entity templates (common data structures)
- Edge case libraries (known pitfalls)
- AI touchpoint patterns (where automation helps)

Selecting modules early accelerates all subsequent rounds.

---

## Instructions for Boss Agent

### Step 1: Review R1 Outputs

Read `discovery/R1_CONTEXT.md` and extract:
- Primary actors and their goals
- Key workflows mentioned
- Integration requirements
- Domain terminology used

### Step 2: Module Matching

For each module below, check if **any** trigger phrase matches the R1 context.

### Step 3: Confirm with User

Present matched modules and ask:
- "I've identified [N] modules that seem relevant: [list]. Does this match your understanding?"
- "Are there any I missed or included incorrectly?"

### Step 4: Select Packages

For each confirmed module, identify which **packages** (sub-capabilities) apply.

---

## Module Catalog (13 Universal Modules)

### 1. Administrative
**Purpose**: Core business operations - calendars, contacts, tasks, settings

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "schedule", "calendar", "appointment", "meeting" | Office manager, Admin assistant | Google Calendar, Outlook |
| "contact list", "address book", "directory" | All users | Email providers |
| "to-do", "task list", "reminders" | All users | Notification systems |
| "settings", "preferences", "configuration" | Admins | — |

**Packages**:
```yaml
administrative:
  calendar:
    entities: [Event, Recurrence, Attendee]
    screens: [CalendarView, EventForm, Availability]
    edge_cases: [timezone_handling, recurring_conflicts, all_day_events]

  contacts:
    entities: [Contact, ContactGroup, Address]
    screens: [ContactList, ContactDetail, ImportExport]
    edge_cases: [duplicate_detection, merge_contacts, shared_contacts]

  tasks:
    entities: [Task, TaskList, Reminder]
    screens: [TaskBoard, TaskForm, MyTasks]
    edge_cases: [overdue_handling, delegation, recurring_tasks]

  settings:
    entities: [UserPreference, SystemConfig, FeatureFlag]
    screens: [SettingsPanel, ProfileEdit]
    edge_cases: [permission_levels, default_values, migration]
```

---

### 2. Financial
**Purpose**: Money movement - invoicing, payments, AR/AP, accounting

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "invoice", "bill", "billing" | Accountant, Business owner | QuickBooks, Xero |
| "payment", "pay", "charge" | Customer, Finance team | Stripe, PayPal |
| "accounts receivable", "AR", "collections" | Finance team | Banking APIs |
| "accounts payable", "AP", "vendors" | Finance team | Vendor portals |
| "expense", "receipt", "reimbursement" | Employees, Finance | Receipt scanning |
| "budget", "forecast", "P&L" | Management | BI tools |

**Packages**:
```yaml
financial:
  invoicing:
    entities: [Invoice, InvoiceLine, Client, Matter, TimeEntry]
    screens: [InvoiceList, InvoiceBuilder, InvoicePreview, PaymentPortal]
    edge_cases: [partial_payments, credits, disputes, late_fees, tax_handling]
    ai_touchpoints: [auto_categorization, anomaly_detection, payment_prediction]

  payments:
    entities: [Payment, PaymentMethod, Transaction, Refund]
    screens: [PaymentForm, TransactionHistory, RefundRequest]
    edge_cases: [failed_payments, chargebacks, currency_conversion, pci_compliance]

  accounts_receivable:
    entities: [Receivable, AgingBucket, CollectionNote]
    screens: [ARDashboard, AgingReport, CollectionQueue]
    edge_cases: [write_offs, payment_plans, bad_debt]

  accounts_payable:
    entities: [Payable, Vendor, Bill, VendorCredit]
    screens: [APDashboard, BillEntry, PaymentRun]
    edge_cases: [early_payment_discounts, recurring_bills, approval_workflows]

  expenses:
    entities: [Expense, ExpenseReport, Receipt, Policy]
    screens: [ExpenseCapture, ReportBuilder, ApprovalQueue]
    edge_cases: [policy_violations, missing_receipts, mileage_calculation]
```

---

### 3. Field Service
**Purpose**: Work performed at customer locations - dispatch, mobile, offline

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "dispatch", "assign job", "schedule tech" | Dispatcher | Mapping/routing |
| "field", "on-site", "at customer location" | Field technician | GPS |
| "work order", "service ticket" | Dispatcher, Tech | CRM |
| "offline", "no signal", "sync later" | Field technician | Local storage |
| "mobile app", "tablet", "phone" | Field technician | Device APIs |
| "inspection", "checklist", "form" | Field technician | Document storage |

**Packages**:
```yaml
field_service:
  dispatch:
    entities: [WorkOrder, Assignment, Route, Territory]
    screens: [DispatchBoard, MapView, TechSchedule, AssignmentForm]
    edge_cases: [emergency_jobs, tech_unavailable, route_optimization, overtime]

  mobile:
    entities: [MobileSession, OfflineQueue, LocationPing]
    screens: [MobileJobList, JobDetail, ChecklistCapture, SignatureCapture]
    edge_cases: [battery_optimization, large_photo_uploads, form_validation_offline]

  offline_sync:
    entities: [SyncQueue, ConflictRecord, SyncLog]
    screens: [SyncStatus, ConflictResolution]
    edge_cases: [conflict_resolution, partial_sync, data_priority, stale_data]

  inspections:
    entities: [Inspection, ChecklistTemplate, Finding, Photo]
    screens: [InspectionForm, PhotoCapture, FindingDetail, ReportPreview]
    edge_cases: [required_photos, conditional_questions, pdf_generation]
```

---

### 4. Inventory
**Purpose**: Physical goods tracking - stock, transfers, reorder

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "inventory", "stock", "warehouse" | Warehouse manager | Barcode scanners |
| "transfer", "move stock", "location" | Warehouse staff | WMS |
| "reorder", "low stock", "purchase order" | Procurement | Supplier APIs |
| "SKU", "part number", "item" | All users | ERP |
| "count", "cycle count", "audit" | Warehouse manager | Mobile devices |

**Packages**:
```yaml
inventory:
  stock_tracking:
    entities: [Item, Location, StockLevel, Lot, SerialNumber]
    screens: [InventoryList, ItemDetail, StockAdjustment, LocationMap]
    edge_cases: [negative_stock, reserved_stock, expiration_dates, serial_tracking]

  transfers:
    entities: [Transfer, TransferLine, Shipment]
    screens: [TransferRequest, PickList, ReceiveShipment]
    edge_cases: [partial_transfers, damaged_goods, cross_dock]

  reorder:
    entities: [ReorderRule, PurchaseRequisition, Forecast]
    screens: [ReorderAlerts, RequisitionForm, ForecastView]
    edge_cases: [lead_time_variation, min_order_quantities, seasonal_demand]

  counting:
    entities: [CycleCount, CountSheet, Variance]
    screens: [CountSchedule, MobileCount, VarianceReport]
    edge_cases: [count_freezes, blind_counting, variance_thresholds]
```

---

### 5. Reporting
**Purpose**: Data visualization - dashboards, exports, KPIs

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "dashboard", "metrics", "KPI" | Management | BI tools |
| "report", "export", "download" | All users | Excel, PDF |
| "chart", "graph", "visualization" | Analysts | Charting libraries |
| "scheduled report", "email report" | Management | Email services |

**Packages**:
```yaml
reporting:
  dashboards:
    entities: [Dashboard, Widget, DataSource, Filter]
    screens: [DashboardBuilder, DashboardView, WidgetLibrary]
    edge_cases: [real_time_updates, permission_based_data, mobile_responsive]

  exports:
    entities: [ExportJob, ExportTemplate, ScheduledExport]
    screens: [ExportBuilder, ExportHistory, ScheduleManager]
    edge_cases: [large_datasets, timeout_handling, format_compatibility]

  analytics:
    entities: [Metric, Dimension, Calculation, Benchmark]
    screens: [MetricExplorer, TrendAnalysis, Comparison]
    edge_cases: [data_freshness, calculation_consistency, drill_down]
```

---

### 6. CRM (Customer Relationship Management)
**Purpose**: Customer tracking - history, interactions, lifecycle

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "customer", "client", "account" | Sales, Support | Email, Phone |
| "contact history", "interaction", "touchpoint" | Sales, Support | Communication tools |
| "lead", "prospect", "opportunity" | Sales | Marketing automation |
| "customer profile", "360 view" | All customer-facing | Data warehouse |

**Packages**:
```yaml
crm:
  customer_management:
    entities: [Customer, Contact, Account, Relationship]
    screens: [CustomerList, CustomerDetail, ContactForm, AccountHierarchy]
    edge_cases: [duplicate_customers, merge_records, inactive_customers]

  interaction_tracking:
    entities: [Interaction, Note, Activity, Communication]
    screens: [ActivityTimeline, NoteEditor, InteractionLog]
    edge_cases: [auto_logging, sentiment_tracking, privacy_compliance]

  lifecycle:
    entities: [LifecycleStage, Segment, Score, Journey]
    screens: [LifecycleView, SegmentBuilder, ScoringRules]
    edge_cases: [stage_transitions, re_engagement, churn_prediction]
    ai_touchpoints: [next_best_action, churn_risk, upsell_opportunity]
```

---

### 7. HR / People
**Purpose**: Employee management - directory, time, payroll

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "employee", "staff", "team member" | HR, Managers | HRIS |
| "time tracking", "clock in", "timesheet" | Employees, Managers | Payroll |
| "payroll", "pay", "compensation" | HR, Finance | Payroll providers |
| "PTO", "leave", "vacation", "time off" | Employees, HR | Calendar |
| "org chart", "reporting structure" | HR, Management | — |

**Packages**:
```yaml
hr:
  directory:
    entities: [Employee, Department, Position, OrgUnit]
    screens: [EmployeeDirectory, OrgChart, PositionDetail]
    edge_cases: [terminated_employees, contractors, multi_location]

  time_tracking:
    entities: [TimeEntry, Timesheet, ApprovalRule, OvertimePolicy]
    screens: [TimeEntry, TimesheetView, ApprovalQueue, OvertimeReport]
    edge_cases: [missed_punches, overtime_calculation, break_requirements]

  leave:
    entities: [LeaveRequest, LeaveBalance, LeavePolicy, Holiday]
    screens: [LeaveRequest, BalanceView, TeamCalendar, PolicyConfig]
    edge_cases: [accrual_calculations, carry_over, blackout_dates]

  payroll:
    entities: [PayRun, PayStub, Deduction, TaxWithholding]
    screens: [PayRunBuilder, PayStubView, DeductionConfig]
    edge_cases: [retroactive_changes, multi_state, garnishments]
```

---

### 8. Sales
**Purpose**: Revenue generation - pipeline, quotes, orders

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "pipeline", "deals", "opportunities" | Sales rep, Manager | CRM |
| "quote", "proposal", "estimate" | Sales rep | Document generation |
| "order", "purchase", "buy" | Sales rep, Customer | ERP, Inventory |
| "commission", "quota", "target" | Sales rep, Manager | Compensation |
| "forecast", "projection" | Management | BI |

**Packages**:
```yaml
sales:
  pipeline:
    entities: [Opportunity, Stage, Activity, Competitor]
    screens: [PipelineBoard, OpportunityDetail, ActivityLog, Forecast]
    edge_cases: [stale_opportunities, stage_skipping, multi_contact_deals]
    ai_touchpoints: [win_probability, deal_coaching, next_step_suggestion]

  quoting:
    entities: [Quote, QuoteLine, PriceBook, Discount, Approval]
    screens: [QuoteBuilder, QuotePreview, ApprovalWorkflow, PriceConfig]
    edge_cases: [expiring_quotes, version_control, complex_pricing]

  orders:
    entities: [Order, OrderLine, Fulfillment, Return]
    screens: [OrderEntry, OrderStatus, FulfillmentQueue, ReturnProcess]
    edge_cases: [partial_fulfillment, backorders, order_modifications]

  compensation:
    entities: [Commission, Quota, Territory, Attainment]
    screens: [CommissionStatement, QuotaTracking, TerritoryMap]
    edge_cases: [split_deals, clawbacks, plan_changes]
```

---

### 9. Procurement
**Purpose**: Buying - vendors, POs, receiving

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "vendor", "supplier", "source" | Procurement, AP | Supplier portals |
| "purchase order", "PO", "requisition" | Procurement, Requesters | ERP |
| "receiving", "goods receipt", "delivery" | Warehouse | Inventory |
| "RFQ", "bid", "sourcing" | Procurement | E-sourcing |

**Packages**:
```yaml
procurement:
  vendor_management:
    entities: [Vendor, VendorContact, Contract, Performance]
    screens: [VendorList, VendorDetail, ContractManager, Scorecard]
    edge_cases: [vendor_onboarding, compliance_docs, performance_issues]

  purchasing:
    entities: [PurchaseOrder, POLine, Requisition, Approval]
    screens: [POBuilder, RequisitionForm, ApprovalQueue, POHistory]
    edge_cases: [blanket_orders, change_orders, three_way_match]

  receiving:
    entities: [Receipt, ReceiptLine, Inspection, Discrepancy]
    screens: [ReceivingQueue, ReceiptEntry, InspectionForm, DiscrepancyReport]
    edge_cases: [partial_receipts, damaged_goods, ASN_matching]

  sourcing:
    entities: [RFQ, Bid, Evaluation, Award]
    screens: [RFQBuilder, BidComparison, EvaluationMatrix]
    edge_cases: [sealed_bids, evaluation_criteria, award_notifications]
```

---

### 10. Project / Job Management
**Purpose**: Work organization - projects, tasks, resources

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "project", "job", "engagement" | PM, Team members | PM tools |
| "task", "work item", "assignment" | Team members | — |
| "resource", "allocation", "capacity" | PM, Resource manager | HR |
| "milestone", "deadline", "timeline" | PM, Stakeholders | Calendar |
| "budget", "cost tracking", "burn rate" | PM, Finance | Financial |

**Packages**:
```yaml
project:
  project_management:
    entities: [Project, Phase, Milestone, Deliverable]
    screens: [ProjectList, ProjectDetail, GanttChart, MilestoneTracker]
    edge_cases: [scope_changes, dependencies, project_templates]

  task_management:
    entities: [Task, Subtask, Assignment, Status]
    screens: [TaskBoard, TaskDetail, MyWork, TeamView]
    edge_cases: [blocked_tasks, priority_conflicts, time_estimates]

  resource_management:
    entities: [Resource, Allocation, Capacity, Skill]
    screens: [ResourceCalendar, AllocationView, CapacityPlanning]
    edge_cases: [over_allocation, skill_matching, time_off]

  project_finance:
    entities: [Budget, Expense, TimeCharge, Variance]
    screens: [BudgetView, ExpenseTracking, ProfitabilityReport]
    edge_cases: [budget_revisions, billing_rates, overhead_allocation]
```

---

### 11. Communication
**Purpose**: Messaging - email, chat, notifications

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "email", "message", "send" | All users | Email providers |
| "chat", "instant message", "Slack" | Team members | Chat platforms |
| "notification", "alert", "remind" | All users | Push services |
| "template", "canned response" | Support, Sales | — |

**Packages**:
```yaml
communication:
  email:
    entities: [EmailMessage, EmailTemplate, EmailCampaign, Attachment]
    screens: [Inbox, Compose, TemplateEditor, CampaignBuilder]
    edge_cases: [delivery_tracking, bounce_handling, unsubscribe]

  chat:
    entities: [Conversation, Message, Participant, Channel]
    screens: [ChatWindow, ChannelList, ThreadView]
    edge_cases: [offline_messages, file_sharing, presence]

  notifications:
    entities: [Notification, NotificationPreference, Channel]
    screens: [NotificationCenter, PreferenceSettings]
    edge_cases: [quiet_hours, channel_preferences, digest_mode]
```

---

### 12. Documents
**Purpose**: File management - storage, templates, e-sign

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "document", "file", "attachment" | All users | Cloud storage |
| "template", "generate", "merge" | All users | Document generation |
| "signature", "e-sign", "DocuSign" | All users | E-signature services |
| "version", "revision", "history" | All users | — |

**Packages**:
```yaml
documents:
  storage:
    entities: [Document, Folder, Permission, Version]
    screens: [FileExplorer, DocumentViewer, UploadForm, ShareDialog]
    edge_cases: [large_files, access_control, deleted_recovery]

  templates:
    entities: [Template, MergeField, GeneratedDocument]
    screens: [TemplateBuilder, MergePreview, GenerationHistory]
    edge_cases: [conditional_content, table_loops, image_insertion]

  esignature:
    entities: [SignatureRequest, Signer, SignatureField, Envelope]
    screens: [SigningView, RequestBuilder, SignatureStatus]
    edge_cases: [signing_order, declined_signatures, expiration]

  versioning:
    entities: [Version, ChangeLog, Comparison]
    screens: [VersionHistory, CompareView, RestoreDialog]
    edge_cases: [conflict_resolution, major_minor_versions, rollback]
```

---

### 13. Compliance
**Purpose**: Regulatory - audit trails, certifications, policies

| Trigger Phrases | Actors | Common Integrations |
|-----------------|--------|---------------------|
| "audit", "audit trail", "log" | Compliance, Auditors | SIEM |
| "compliance", "regulation", "requirement" | Compliance | GRC tools |
| "certification", "license", "credential" | HR, Compliance | Verification services |
| "policy", "procedure", "acknowledgment" | All users | — |
| "HIPAA", "SOC2", "GDPR", "PCI" | Compliance | Compliance tools |

**Packages**:
```yaml
compliance:
  audit_trail:
    entities: [AuditLog, Event, Actor, Change]
    screens: [AuditViewer, EventSearch, ChangeReport]
    edge_cases: [log_retention, sensitive_data_masking, tamper_evidence]

  certifications:
    entities: [Certification, Credential, Expiration, Verification]
    screens: [CertificationTracker, ExpirationAlerts, VerificationLog]
    edge_cases: [grace_periods, renewal_workflows, verification_failures]

  policies:
    entities: [Policy, PolicyVersion, Acknowledgment, Training]
    screens: [PolicyLibrary, AcknowledgmentForm, ComplianceDashboard]
    edge_cases: [policy_updates, attestation_tracking, exceptions]

  regulatory:
    entities: [Regulation, Requirement, Control, Assessment]
    screens: [RequirementMatrix, ControlMapping, AssessmentForm]
    edge_cases: [overlapping_requirements, evidence_collection, gap_analysis]
```

---

## Selection Output

After confirmation, update `discovery/discovery-state.json`:

```json
{
  "modules": {
    "selected": ["financial", "field_service", "crm"],
    "packages": {
      "financial": ["invoicing", "payments"],
      "field_service": ["dispatch", "mobile", "offline_sync", "inspections"],
      "crm": ["customer_management", "interaction_tracking"]
    },
    "selection_rationale": {
      "financial": "User mentioned invoicing and payment tracking",
      "field_service": "Primary actors are field technicians with offline needs",
      "crm": "Customer history tracking was explicit requirement"
    },
    "rejected": {
      "inventory": "No physical goods mentioned",
      "hr": "No employee management needs identified"
    }
  },
  "rounds": {
    "R1.5": {
      "status": "complete",
      "completed": "{{ ISO_DATE }}",
      "modules_selected": 3,
      "packages_selected": 8
    }
  },
  "current_round": "R2"
}
```

---

## Validation Checklist

R1.5 cannot be marked complete until:

- [ ] At least 1 module selected
- [ ] User confirmed module selection
- [ ] Each selected module has at least 1 package identified
- [ ] Selection rationale documented
- [ ] Rejected modules noted (if any were considered)

---

## State Update

When R1.5 completes:

1. Update `rounds.R1.5.status` to "complete"
2. Update `modules.selected` with confirmed list
3. Update `modules.packages` with package selections
4. Set `current_round` to "R2"
5. Note: R2 and R3 can now run in parallel

---

## Next Steps

After R1.5 completes:
1. Save state to `discovery/discovery-state.json`
2. Announce: "Module selection complete. R2 (Entities) and R3 (Workflows) can run in parallel."
3. Proceed to R2 and R3 (can be parallel)

---

## Module Quick Reference

| # | Module | Key Packages | Typical Actors |
|---|--------|--------------|----------------|
| 1 | Administrative | calendar, contacts, tasks | Admins, All users |
| 2 | Financial | invoicing, payments, AR/AP | Finance, Customers |
| 3 | Field Service | dispatch, mobile, offline | Dispatchers, Techs |
| 4 | Inventory | stock, transfers, reorder | Warehouse staff |
| 5 | Reporting | dashboards, exports | Management, Analysts |
| 6 | CRM | customers, interactions | Sales, Support |
| 7 | HR/People | directory, time, payroll | HR, Employees |
| 8 | Sales | pipeline, quotes, orders | Sales reps |
| 9 | Procurement | vendors, POs, receiving | Procurement |
| 10 | Project/Job | projects, tasks, resources | PMs, Team members |
| 11 | Communication | email, chat, notifications | All users |
| 12 | Documents | storage, templates, e-sign | All users |
| 13 | Compliance | audit, certs, policies | Compliance, Auditors |
