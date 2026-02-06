# HR/People Module Catalog

**Module**: HR/People
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The HR/People module covers all aspects of managing an organization's workforce: tracking employees, managing time and attendance, handling leave requests, ensuring compliance with labor laws, and coordinating with external systems like payroll and benefits providers. The central concept is the "Employee Graph" where the employee record serves as a hub with all other HR data linking to it.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "employee", "hire", "onboarding", "new hire" | HR Manager, Hiring Manager | Bring new employees into the organization |
| "time tracking", "timesheet", "clock in/out" | Employee, Manager, Payroll | Record hours worked for pay and projects |
| "PTO", "vacation", "sick leave", "time off" | Employee, Manager, HR | Request and approve employee absences |
| "department", "org chart", "reporting structure" | HR, Management | Organize workforce hierarchy |
| "offboarding", "termination", "exit" | HR Manager, IT | Process employee departures |
| "I-9", "W-4", "compliance", "FLSA" | HR, Compliance | Meet legal employment requirements |

### Module Dependencies

```
HR/People Module
├── REQUIRES: Administrative (for settings, user preferences)
├── REQUIRES: Documents (for compliance docs, offer letters)
├── INTEGRATES_WITH: Payroll (external - DO NOT BUILD)
├── INTEGRATES_WITH: Benefits (external - health, 401k)
├── INTEGRATES_WITH: IT Provisioning (accounts, equipment)
├── INTEGRATES_WITH: Accounting (labor costs, GL coding)
├── INTEGRATES_WITH: Financial (time entries for billing)
```

**Important Note**: This module explicitly does NOT include a payroll engine. Payroll involves tax withholding, garnishments, multi-state compliance, and frequent regulatory changes. Always integrate with dedicated payroll providers (ADP, Gusto, Paychex, etc.).

---

## Packages

This module contains 5 packages:

1. **employee_management** - Core employee records and organizational structure
2. **time_attendance** - Time tracking, schedules, and overtime
3. **leave_management** - PTO, sick leave, and absence tracking
4. **compliance** - Employment documents and regulatory requirements
5. **onboarding_offboarding** - Employee lifecycle transitions

---

## Package 1: Employee Management

### Purpose

Maintain the central employee record that serves as the hub for all HR data. Track organizational structure, positions, departments, and employment status.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What information do you track for each employee? (contact, emergency contacts, demographics)
- How is your organization structured? (departments, divisions, cost centers)
- Do employees have multiple positions or report to multiple managers?
- What employment types do you have? (full-time, part-time, contractor, intern)
- Do you track employee skills, certifications, or licenses?

**Workflow Discovery**:
- How do managers request new positions?
- Who approves organizational changes?
- How do you handle internal transfers and promotions?
- What triggers an employee record update?

**Edge Case Probing**:
- Can an employee belong to multiple departments?
- How do you handle rehires?
- What happens when a department is reorganized or eliminated?

### Entity Templates

#### Employee

```json
{
  "id": "data.employee_management.employee",
  "name": "Employee",
  "type": "data",
  "namespace": "employee_management",
  "tags": ["core-entity", "mvp", "pii-sensitive"],
  "status": "discovered",

  "spec": {
    "purpose": "Central hub record for a person employed by the organization.",
    "fields": [
      { "name": "employee_number", "type": "string", "required": true, "description": "Unique employee identifier (e.g., EMP-001234)" },
      { "name": "first_name", "type": "string", "required": true, "description": "Legal first name" },
      { "name": "last_name", "type": "string", "required": true, "description": "Legal last name" },
      { "name": "preferred_name", "type": "string", "required": false, "description": "Name employee prefers to be called" },
      { "name": "email", "type": "email", "required": true, "description": "Work email address" },
      { "name": "personal_email", "type": "email", "required": false, "description": "Personal email for emergencies" },
      { "name": "phone", "type": "phone", "required": false, "description": "Work phone number" },
      { "name": "mobile_phone", "type": "phone", "required": false, "description": "Personal mobile number" },
      { "name": "date_of_birth", "type": "date", "required": false, "description": "Birth date for benefits and compliance" },
      { "name": "ssn_last_four", "type": "encrypted_string", "required": false, "description": "Last 4 digits of SSN for verification" },
      { "name": "address", "type": "address", "required": false, "description": "Home address" },
      { "name": "hire_date", "type": "date", "required": true, "description": "Original hire date" },
      { "name": "start_date", "type": "date", "required": true, "description": "First day of work" },
      { "name": "termination_date", "type": "date", "required": false, "description": "Last day of employment" },
      { "name": "employment_status", "type": "enum", "required": true, "values": ["active", "on_leave", "suspended", "terminated"], "description": "Current employment state" },
      { "name": "employment_type", "type": "enum", "required": true, "values": ["full_time", "part_time", "contractor", "intern", "temporary"], "description": "Type of employment" },
      { "name": "flsa_status", "type": "enum", "required": true, "values": ["exempt", "non_exempt"], "description": "FLSA overtime eligibility" },
      { "name": "department_id", "type": "uuid", "required": true, "description": "Primary department" },
      { "name": "position_id", "type": "uuid", "required": true, "description": "Current position/job title" },
      { "name": "manager_id", "type": "uuid", "required": false, "description": "Direct supervisor (Employee reference)" },
      { "name": "work_location", "type": "string", "required": false, "description": "Office location or remote designation" },
      { "name": "pay_rate", "type": "decimal", "required": false, "description": "Hourly rate or salary amount" },
      { "name": "pay_type", "type": "enum", "required": false, "values": ["hourly", "salary"], "description": "Compensation basis" },
      { "name": "pay_frequency", "type": "enum", "required": false, "values": ["weekly", "biweekly", "semimonthly", "monthly"], "description": "How often paid" }
    ],
    "relationships": [
      { "entity": "Department", "type": "many_to_one", "required": true },
      { "entity": "Position", "type": "many_to_one", "required": true },
      { "entity": "Employee", "type": "many_to_one", "required": false, "description": "Manager" },
      { "entity": "TimeEntry", "type": "one_to_many", "required": false },
      { "entity": "LeaveRequest", "type": "one_to_many", "required": false },
      { "entity": "LeaveBalance", "type": "one_to_many", "required": false },
      { "entity": "ComplianceDocument", "type": "one_to_many", "required": false },
      { "entity": "EmergencyContact", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.employee_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Department

```json
{
  "id": "data.employee_management.department",
  "name": "Department",
  "type": "data",
  "namespace": "employee_management",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Organizational unit grouping employees by function or business area.",
    "fields": [
      { "name": "code", "type": "string", "required": true, "description": "Unique department code (e.g., ENG, HR, FIN)" },
      { "name": "name", "type": "string", "required": true, "description": "Full department name" },
      { "name": "parent_department_id", "type": "uuid", "required": false, "description": "Parent department for hierarchy" },
      { "name": "department_head_id", "type": "uuid", "required": false, "description": "Employee who leads this department" },
      { "name": "cost_center", "type": "string", "required": false, "description": "Accounting cost center code" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "inactive"], "description": "Whether department is active" },
      { "name": "effective_date", "type": "date", "required": false, "description": "When department was created/activated" },
      { "name": "end_date", "type": "date", "required": false, "description": "When department was deactivated" }
    ],
    "relationships": [
      { "entity": "Department", "type": "many_to_one", "required": false, "description": "Parent department" },
      { "entity": "Employee", "type": "one_to_many", "required": false },
      { "entity": "Position", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.employee_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Position

```json
{
  "id": "data.employee_management.position",
  "name": "Position",
  "type": "data",
  "namespace": "employee_management",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Job title and role definition within the organization.",
    "fields": [
      { "name": "title", "type": "string", "required": true, "description": "Job title (e.g., Software Engineer, HR Manager)" },
      { "name": "code", "type": "string", "required": false, "description": "Position code for reporting" },
      { "name": "department_id", "type": "uuid", "required": true, "description": "Department this position belongs to" },
      { "name": "job_description", "type": "text", "required": false, "description": "Full job description" },
      { "name": "pay_grade", "type": "string", "required": false, "description": "Compensation band/level" },
      { "name": "min_salary", "type": "decimal", "required": false, "description": "Minimum of pay range" },
      { "name": "max_salary", "type": "decimal", "required": false, "description": "Maximum of pay range" },
      { "name": "flsa_default", "type": "enum", "required": false, "values": ["exempt", "non_exempt"], "description": "Default FLSA status for this position" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "inactive", "frozen"], "description": "Whether position can be filled" },
      { "name": "headcount_budget", "type": "integer", "required": false, "description": "Approved headcount for this position" },
      { "name": "reports_to_position_id", "type": "uuid", "required": false, "description": "Position this role reports to" }
    ],
    "relationships": [
      { "entity": "Department", "type": "many_to_one", "required": true },
      { "entity": "Employee", "type": "one_to_many", "required": false },
      { "entity": "Position", "type": "many_to_one", "required": false, "description": "Reporting position" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.employee_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### EmergencyContact

```json
{
  "id": "data.employee_management.emergency_contact",
  "name": "Emergency Contact",
  "type": "data",
  "namespace": "employee_management",
  "tags": ["core-entity", "pii-sensitive"],
  "status": "discovered",

  "spec": {
    "purpose": "Contact information for emergencies related to an employee.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee this contact is for" },
      { "name": "name", "type": "string", "required": true, "description": "Contact's full name" },
      { "name": "relationship", "type": "string", "required": true, "description": "Relationship to employee (spouse, parent, friend)" },
      { "name": "phone", "type": "phone", "required": true, "description": "Primary contact number" },
      { "name": "alternate_phone", "type": "phone", "required": false, "description": "Backup contact number" },
      { "name": "email", "type": "email", "required": false, "description": "Email address" },
      { "name": "is_primary", "type": "boolean", "required": true, "description": "Primary emergency contact" },
      { "name": "priority", "type": "integer", "required": false, "description": "Contact order (1 = first to call)" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.employee_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.employee_management.internal_transfer

```yaml
workflow:
  id: "wf.employee_management.internal_transfer"
  name: "Internal Transfer or Promotion"
  trigger: "Manager or HR initiates transfer/promotion"
  actors: ["Current Manager", "Receiving Manager", "HR", "Employee", "System"]

  steps:
    - step: 1
      name: "Initiate Transfer Request"
      actor: "Current Manager"
      action: "Submit transfer/promotion request with justification"
      inputs: ["Employee", "New position", "Effective date", "Justification"]
      outputs: ["Transfer request"]

    - step: 2
      name: "Receiving Manager Approval"
      actor: "Receiving Manager"
      action: "Review and approve acceptance of employee"
      inputs: ["Transfer request", "Employee record"]
      outputs: ["Manager approval"]
      decision_point: "Accept transfer?"

    - step: 3
      name: "HR Review"
      actor: "HR"
      action: "Verify compliance, pay changes, budget"
      inputs: ["Transfer request", "Manager approval"]
      outputs: ["HR approval", "Pay change details"]
      decision_point: "Approve with pay adjustment?"

    - step: 4
      name: "Update Employee Record"
      actor: "System"
      action: "Update department, position, manager, pay"
      inputs: ["Approved transfer", "Effective date"]
      outputs: ["Updated employee record", "Historical record"]
      automatable: true

    - step: 5
      name: "Notify Stakeholders"
      actor: "System"
      action: "Send notifications to all parties"
      inputs: ["Updated record"]
      outputs: ["Notification emails"]
      automatable: true

    - step: 6
      name: "Trigger Related Updates"
      actor: "System"
      action: "Update payroll, access rights, org chart"
      inputs: ["Updated employee record"]
      outputs: ["Integration updates"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-HR-001 | **Employee rehired after termination** | Medium | Create new employee number or reactivate with gap in service; link records for history |
| EC-HR-002 | **Department eliminated** | Medium | Transfer all employees first; mark department inactive; preserve for historical reporting |
| EC-HR-003 | **Employee reports to multiple managers** | Medium | Designate primary manager for HR purposes; support dotted-line relationships separately |
| EC-HR-004 | **Manager terminated with direct reports** | High | Immediately reassign reports; escalate to manager's manager temporarily |
| EC-HR-005 | **Circular reporting relationship** | High | Validate on save; prevent A reports to B reports to A |
| EC-HR-006 | **Employee disputes personal information** | Low | Allow employee self-service updates for non-sensitive fields; log all changes |
| EC-HR-007 | **Contractor converted to employee** | Medium | New employee record; link to contractor record for history; new I-9 required |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-HR-001 | **Org structure anomalies** | Reporting relationships, spans of control | Flags for review | Identifies organizational issues |
| AI-HR-002 | **Flight risk prediction** | Tenure, performance, market data | Risk score | Proactive retention efforts |
| AI-HR-003 | **Position matching** | Skills, experience, open positions | Suggested matches | Internal mobility support |
| AI-HR-004 | **Data completeness** | Employee records | Missing fields, inconsistencies | Data quality improvement |

---

## Package 2: Time & Attendance

### Purpose

Track hours worked, manage schedules, calculate overtime, and feed time data to payroll integration. Critical for FLSA compliance with non-exempt employees.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How do employees record time? (time clock, web app, mobile, manager entry)
- Do you track time to projects, tasks, or cost centers?
- What's your work week? (Sunday-Saturday, Monday-Sunday)
- Do you have shift differentials or premium pay?
- Do you need to track breaks and meal periods?

**Workflow Discovery**:
- Who approves timesheets? (direct manager, project manager, both)
- What's your pay period? (weekly, biweekly, semimonthly)
- When are timesheets due? (end of period, next day)
- Can employees edit submitted time?
- How do you handle missed punches?

**Edge Case Probing**:
- What if an employee works in multiple states?
- How do you handle on-call time?
- What about travel time between job sites?

### Entity Templates

#### TimeEntry

```json
{
  "id": "data.time_attendance.time_entry",
  "name": "Time Entry",
  "type": "data",
  "namespace": "time_attendance",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of time worked by an employee for a specific period.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee who worked" },
      { "name": "date", "type": "date", "required": true, "description": "Date of work" },
      { "name": "clock_in", "type": "datetime", "required": false, "description": "Start time (for punch-based)" },
      { "name": "clock_out", "type": "datetime", "required": false, "description": "End time (for punch-based)" },
      { "name": "hours", "type": "decimal", "required": true, "description": "Total hours worked" },
      { "name": "regular_hours", "type": "decimal", "required": false, "description": "Non-overtime hours" },
      { "name": "overtime_hours", "type": "decimal", "required": false, "description": "Overtime hours (FLSA)" },
      { "name": "double_time_hours", "type": "decimal", "required": false, "description": "Double-time hours if applicable" },
      { "name": "entry_type", "type": "enum", "required": true, "values": ["regular", "overtime", "pto", "sick", "holiday", "jury_duty", "bereavement", "unpaid"], "description": "Type of time entry" },
      { "name": "pay_code", "type": "string", "required": false, "description": "Payroll pay code" },
      { "name": "department_id", "type": "uuid", "required": false, "description": "Department to charge" },
      { "name": "project_id", "type": "uuid", "required": false, "description": "Project/job for cost allocation" },
      { "name": "task_code", "type": "string", "required": false, "description": "Task or activity code" },
      { "name": "description", "type": "text", "required": false, "description": "Work description" },
      { "name": "billable", "type": "boolean", "required": false, "description": "Time is billable to client" },
      { "name": "billing_rate", "type": "decimal", "required": false, "description": "Rate for billing if billable" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "rejected", "processed"], "description": "Approval status" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When employee submitted" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "Manager who approved" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "Approval timestamp" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why entry was rejected" },
      { "name": "source", "type": "enum", "required": false, "values": ["manual", "time_clock", "mobile", "import", "system"], "description": "How entry was created" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "Department", "type": "many_to_one", "required": false },
      { "entity": "PayPeriod", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.time_attendance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PayPeriod

```json
{
  "id": "data.time_attendance.pay_period",
  "name": "Pay Period",
  "type": "data",
  "namespace": "time_attendance",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Defined time period for payroll processing.",
    "fields": [
      { "name": "period_name", "type": "string", "required": true, "description": "Display name (e.g., 'Jan 1-15, 2026')" },
      { "name": "start_date", "type": "date", "required": true, "description": "First day of period" },
      { "name": "end_date", "type": "date", "required": true, "description": "Last day of period" },
      { "name": "pay_date", "type": "date", "required": true, "description": "When employees are paid" },
      { "name": "submission_deadline", "type": "datetime", "required": true, "description": "When timesheets must be submitted" },
      { "name": "approval_deadline", "type": "datetime", "required": true, "description": "When approvals must be complete" },
      { "name": "status", "type": "enum", "required": true, "values": ["upcoming", "open", "pending_approval", "locked", "processed"], "description": "Period status" },
      { "name": "frequency", "type": "enum", "required": true, "values": ["weekly", "biweekly", "semimonthly", "monthly"], "description": "Pay frequency" }
    ],
    "relationships": [
      { "entity": "TimeEntry", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.time_attendance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Schedule

```json
{
  "id": "data.time_attendance.schedule",
  "name": "Schedule",
  "type": "data",
  "namespace": "time_attendance",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Expected work schedule for an employee.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee this schedule is for" },
      { "name": "effective_date", "type": "date", "required": true, "description": "When schedule takes effect" },
      { "name": "end_date", "type": "date", "required": false, "description": "When schedule ends (null = ongoing)" },
      { "name": "schedule_type", "type": "enum", "required": true, "values": ["standard", "flexible", "shift", "on_call"], "description": "Type of schedule" },
      { "name": "weekly_hours", "type": "decimal", "required": false, "description": "Expected hours per week" },
      { "name": "monday_start", "type": "time", "required": false, "description": "Monday start time" },
      { "name": "monday_end", "type": "time", "required": false, "description": "Monday end time" },
      { "name": "tuesday_start", "type": "time", "required": false, "description": "Tuesday start time" },
      { "name": "tuesday_end", "type": "time", "required": false, "description": "Tuesday end time" },
      { "name": "wednesday_start", "type": "time", "required": false, "description": "Wednesday start time" },
      { "name": "wednesday_end", "type": "time", "required": false, "description": "Wednesday end time" },
      { "name": "thursday_start", "type": "time", "required": false, "description": "Thursday start time" },
      { "name": "thursday_end", "type": "time", "required": false, "description": "Thursday end time" },
      { "name": "friday_start", "type": "time", "required": false, "description": "Friday start time" },
      { "name": "friday_end", "type": "time", "required": false, "description": "Friday end time" },
      { "name": "saturday_start", "type": "time", "required": false, "description": "Saturday start time" },
      { "name": "saturday_end", "type": "time", "required": false, "description": "Saturday end time" },
      { "name": "sunday_start", "type": "time", "required": false, "description": "Sunday start time" },
      { "name": "sunday_end", "type": "time", "required": false, "description": "Sunday end time" },
      { "name": "timezone", "type": "string", "required": false, "description": "Schedule timezone" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "hr_people.time_attendance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.time_attendance.timesheet_approval

```yaml
workflow:
  id: "wf.time_attendance.timesheet_approval"
  name: "Timesheet Submission and Approval"
  trigger: "Pay period submission deadline approaches"
  actors: ["Employee", "Manager", "Payroll", "System"]

  steps:
    - step: 1
      name: "Enter Time"
      actor: "Employee"
      action: "Record daily hours throughout pay period"
      inputs: ["Work performed", "Projects", "Dates"]
      outputs: ["Draft time entries"]

    - step: 2
      name: "Submit Timesheet"
      actor: "Employee"
      action: "Review and submit timesheet for approval"
      inputs: ["Draft time entries"]
      outputs: ["Submitted timesheet"]

    - step: 3
      name: "Calculate Overtime"
      actor: "System"
      action: "Apply FLSA rules, calculate regular vs overtime hours"
      inputs: ["Submitted timesheet", "FLSA status", "State rules"]
      outputs: ["Calculated timesheet with OT breakdown"]
      automatable: true

    - step: 4
      name: "Manager Review"
      actor: "Manager"
      action: "Review hours, project allocation, overtime"
      inputs: ["Calculated timesheet"]
      outputs: ["Approval decision"]
      decision_point: "Approve, reject, or request changes?"

    - step: 5a
      name: "Approve Timesheet"
      actor: "Manager"
      action: "Approve timesheet for payroll"
      inputs: ["Timesheet"]
      outputs: ["Approved timesheet"]
      condition: "Manager approves"

    - step: 5b
      name: "Reject Timesheet"
      actor: "Manager"
      action: "Reject with reason, return to employee"
      inputs: ["Timesheet", "Rejection reason"]
      outputs: ["Rejected timesheet notification"]
      condition: "Manager rejects"

    - step: 6
      name: "Lock Pay Period"
      actor: "System"
      action: "Lock period after approval deadline"
      inputs: ["All timesheets", "Deadline"]
      outputs: ["Locked pay period"]
      automatable: true

    - step: 7
      name: "Export to Payroll"
      actor: "System"
      action: "Send approved time data to payroll provider"
      inputs: ["Locked pay period", "Approved timesheets"]
      outputs: ["Payroll export file/API call"]
      automatable: true
```

#### wf.time_attendance.missed_punch_correction

```yaml
workflow:
  id: "wf.time_attendance.missed_punch_correction"
  name: "Missed Punch Correction"
  trigger: "Employee reports missed clock in/out"
  actors: ["Employee", "Manager", "System"]

  steps:
    - step: 1
      name: "Report Missed Punch"
      actor: "Employee"
      action: "Submit correction request with actual times"
      inputs: ["Date", "Correct clock in/out times", "Reason"]
      outputs: ["Correction request"]

    - step: 2
      name: "Validate Request"
      actor: "System"
      action: "Check for reasonableness, duplicates, conflicts"
      inputs: ["Correction request", "Existing entries"]
      outputs: ["Validated request with flags"]
      automatable: true

    - step: 3
      name: "Manager Approval"
      actor: "Manager"
      action: "Review and approve time correction"
      inputs: ["Correction request", "Validation flags"]
      outputs: ["Approval decision"]
      decision_point: "Approve correction?"

    - step: 4
      name: "Apply Correction"
      actor: "System"
      action: "Update time entry, maintain audit trail"
      inputs: ["Approved correction"]
      outputs: ["Corrected time entry", "Audit record"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-HR-008 | **FLSA overtime calculation across state lines** | High | Apply most employee-favorable rules; track work location per entry |
| EC-HR-009 | **Employee works through meal break** | Medium | Auto-deduct unless employee indicates worked meal; maintain compliance records |
| EC-HR-010 | **Timesheet submitted after payroll cutoff** | Medium | Process in next pay period; allow manual adjustment if critical |
| EC-HR-011 | **Clock in/out times span midnight** | Low | Attribute to calendar date of shift start or per policy |
| EC-HR-012 | **Negative time entry (correction)** | Low | Support adjustments; require approval; clear audit trail |
| EC-HR-013 | **Employee disputes approved hours** | Medium | Allow reopen with manager approval before payroll lock |
| EC-HR-014 | **California daily overtime rules** | High | Track state; apply 8hr/day rule for CA employees |
| EC-HR-015 | **Remote employee in different timezone** | Medium | Record in employee's local time; convert for scheduling |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-HR-005 | **Overtime prediction** | Schedules, historical time, current entries | Projected OT by week end | Budget management |
| AI-HR-006 | **Time anomaly detection** | Time entries, patterns | Unusual entries flagged | Catch errors early |
| AI-HR-007 | **Project allocation suggestion** | Task descriptions, project list | Suggested project codes | Faster time entry |
| AI-HR-008 | **Compliance risk detection** | Hours, break patterns, state rules | Compliance warnings | Avoid FLSA violations |

---

## Package 3: Leave Management

### Purpose

Track employee time-off balances, process leave requests, and ensure proper coverage and compliance with leave policies (FMLA, state requirements).

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of leave do you offer? (PTO, vacation, sick, personal)
- Are leave types pooled or separate?
- How do balances accrue? (per pay period, annually, by tenure)
- Is there a carryover limit? Use-it-or-lose-it?
- Do you have negative balance policies?

**Workflow Discovery**:
- How far in advance must leave be requested?
- Who approves leave? (manager, HR, auto-approve)
- How do you ensure coverage during absences?
- Can approved leave be canceled?
- How do you handle unplanned sick days?

**Edge Case Probing**:
- What if leave request conflicts with blackout period?
- How do you handle leave for part-time employees?
- What about FMLA or other protected leave?

### Entity Templates

#### LeaveBalance

```json
{
  "id": "data.leave_management.leave_balance",
  "name": "Leave Balance",
  "type": "data",
  "namespace": "leave_management",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Current and projected leave balances for an employee by type.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee this balance is for" },
      { "name": "leave_type_id", "type": "uuid", "required": true, "description": "Type of leave (PTO, sick, etc.)" },
      { "name": "balance_year", "type": "integer", "required": true, "description": "Calendar or fiscal year" },
      { "name": "accrued_hours", "type": "decimal", "required": true, "description": "Total hours accrued YTD" },
      { "name": "used_hours", "type": "decimal", "required": true, "description": "Hours taken YTD" },
      { "name": "pending_hours", "type": "decimal", "required": true, "description": "Approved but not yet taken" },
      { "name": "available_hours", "type": "decimal", "required": true, "description": "accrued - used - pending" },
      { "name": "carryover_hours", "type": "decimal", "required": false, "description": "Hours carried from prior year" },
      { "name": "forfeited_hours", "type": "decimal", "required": false, "description": "Hours lost due to policy limits" },
      { "name": "adjustment_hours", "type": "decimal", "required": false, "description": "Manual adjustments (+/-)" },
      { "name": "max_carryover", "type": "decimal", "required": false, "description": "Maximum hours that can carry over" },
      { "name": "max_balance", "type": "decimal", "required": false, "description": "Maximum balance cap" },
      { "name": "last_accrual_date", "type": "date", "required": false, "description": "When last accrual occurred" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "LeaveType", "type": "many_to_one", "required": true },
      { "entity": "LeaveRequest", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.leave_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### LeaveType

```json
{
  "id": "data.leave_management.leave_type",
  "name": "Leave Type",
  "type": "data",
  "namespace": "leave_management",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Definition of a leave category and its accrual rules.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Leave type name (PTO, Sick, etc.)" },
      { "name": "code", "type": "string", "required": true, "description": "Short code for payroll" },
      { "name": "paid", "type": "boolean", "required": true, "description": "Whether leave is paid" },
      { "name": "accrual_type", "type": "enum", "required": true, "values": ["none", "per_pay_period", "annually", "monthly", "by_tenure"], "description": "How leave accrues" },
      { "name": "accrual_rate", "type": "decimal", "required": false, "description": "Hours accrued per period" },
      { "name": "max_balance", "type": "decimal", "required": false, "description": "Maximum balance cap (null = unlimited)" },
      { "name": "max_carryover", "type": "decimal", "required": false, "description": "Max hours to carry to next year" },
      { "name": "allows_negative", "type": "boolean", "required": false, "description": "Can balance go negative" },
      { "name": "max_negative", "type": "decimal", "required": false, "description": "Maximum negative balance allowed" },
      { "name": "requires_approval", "type": "boolean", "required": true, "description": "Needs manager approval" },
      { "name": "advance_notice_days", "type": "integer", "required": false, "description": "Minimum notice required" },
      { "name": "documentation_required", "type": "boolean", "required": false, "description": "Requires supporting docs" },
      { "name": "is_protected", "type": "boolean", "required": false, "description": "FMLA or legally protected" },
      { "name": "applies_to", "type": "array", "required": false, "description": "Employee types/groups eligible" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "inactive"], "description": "Whether type is active" }
    ],
    "relationships": [
      { "entity": "LeaveBalance", "type": "one_to_many", "required": false },
      { "entity": "LeaveRequest", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.leave_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### LeaveRequest

```json
{
  "id": "data.leave_management.leave_request",
  "name": "Leave Request",
  "type": "data",
  "namespace": "leave_management",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Employee request for time off.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee requesting leave" },
      { "name": "leave_type_id", "type": "uuid", "required": true, "description": "Type of leave requested" },
      { "name": "start_date", "type": "date", "required": true, "description": "First day of leave" },
      { "name": "end_date", "type": "date", "required": true, "description": "Last day of leave" },
      { "name": "start_half_day", "type": "boolean", "required": false, "description": "Start with half day" },
      { "name": "end_half_day", "type": "boolean", "required": false, "description": "End with half day" },
      { "name": "total_hours", "type": "decimal", "required": true, "description": "Total hours requested" },
      { "name": "reason", "type": "text", "required": false, "description": "Reason for leave" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending", "approved", "rejected", "canceled", "taken"], "description": "Request status" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When request was submitted" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "Manager who approved" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "Approval timestamp" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why request was rejected" },
      { "name": "cancellation_reason", "type": "text", "required": false, "description": "Why request was canceled" },
      { "name": "documentation_file", "type": "string", "required": false, "description": "Path to supporting doc if required" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "LeaveType", "type": "many_to_one", "required": true },
      { "entity": "LeaveBalance", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.leave_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Holiday

```json
{
  "id": "data.leave_management.holiday",
  "name": "Holiday",
  "type": "data",
  "namespace": "leave_management",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Company-observed holiday.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Holiday name" },
      { "name": "date", "type": "date", "required": true, "description": "Holiday date" },
      { "name": "observed_date", "type": "date", "required": false, "description": "Date observed if different" },
      { "name": "year", "type": "integer", "required": true, "description": "Calendar year" },
      { "name": "paid", "type": "boolean", "required": true, "description": "Paid holiday" },
      { "name": "hours", "type": "decimal", "required": false, "description": "Holiday hours credited" },
      { "name": "applies_to", "type": "array", "required": false, "description": "Employee groups eligible" },
      { "name": "location", "type": "string", "required": false, "description": "Specific location if regional" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.leave_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.leave_management.leave_request_approval

```yaml
workflow:
  id: "wf.leave_management.leave_request_approval"
  name: "Leave Request Approval"
  trigger: "Employee submits leave request"
  actors: ["Employee", "Manager", "HR", "System"]

  steps:
    - step: 1
      name: "Submit Request"
      actor: "Employee"
      action: "Create and submit leave request"
      inputs: ["Leave type", "Dates", "Reason"]
      outputs: ["Leave request"]

    - step: 2
      name: "Validate Request"
      actor: "System"
      action: "Check balance, blackout periods, conflicts, advance notice"
      inputs: ["Leave request", "Leave balance", "Calendar", "Policies"]
      outputs: ["Validation result", "Warnings"]
      automatable: true

    - step: 3a
      name: "Auto-Approve (if policy allows)"
      actor: "System"
      action: "Approve request that meets auto-approval criteria"
      inputs: ["Validated request", "Auto-approval rules"]
      outputs: ["Approved request"]
      condition: "Meets auto-approval criteria"
      automatable: true

    - step: 3b
      name: "Route to Manager"
      actor: "System"
      action: "Send request to manager for approval"
      inputs: ["Validated request"]
      outputs: ["Pending request notification"]
      condition: "Requires manager approval"
      automatable: true

    - step: 4
      name: "Manager Review"
      actor: "Manager"
      action: "Review request, check team coverage"
      inputs: ["Leave request", "Team calendar"]
      outputs: ["Approval decision"]
      decision_point: "Approve or reject?"

    - step: 5a
      name: "Approve Request"
      actor: "Manager"
      action: "Approve leave request"
      inputs: ["Leave request"]
      outputs: ["Approved request"]
      condition: "Manager approves"

    - step: 5b
      name: "Reject Request"
      actor: "Manager"
      action: "Reject with reason"
      inputs: ["Leave request", "Rejection reason"]
      outputs: ["Rejected request notification"]
      condition: "Manager rejects"

    - step: 6
      name: "Update Balance"
      actor: "System"
      action: "Deduct from available, add to pending"
      inputs: ["Approved request"]
      outputs: ["Updated leave balance"]
      automatable: true

    - step: 7
      name: "Calendar Integration"
      actor: "System"
      action: "Add to team calendar, block scheduling"
      inputs: ["Approved request"]
      outputs: ["Calendar entry"]
      automatable: true

    - step: 8
      name: "Notify Stakeholders"
      actor: "System"
      action: "Notify employee, team, and relevant parties"
      inputs: ["Final request status"]
      outputs: ["Notifications"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-HR-016 | **Leave request exceeds available balance** | Medium | Reject or allow negative with approval; show projected balance |
| EC-HR-017 | **Approved leave overlaps new blackout period** | Medium | Grandfather existing approvals; notify for review |
| EC-HR-018 | **Employee resigns with pending leave** | Low | Cancel pending; pay out per policy |
| EC-HR-019 | **FMLA eligibility determination** | High | Track hours worked, tenure; integration with HR |
| EC-HR-020 | **Year-end carryover calculation** | Medium | Run before year end; handle in-flight requests |
| EC-HR-021 | **Part-time employee leave proration** | Medium | Pro-rate based on FTE percentage |
| EC-HR-022 | **Sick leave with doctor's note required** | Low | Flag for documentation; allow conditional approval |
| EC-HR-023 | **Overlapping leave requests from same team** | Medium | Show coverage conflicts to manager during approval |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-HR-009 | **Optimal approval routing** | Request details, org chart, policies | Correct approver(s) | Ensures proper workflow |
| AI-HR-010 | **Coverage impact analysis** | Leave request, team calendar | Coverage risk assessment | Informed approval decisions |
| AI-HR-011 | **Leave pattern analysis** | Historical leave, upcoming requests | Staffing projections | Resource planning |
| AI-HR-012 | **Balance forecast** | Accrual rates, pending requests | Year-end projected balance | Helps employees plan |

---

## Package 4: Compliance

### Purpose

Manage employment-related documents and ensure compliance with federal, state, and local employment regulations. Track required forms, certifications, and deadlines.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What federal forms do you track? (I-9, W-4, W-2)
- Do employees have licenses or certifications that need renewal?
- What state-specific forms are required?
- Do you need to track training compliance?
- Are there industry-specific certifications?

**Workflow Discovery**:
- How are I-9s completed? (in-person, E-Verify)
- Who is responsible for document collection?
- How do you track expiring documents?
- What happens when certification expires?

**Edge Case Probing**:
- Employee cannot produce I-9 documents on time?
- Work authorization expires mid-employment?
- Employee moves to different state?

### Entity Templates

#### ComplianceDocument

```json
{
  "id": "data.compliance.compliance_document",
  "name": "Compliance Document",
  "type": "data",
  "namespace": "compliance",
  "tags": ["core-entity", "mvp", "pii-sensitive", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Employment-related document required for compliance.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee this document is for" },
      { "name": "document_type", "type": "enum", "required": true, "values": ["i9", "w4", "state_w4", "direct_deposit", "handbook_ack", "nda", "license", "certification", "background_check", "drug_test", "other"], "description": "Type of document" },
      { "name": "document_name", "type": "string", "required": true, "description": "Document name/title" },
      { "name": "status", "type": "enum", "required": true, "values": ["required", "pending", "submitted", "verified", "expired", "rejected"], "description": "Document status" },
      { "name": "required_by_date", "type": "date", "required": false, "description": "Deadline for submission" },
      { "name": "submitted_date", "type": "date", "required": false, "description": "When employee submitted" },
      { "name": "verified_date", "type": "date", "required": false, "description": "When HR verified" },
      { "name": "verified_by", "type": "uuid", "required": false, "description": "HR person who verified" },
      { "name": "expiration_date", "type": "date", "required": false, "description": "When document/cert expires" },
      { "name": "renewal_reminder_date", "type": "date", "required": false, "description": "When to send renewal reminder" },
      { "name": "file_path", "type": "string", "required": false, "description": "Storage path for document" },
      { "name": "notes", "type": "text", "required": false, "description": "Internal notes" },
      { "name": "section_2_due_date", "type": "date", "required": false, "description": "For I-9: Section 2 deadline (day 3)" },
      { "name": "everify_case_number", "type": "string", "required": false, "description": "E-Verify case number if applicable" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.compliance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Certification

```json
{
  "id": "data.compliance.certification",
  "name": "Certification",
  "type": "data",
  "namespace": "compliance",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Professional license or certification held by an employee.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee holding certification" },
      { "name": "certification_type_id", "type": "uuid", "required": true, "description": "Type of certification" },
      { "name": "certificate_number", "type": "string", "required": false, "description": "License/certificate number" },
      { "name": "issuing_authority", "type": "string", "required": true, "description": "Organization that issued" },
      { "name": "issue_date", "type": "date", "required": true, "description": "When issued/earned" },
      { "name": "expiration_date", "type": "date", "required": false, "description": "When it expires" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "expired", "revoked", "pending_renewal"], "description": "Current status" },
      { "name": "verification_url", "type": "string", "required": false, "description": "URL to verify certification" },
      { "name": "document_path", "type": "string", "required": false, "description": "Scanned certificate location" },
      { "name": "required_for_position", "type": "boolean", "required": false, "description": "Required for current job" },
      { "name": "notes", "type": "text", "required": false, "description": "Additional notes" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "CertificationType", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "hr_people.compliance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### CertificationType

```json
{
  "id": "data.compliance.certification_type",
  "name": "Certification Type",
  "type": "data",
  "namespace": "compliance",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Definition of a professional certification or license type.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Certification name (e.g., CPA, PMP)" },
      { "name": "category", "type": "string", "required": false, "description": "Category (medical, legal, technical)" },
      { "name": "issuing_authority", "type": "string", "required": false, "description": "Default issuing organization" },
      { "name": "renewal_period_months", "type": "integer", "required": false, "description": "Typical renewal period" },
      { "name": "renewal_reminder_days", "type": "integer", "required": false, "description": "Days before expiry to remind" },
      { "name": "required_for_positions", "type": "array", "required": false, "description": "Positions requiring this cert" },
      { "name": "continuing_education_required", "type": "boolean", "required": false, "description": "Requires CE credits" },
      { "name": "ce_hours_required", "type": "integer", "required": false, "description": "CE hours per renewal period" },
      { "name": "verification_process", "type": "text", "required": false, "description": "How to verify this cert" }
    ],
    "relationships": [
      { "entity": "Certification", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "hr_people.compliance",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.compliance.i9_completion

```yaml
workflow:
  id: "wf.compliance.i9_completion"
  name: "I-9 Form Completion"
  trigger: "New hire begins employment"
  actors: ["Employee", "HR", "System"]

  steps:
    - step: 1
      name: "Create I-9 Record"
      actor: "System"
      action: "Create compliance document record for I-9"
      inputs: ["New employee", "Start date"]
      outputs: ["I-9 compliance record with deadlines"]
      automatable: true

    - step: 2
      name: "Section 1 Completion (Day 1)"
      actor: "Employee"
      action: "Complete Section 1 on or before first day of work"
      inputs: ["Employee personal info"]
      outputs: ["Section 1 completed"]
      deadline: "Start date"

    - step: 3
      name: "Document Presentation (Day 1-3)"
      actor: "Employee"
      action: "Present acceptable identity and work auth documents"
      inputs: ["Original documents from List A, or List B + C"]
      outputs: ["Documents presented"]
      deadline: "Start date + 3 business days"

    - step: 4
      name: "Section 2 Verification"
      actor: "HR"
      action: "Examine documents, complete Section 2"
      inputs: ["Presented documents"]
      outputs: ["Section 2 completed", "Document copies"]
      deadline: "Start date + 3 business days"

    - step: 5
      name: "E-Verify Submission (if required)"
      actor: "HR"
      action: "Submit to E-Verify system"
      inputs: ["Completed I-9"]
      outputs: ["E-Verify case number", "Verification result"]
      condition: "Company uses E-Verify"
      deadline: "Start date + 3 business days"

    - step: 6
      name: "Store I-9"
      actor: "System"
      action: "Securely store completed I-9"
      inputs: ["Completed I-9", "Document copies"]
      outputs: ["Stored document record"]
      automatable: true

    - step: 7
      name: "Schedule Reverification (if applicable)"
      actor: "System"
      action: "Set reminder for work authorization expiration"
      inputs: ["Work auth expiration date"]
      outputs: ["Reverification reminder"]
      condition: "Work authorization has expiration"
      automatable: true
```

#### wf.compliance.certification_renewal

```yaml
workflow:
  id: "wf.compliance.certification_renewal"
  name: "Certification Renewal Tracking"
  trigger: "Certification approaches expiration"
  actors: ["Employee", "Manager", "HR", "System"]

  steps:
    - step: 1
      name: "Send Renewal Reminder"
      actor: "System"
      action: "Notify employee of upcoming expiration"
      inputs: ["Certification record", "Reminder settings"]
      outputs: ["Reminder notification"]
      automatable: true

    - step: 2
      name: "Employee Initiates Renewal"
      actor: "Employee"
      action: "Complete renewal requirements (CE, exam, fee)"
      inputs: ["Renewal requirements"]
      outputs: ["Renewal documentation"]

    - step: 3
      name: "Submit Renewal Proof"
      actor: "Employee"
      action: "Upload renewed certificate/license"
      inputs: ["Renewal documentation"]
      outputs: ["Updated certification record"]

    - step: 4
      name: "HR Verification"
      actor: "HR"
      action: "Verify renewed certification"
      inputs: ["Renewal documentation"]
      outputs: ["Verified certification"]

    - step: 5
      name: "Update Record"
      actor: "System"
      action: "Update expiration date, status"
      inputs: ["Verified certification"]
      outputs: ["Updated certification record"]
      automatable: true

    - step: 6
      name: "Handle Non-Renewal"
      actor: "HR"
      action: "If not renewed, escalate to manager"
      inputs: ["Expired certification", "Position requirements"]
      outputs: ["Escalation to manager", "Action plan"]
      condition: "Certification not renewed by expiration"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-HR-024 | **Employee cannot produce I-9 documents by day 3** | High | Document receipt in Section 2; complete within grace period; document good faith effort |
| EC-HR-025 | **Work authorization expires during employment** | High | Reverify before expiration; may need Section 3; cannot continue if expired |
| EC-HR-026 | **E-Verify tentative non-confirmation** | High | Follow E-Verify procedures; employee has right to contest; cannot terminate until resolved |
| EC-HR-027 | **Required certification expires without renewal** | Medium | Restrict from duties requiring cert; performance issue if intentional |
| EC-HR-028 | **Employee relocates to different state** | Medium | May need new state W-4; update tax withholding; check state-specific requirements |
| EC-HR-029 | **Document retention period for terminated employee** | Medium | I-9: 3 years from hire or 1 year from term, whichever later |
| EC-HR-030 | **Remote I-9 verification** | Medium | Use authorized representative; maintain audit trail; follow DHS guidance |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-HR-013 | **Document classification** | Uploaded document image | Document type, extracted data | Faster processing |
| AI-HR-014 | **Expiration forecasting** | All certifications, renewal times | Risk calendar | Proactive management |
| AI-HR-015 | **Compliance gap detection** | Employee roles, required certs | Missing/expiring requirements | Risk mitigation |
| AI-HR-016 | **I-9 document verification** | Document images | Acceptance/rejection likelihood | Assist HR review |

---

## Package 5: Onboarding & Offboarding

### Purpose

Manage the employee lifecycle transitions: bringing new hires into the organization smoothly and handling departures completely. Coordinate across HR, IT, facilities, and other departments.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What tasks must be completed for new hires? (paperwork, equipment, training)
- What systems need accounts provisioned? (email, VPN, apps)
- What equipment is assigned? (laptop, phone, badge)
- What training is required before starting work?

**Workflow Discovery**:
- How far in advance do you start onboarding?
- Who is responsible for each onboarding task?
- How long is the typical onboarding period?
- What exit interview process do you have?
- How do you handle knowledge transfer?

**Edge Case Probing**:
- New hire starts before all background checks clear?
- Employee gives no notice before leaving?
- Terminated employee is rehired?

### Entity Templates

#### OnboardingChecklist

```json
{
  "id": "data.onboarding.onboarding_checklist",
  "name": "Onboarding Checklist",
  "type": "data",
  "namespace": "onboarding",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Master checklist tracking all onboarding tasks for a new hire.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "New hire being onboarded" },
      { "name": "template_id", "type": "uuid", "required": false, "description": "Checklist template used" },
      { "name": "start_date", "type": "date", "required": true, "description": "Employee start date" },
      { "name": "status", "type": "enum", "required": true, "values": ["not_started", "in_progress", "completed", "canceled"], "description": "Overall onboarding status" },
      { "name": "completion_percentage", "type": "decimal", "required": false, "description": "Percent of tasks completed" },
      { "name": "target_completion_date", "type": "date", "required": false, "description": "When onboarding should finish" },
      { "name": "actual_completion_date", "type": "date", "required": false, "description": "When actually completed" },
      { "name": "hr_coordinator_id", "type": "uuid", "required": false, "description": "HR person managing onboarding" },
      { "name": "buddy_id", "type": "uuid", "required": false, "description": "Assigned onboarding buddy" },
      { "name": "notes", "type": "text", "required": false, "description": "Onboarding notes" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "OnboardingTask", "type": "one_to_many", "required": false },
      { "entity": "OnboardingTemplate", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.onboarding",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### OnboardingTask

```json
{
  "id": "data.onboarding.onboarding_task",
  "name": "Onboarding Task",
  "type": "data",
  "namespace": "onboarding",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual task in an onboarding checklist.",
    "fields": [
      { "name": "checklist_id", "type": "uuid", "required": true, "description": "Parent onboarding checklist" },
      { "name": "task_name", "type": "string", "required": true, "description": "Task description" },
      { "name": "category", "type": "enum", "required": true, "values": ["paperwork", "it_provisioning", "equipment", "training", "introductions", "compliance", "facilities", "other"], "description": "Task category" },
      { "name": "assigned_to_id", "type": "uuid", "required": false, "description": "Person responsible for task" },
      { "name": "assigned_department", "type": "enum", "required": false, "values": ["hr", "it", "facilities", "manager", "employee", "security"], "description": "Responsible department" },
      { "name": "due_date", "type": "date", "required": false, "description": "When task should be done" },
      { "name": "due_offset_days", "type": "integer", "required": false, "description": "Days relative to start date" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "in_progress", "completed", "blocked", "skipped"], "description": "Task status" },
      { "name": "completed_by", "type": "uuid", "required": false, "description": "Who completed the task" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When completed" },
      { "name": "blocked_reason", "type": "text", "required": false, "description": "Why task is blocked" },
      { "name": "notes", "type": "text", "required": false, "description": "Task notes" },
      { "name": "sort_order", "type": "integer", "required": false, "description": "Display order" },
      { "name": "is_required", "type": "boolean", "required": true, "description": "Must be completed" }
    ],
    "relationships": [
      { "entity": "OnboardingChecklist", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.onboarding",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### OffboardingChecklist

```json
{
  "id": "data.offboarding.offboarding_checklist",
  "name": "Offboarding Checklist",
  "type": "data",
  "namespace": "offboarding",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Master checklist tracking all offboarding tasks for a departing employee.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Departing employee" },
      { "name": "termination_type", "type": "enum", "required": true, "values": ["voluntary", "involuntary", "retirement", "layoff", "death", "contract_end"], "description": "Type of separation" },
      { "name": "last_day", "type": "date", "required": true, "description": "Employee's last working day" },
      { "name": "termination_date", "type": "date", "required": true, "description": "Official termination date" },
      { "name": "status", "type": "enum", "required": true, "values": ["not_started", "in_progress", "completed"], "description": "Offboarding status" },
      { "name": "eligible_for_rehire", "type": "boolean", "required": false, "description": "Can be rehired" },
      { "name": "exit_interview_completed", "type": "boolean", "required": false, "description": "Exit interview done" },
      { "name": "exit_interview_date", "type": "date", "required": false, "description": "When exit interview occurred" },
      { "name": "exit_interview_notes", "type": "text", "required": false, "description": "Exit interview summary" },
      { "name": "final_pay_date", "type": "date", "required": false, "description": "When final paycheck issued" },
      { "name": "pto_payout_hours", "type": "decimal", "required": false, "description": "PTO hours to pay out" },
      { "name": "hr_coordinator_id", "type": "uuid", "required": false, "description": "HR person managing offboarding" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true },
      { "entity": "OffboardingTask", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.offboarding",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### OffboardingTask

```json
{
  "id": "data.offboarding.offboarding_task",
  "name": "Offboarding Task",
  "type": "data",
  "namespace": "offboarding",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual task in an offboarding checklist.",
    "fields": [
      { "name": "checklist_id", "type": "uuid", "required": true, "description": "Parent offboarding checklist" },
      { "name": "task_name", "type": "string", "required": true, "description": "Task description" },
      { "name": "category", "type": "enum", "required": true, "values": ["access_revocation", "equipment_return", "knowledge_transfer", "final_pay", "benefits", "exit_interview", "notifications", "other"], "description": "Task category" },
      { "name": "assigned_to_id", "type": "uuid", "required": false, "description": "Person responsible" },
      { "name": "assigned_department", "type": "enum", "required": false, "values": ["hr", "it", "facilities", "manager", "employee", "security", "payroll"], "description": "Responsible department" },
      { "name": "due_date", "type": "date", "required": false, "description": "When task should be done" },
      { "name": "due_timing", "type": "enum", "required": false, "values": ["before_last_day", "on_last_day", "after_last_day"], "description": "Relative timing" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "in_progress", "completed", "blocked", "not_applicable"], "description": "Task status" },
      { "name": "completed_by", "type": "uuid", "required": false, "description": "Who completed" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When completed" },
      { "name": "notes", "type": "text", "required": false, "description": "Task notes" },
      { "name": "is_required", "type": "boolean", "required": true, "description": "Must be completed" },
      { "name": "is_time_sensitive", "type": "boolean", "required": false, "description": "Must be done immediately on trigger" }
    ],
    "relationships": [
      { "entity": "OffboardingChecklist", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "hr_people.offboarding",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### EquipmentAssignment

```json
{
  "id": "data.onboarding.equipment_assignment",
  "name": "Equipment Assignment",
  "type": "data",
  "namespace": "onboarding",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Track equipment assigned to employees.",
    "fields": [
      { "name": "employee_id", "type": "uuid", "required": true, "description": "Employee with equipment" },
      { "name": "equipment_type", "type": "enum", "required": true, "values": ["laptop", "desktop", "monitor", "phone", "mobile", "badge", "keys", "vehicle", "other"], "description": "Type of equipment" },
      { "name": "asset_tag", "type": "string", "required": false, "description": "Asset tracking number" },
      { "name": "serial_number", "type": "string", "required": false, "description": "Manufacturer serial" },
      { "name": "description", "type": "string", "required": true, "description": "Equipment description" },
      { "name": "assigned_date", "type": "date", "required": true, "description": "When assigned" },
      { "name": "returned_date", "type": "date", "required": false, "description": "When returned" },
      { "name": "status", "type": "enum", "required": true, "values": ["assigned", "returned", "lost", "damaged"], "description": "Current status" },
      { "name": "condition_on_return", "type": "enum", "required": false, "values": ["good", "fair", "damaged", "missing_parts"], "description": "Condition when returned" },
      { "name": "notes", "type": "text", "required": false, "description": "Equipment notes" }
    ],
    "relationships": [
      { "entity": "Employee", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "hr_people.onboarding",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.onboarding.new_hire_onboarding

```yaml
workflow:
  id: "wf.onboarding.new_hire_onboarding"
  name: "New Hire Onboarding"
  trigger: "Offer accepted, start date confirmed"
  actors: ["HR", "Manager", "IT", "Facilities", "Employee", "System"]

  steps:
    - step: 1
      name: "Create Onboarding Checklist"
      actor: "System"
      action: "Generate checklist from template based on role"
      inputs: ["Employee record", "Position", "Department"]
      outputs: ["Onboarding checklist with tasks"]
      automatable: true

    - step: 2
      name: "Pre-Boarding Tasks (Before Day 1)"
      actor: "HR"
      action: "Send welcome packet, collect paperwork"
      inputs: ["Employee contact info"]
      outputs: ["Signed offer letter", "Personal info forms"]

    - step: 3
      name: "IT Provisioning"
      actor: "IT"
      action: "Create accounts, prepare equipment"
      inputs: ["Employee info", "Role requirements"]
      outputs: ["Email account", "System access", "Laptop/equipment"]
      deadline: "Start date - 1 day"

    - step: 4
      name: "Facilities Setup"
      actor: "Facilities"
      action: "Prepare workspace, badge, parking"
      inputs: ["Work location", "Start date"]
      outputs: ["Desk assignment", "Building access"]
      deadline: "Start date"

    - step: 5
      name: "Day 1: Compliance Documents"
      actor: "HR"
      action: "Complete I-9 Section 1, W-4, direct deposit"
      inputs: ["New hire"]
      outputs: ["Completed compliance docs"]
      deadline: "Start date"

    - step: 6
      name: "Day 1: Welcome and Orientation"
      actor: "HR"
      action: "Company overview, policies, introductions"
      inputs: ["New hire"]
      outputs: ["Orientation completed"]
      deadline: "Start date"

    - step: 7
      name: "Days 1-3: I-9 Section 2"
      actor: "HR"
      action: "Verify identity and work authorization documents"
      inputs: ["Employee documents"]
      outputs: ["Completed I-9"]
      deadline: "Start date + 3 business days"

    - step: 8
      name: "Week 1: Manager Onboarding"
      actor: "Manager"
      action: "Role expectations, team intro, initial training"
      inputs: ["New hire"]
      outputs: ["Training plan", "Initial goals"]

    - step: 9
      name: "First Month: Training Completion"
      actor: "Employee"
      action: "Complete required training modules"
      inputs: ["Training requirements"]
      outputs: ["Training certificates"]

    - step: 10
      name: "30/60/90 Day Check-ins"
      actor: "Manager"
      action: "Progress reviews and feedback"
      inputs: ["Employee progress", "Initial goals"]
      outputs: ["Check-in records"]

    - step: 11
      name: "Close Onboarding"
      actor: "HR"
      action: "Mark onboarding complete, file all documents"
      inputs: ["Completed checklist"]
      outputs: ["Completed onboarding record"]
```

#### wf.offboarding.employee_offboarding

```yaml
workflow:
  id: "wf.offboarding.employee_offboarding"
  name: "Employee Offboarding"
  trigger: "Resignation received or termination initiated"
  actors: ["HR", "Manager", "IT", "Facilities", "Payroll", "Employee", "System"]

  steps:
    - step: 1
      name: "Create Offboarding Checklist"
      actor: "System"
      action: "Generate checklist based on termination type"
      inputs: ["Employee", "Termination type", "Last day"]
      outputs: ["Offboarding checklist"]
      automatable: true

    - step: 2
      name: "Notify Stakeholders"
      actor: "HR"
      action: "Inform IT, facilities, payroll, relevant teams"
      inputs: ["Employee", "Last day", "Termination type"]
      outputs: ["Stakeholder notifications"]

    - step: 3
      name: "Knowledge Transfer"
      actor: "Employee"
      action: "Document processes, transfer responsibilities"
      inputs: ["Role responsibilities"]
      outputs: ["Knowledge transfer docs", "Handoff meetings"]
      condition: "If voluntary with notice period"

    - step: 4
      name: "Exit Interview"
      actor: "HR"
      action: "Conduct exit interview"
      inputs: ["Employee"]
      outputs: ["Exit interview notes"]
      condition: "If voluntary separation"

    - step: 5
      name: "Final Timesheet"
      actor: "Manager"
      action: "Approve final hours worked"
      inputs: ["Last timesheet"]
      outputs: ["Approved final hours"]

    - step: 6
      name: "Calculate Final Pay"
      actor: "Payroll"
      action: "Calculate wages, PTO payout, deductions"
      inputs: ["Final hours", "PTO balance", "Deductions"]
      outputs: ["Final paycheck amount"]

    - step: 7
      name: "Equipment Collection"
      actor: "IT"
      action: "Collect laptop, phone, other equipment"
      inputs: ["Equipment assignment list"]
      outputs: ["Returned equipment", "Updated asset records"]
      deadline: "Last day"

    - step: 8
      name: "Access Revocation"
      actor: "IT"
      action: "Disable all system access"
      inputs: ["Employee accounts"]
      outputs: ["Disabled accounts"]
      deadline: "Last day (involuntary) or day after (voluntary)"

    - step: 9
      name: "Badge and Keys Return"
      actor: "Facilities"
      action: "Collect building access items"
      inputs: ["Access items list"]
      outputs: ["Returned items"]
      deadline: "Last day"

    - step: 10
      name: "Benefits Notification"
      actor: "HR"
      action: "Send COBRA info, benefits termination details"
      inputs: ["Employee", "Benefits enrollment"]
      outputs: ["COBRA notice", "Benefits summary"]

    - step: 11
      name: "Final Paycheck"
      actor: "Payroll"
      action: "Issue final paycheck per state requirements"
      inputs: ["Final pay calculation", "State laws"]
      outputs: ["Final paycheck"]

    - step: 12
      name: "Update Employee Record"
      actor: "System"
      action: "Mark terminated, record separation details"
      inputs: ["Offboarding checklist"]
      outputs: ["Updated employee record"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-HR-031 | **New hire starts before background check clears** | High | Define policy: conditional start, restricted access, or delay start |
| EC-HR-032 | **Employee terminates with no notice** | Medium | Expedite offboarding; prioritize access revocation and equipment |
| EC-HR-033 | **Terminated employee has approved future leave** | Low | Cancel leave requests; do not count against balance |
| EC-HR-034 | **Equipment not returned by terminated employee** | Medium | Document; deduct from final pay if legal; consider legal action |
| EC-HR-035 | **Involuntary termination requires immediate departure** | High | Pre-plan IT disable; escort off premises; ship personal items |
| EC-HR-036 | **Remote employee onboarding** | Medium | Ship equipment; virtual orientation; remote I-9 via authorized rep |
| EC-HR-037 | **Employee death** | High | Sensitive handling; contact beneficiary; expedite final pay |
| EC-HR-038 | **Rehire of former employee** | Medium | Check eligibility; link to prior records; may need new I-9 |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-HR-017 | **Onboarding task prediction** | Role, department, location | Suggested checklist tasks | Role-appropriate onboarding |
| AI-HR-018 | **Bottleneck detection** | Onboarding progress, task status | Blocking issues identified | Faster onboarding |
| AI-HR-019 | **Exit interview analysis** | Exit interview notes | Themes, sentiment, recommendations | Retention insights |
| AI-HR-020 | **Knowledge gap identification** | Departing role, team docs | Knowledge transfer priorities | Minimize knowledge loss |

---

## Cross-Package Relationships

The HR/People module packages interconnect through the central Employee Graph:

```
                         ┌─────────────────────────────────────┐
                         │           EMPLOYEE                   │
                         │     (Central Hub Entity)             │
                         └────────────────┬────────────────────┘
                                          │
          ┌───────────────────┬───────────┼───────────┬───────────────────┐
          │                   │           │           │                   │
          ▼                   ▼           ▼           ▼                   ▼
┌─────────────────┐  ┌────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  EMPLOYEE MGMT  │  │ TIME/ATTENDANCE│  │ LEAVE MANAGEMENT│  │   COMPLIANCE    │
│  - Department   │  │  - TimeEntry   │  │  - LeaveBalance │  │  - I-9, W-4     │
│  - Position     │  │  - PayPeriod   │  │  - LeaveRequest │  │  - Certificates │
│  - Emergency    │  │  - Schedule    │  │  - LeaveType    │  │  - Documents    │
│    Contact      │  │               │  │  - Holiday      │  │                 │
└─────────────────┘  └────────────────┘  └─────────────────┘  └─────────────────┘
                              │                   │
                              │                   │
                              ▼                   ▼
                    ┌─────────────────────────────────────────┐
                    │        ONBOARDING / OFFBOARDING         │
                    │  - OnboardingChecklist                   │
                    │  - OffboardingChecklist                  │
                    │  - EquipmentAssignment                   │
                    └─────────────────────────────────────────┘
```

### Key Integration Points Within HR/People

| From | To | Integration |
|------|-----|-------------|
| Employee Management | All Packages | Employee record is foreign key for all HR data |
| Time & Attendance | Leave Management | Leave hours appear as time entries |
| Leave Management | Time & Attendance | Approved leave blocks scheduling |
| Compliance | Onboarding | I-9, W-4 are onboarding tasks |
| Onboarding | Employee Management | Completes employee record setup |
| Offboarding | All Packages | Triggers cleanup across all employee data |

---

## Integration Points (External Systems)

### Payroll Providers (CRITICAL - Do Not Build Payroll)

| System | Use Case | Notes |
|--------|----------|-------|
| **ADP** | Enterprise payroll | Most feature-rich; complex integration |
| **Gusto** | SMB payroll | Developer-friendly API; good for startups |
| **Paychex** | Mid-market payroll | Strong compliance features |
| **Paylocity** | HR + Payroll | Integrated platform |
| **Rippling** | HR + IT + Payroll | Modern all-in-one |

**Integration Pattern**: Export approved time data; import pay stubs and tax docs; sync employee demographics.

### Benefits Administration

| System | Use Case | Notes |
|--------|----------|-------|
| **Benefitfocus** | Benefits enrollment | Large enterprise |
| **Ease** | SMB benefits | Simple interface |
| **Employee Navigator** | Broker-focused | Good for benefit brokers |
| **Carrier Direct** | Insurance carriers | Direct to health/dental/vision |

### IT Provisioning

| System | Use Case | Notes |
|--------|----------|-------|
| **Active Directory** | Account provisioning | On-prem Windows |
| **Okta** | Identity management | Cloud-first SSO |
| **Google Workspace** | Email/calendar | G Suite admin API |
| **Microsoft 365** | Email/Office apps | Azure AD integration |
| **Jamf** | Mac device management | Apple device provisioning |

### Background Checks

| System | Use Case | Notes |
|--------|----------|-------|
| **Checkr** | Background screening | Modern API |
| **Sterling** | Comprehensive screening | Enterprise |
| **GoodHire** | SMB-focused | Simple integration |

### E-Verify

| System | Use Case | Notes |
|--------|----------|-------|
| **E-Verify (USCIS)** | Work authorization | Federal requirement for some employers |

---

## Compliance Considerations

### FLSA (Fair Labor Standards Act)

**Applies to**: All US employees

| Requirement | Implementation |
|-------------|----------------|
| Minimum wage | Validate pay rates meet federal/state minimum |
| Overtime (non-exempt) | Track hours; calculate OT at 1.5x after 40 hrs/week |
| Record keeping | Maintain time records for 3 years |
| Child labor | Verify age; restrict hours for minors |

**California Specific**: Daily overtime (8 hrs), double time (12 hrs), 7th day rules.

### I-9 Compliance

| Requirement | Deadline |
|-------------|----------|
| Section 1 | On or before first day of work |
| Section 2 | Within 3 business days of start |
| E-Verify (if required) | Within 3 business days of hire |
| Retention | 3 years from hire OR 1 year from termination (whichever later) |
| Reverification | Before work authorization expires |

### State-Specific Requirements

| State | Notable Requirements |
|-------|---------------------|
| **California** | Daily OT, meal/rest breaks, pay transparency |
| **New York** | NY HERO Act, pay frequency, final pay timing |
| **Illinois** | BIPA (biometrics), pay data reporting |
| **Colorado** | Equal Pay Act, pay transparency in postings |
| **Massachusetts** | Pay equity, earned sick time |

### FMLA (Family and Medical Leave Act)

**Applies to**: Employers with 50+ employees within 75 miles

| Requirement | Notes |
|-------------|-------|
| Eligibility | 12 months employed, 1,250 hours worked |
| Leave amount | Up to 12 weeks unpaid per year |
| Job protection | Must restore to same or equivalent position |
| Benefits continuation | Maintain health coverage during leave |

### Data Privacy

| Regulation | Scope | Key Requirements |
|------------|-------|------------------|
| CCPA/CPRA | California employees | Right to know, delete, opt-out |
| GDPR | EU employees | Consent, data minimization, right to erasure |
| State privacy laws | Various | Growing patchwork of state requirements |

**Best Practices**:
- Encrypt PII at rest and in transit
- Implement role-based access
- Maintain audit logs
- Document data retention and deletion

---

## Anti-Patterns to Avoid

### 1. Building a Payroll Engine

**Why to avoid**: Tax tables change constantly, multi-state withholding is complex, garnishment rules vary by jurisdiction, mistakes are costly and legally risky.

**Do instead**: Integrate with established payroll providers.

### 2. Complex Approval Workflows from Day One

**Why to avoid**: Business processes evolve; over-engineered workflows become rigid and frustrating.

**Do instead**: Start with simple manager approval; add complexity only when proven needed.

### 3. Matrix Organizations Initially

**Why to avoid**: Dual reporting, dotted lines, and project-based assignments add significant complexity.

**Do instead**: Start with single reporting line; add project assignments as a separate concept.

### 4. Storing Full SSN

**Why to avoid**: Major security liability; rarely needed for business operations.

**Do instead**: Store last 4 for verification; use payroll integration for full SSN when needed for tax purposes.

### 5. Manual Compliance Tracking

**Why to avoid**: Deadlines are legally mandated; manual tracking leads to violations.

**Do instead**: Automate deadline calculation and reminders from day one.

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Employee Management | Employee, Department, Position | EmergencyContact |
| Time & Attendance | TimeEntry, PayPeriod | Schedule |
| Leave Management | LeaveBalance, LeaveRequest | LeaveType, Holiday |
| Compliance | ComplianceDocument, Certification | CertificationType |
| Onboarding/Offboarding | OnboardingChecklist, OffboardingChecklist | OnboardingTask, OffboardingTask, EquipmentAssignment |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.employee_management.internal_transfer | Internal Transfer or Promotion | Manager/HR initiates |
| wf.time_attendance.timesheet_approval | Timesheet Submission and Approval | Pay period deadline |
| wf.time_attendance.missed_punch_correction | Missed Punch Correction | Employee reports |
| wf.leave_management.leave_request_approval | Leave Request Approval | Employee submits request |
| wf.compliance.i9_completion | I-9 Form Completion | New hire starts |
| wf.compliance.certification_renewal | Certification Renewal | Expiration approaches |
| wf.onboarding.new_hire_onboarding | New Hire Onboarding | Offer accepted |
| wf.offboarding.employee_offboarding | Employee Offboarding | Resignation/termination |

### Common Edge Case Themes

1. **Employee lifecycle transitions** - Rehires, transfers, terminations with pending items
2. **Compliance deadlines** - I-9 day 3, state-specific requirements
3. **Multi-state complexity** - Different overtime, leave, tax rules
4. **Time calculation edge cases** - Midnight spans, timezone differences, meal breaks
5. **Leave balance math** - Carryover limits, negative balances, proration
6. **Access timing** - When to provision/revoke for various termination types
7. **Protected leave** - FMLA, ADA accommodations, state leave laws

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
