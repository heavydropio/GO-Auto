# Compliance Module Catalog

**Module**: Compliance
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Compliance module provides audit logging, policy management, evidence collection, and regulatory framework tracking. This module establishes immutable audit trails with hash-chain integrity, manages policy acknowledgments, and prepares organizations for internal and external audits.

### Core Principle: Append-Only Audit Log

The foundation of this module is an **append-only audit log with hash chain integrity**. Every auditable action in the system writes to this log, and each entry includes a hash of the previous entry, creating a tamper-evident chain. This approach provides:

- **Immutability** - Entries cannot be modified after creation
- **Integrity verification** - Chain breaks indicate tampering
- **Complete history** - All changes are preserved forever
- **Regulatory compliance** - Meets audit trail requirements across frameworks

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "audit trail", "audit log", "compliance" | Compliance Officer, Auditor | Track all system changes with integrity |
| "SOC2", "HIPAA", "GDPR", "PCI-DSS", "ISO27001" | Compliance team, Legal | Meet specific regulatory requirements |
| "policy", "policy acknowledgment", "attestation" | HR, Compliance Officer | Distribute and track policy acceptance |
| "evidence", "evidence collection", "audit prep" | Compliance team, Auditor | Gather proof of controls for audits |
| "regulatory", "framework", "controls" | GRC team, Management | Map controls to regulatory requirements |

### Module Dependencies

```
Compliance Module
├── REQUIRES: Administrative (for user management, settings)
├── REQUIRES: Documents (for policy documents, evidence attachments)
├── INTEGRATES_WITH: All Modules (via AuditableMixin pattern)
├── INTEGRATES_WITH: Financial (SOX compliance, payment audit trails)
├── INTEGRATES_WITH: Security (access logs, incident records)
```

---

## Packages

This module contains 5 packages:

1. **audit_logging** - Immutable, hash-chained audit trail for all system actions
2. **compliance_tracking** - Monitor compliance status against requirements
3. **policy_management** - Create, distribute, and track policy acknowledgments
4. **evidence_collection** - Gather and organize evidence for audits
5. **audit_preparation** - Prepare for and manage internal/external audits

---

## Package 1: Audit Logging

### Purpose

Capture every significant action in the system with an immutable, hash-chained log that provides tamper-evident audit trails for regulatory compliance and forensic analysis.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What actions must be logged? (data changes, access, authentication)
- How long must audit logs be retained? (7 years, indefinitely)
- What level of detail is required? (field-level, record-level)
- Do you need real-time audit log monitoring?
- What user context must be captured? (IP, device, session)

**Workflow Discovery**:
- Who reviews audit logs? (Security, Compliance, Management)
- How often are logs reviewed? (real-time alerts, daily, periodic)
- What triggers an audit log investigation?
- How are suspicious activities escalated?
- What reporting is required from audit logs?

**Edge Case Probing**:
- What if the hash chain is broken?
- How do you handle system-generated vs user-initiated actions?
- What if audit logging fails during a transaction?
- How do you handle bulk operations in audit logs?

### Entity Templates

#### AuditLog

```json
{
  "id": "data.audit_logging.audit_log",
  "name": "Audit Log Entry",
  "type": "data",
  "namespace": "audit_logging",
  "tags": ["core-entity", "mvp", "immutable"],
  "status": "discovered",

  "spec": {
    "purpose": "Immutable record of a system action with hash chain integrity.",
    "fields": [
      { "name": "entry_id", "type": "uuid", "required": true, "description": "Unique identifier for this entry" },
      { "name": "sequence_number", "type": "bigint", "required": true, "description": "Monotonically increasing sequence" },
      { "name": "timestamp", "type": "datetime", "required": true, "description": "When action occurred (UTC)" },
      { "name": "actor_id", "type": "uuid", "required": true, "description": "User or system that performed action" },
      { "name": "actor_type", "type": "enum", "required": true, "values": ["user", "system", "api_client", "service_account"], "description": "Type of actor" },
      { "name": "action", "type": "enum", "required": true, "values": ["create", "read", "update", "delete", "login", "logout", "access_denied", "export", "approve", "reject"], "description": "Action performed" },
      { "name": "resource_type", "type": "string", "required": true, "description": "Entity type affected (e.g., Invoice, User)" },
      { "name": "resource_id", "type": "uuid", "required": true, "description": "ID of affected resource" },
      { "name": "changes", "type": "json", "required": false, "description": "Before/after values for updates" },
      { "name": "context", "type": "json", "required": false, "description": "Additional context (IP, user agent, session)" },
      { "name": "previous_hash", "type": "string", "required": true, "description": "SHA-256 hash of previous entry" },
      { "name": "entry_hash", "type": "string", "required": true, "description": "SHA-256 hash of this entry" },
      { "name": "classification", "type": "enum", "required": false, "values": ["routine", "sensitive", "critical", "security"], "description": "Sensitivity level" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": false },
      { "entity": "AuditLogVerification", "type": "one_to_many", "required": false }
    ],
    "notes": "APPEND-ONLY: No updates or deletes allowed. Hash chain must be verified periodically."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.audit_logging",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### AuditLogVerification

```json
{
  "id": "data.audit_logging.audit_log_verification",
  "name": "Audit Log Verification",
  "type": "data",
  "namespace": "audit_logging",
  "tags": ["core-entity", "integrity"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of hash chain integrity verification runs.",
    "fields": [
      { "name": "verification_id", "type": "uuid", "required": true, "description": "Unique verification run ID" },
      { "name": "started_at", "type": "datetime", "required": true, "description": "When verification started" },
      { "name": "completed_at", "type": "datetime", "required": false, "description": "When verification completed" },
      { "name": "start_sequence", "type": "bigint", "required": true, "description": "First sequence number verified" },
      { "name": "end_sequence", "type": "bigint", "required": true, "description": "Last sequence number verified" },
      { "name": "entries_verified", "type": "integer", "required": true, "description": "Total entries checked" },
      { "name": "status", "type": "enum", "required": true, "values": ["running", "passed", "failed", "error"], "description": "Verification result" },
      { "name": "first_break_sequence", "type": "bigint", "required": false, "description": "Sequence where chain broke (if failed)" },
      { "name": "error_details", "type": "text", "required": false, "description": "Error information if failed" },
      { "name": "verified_by", "type": "uuid", "required": true, "description": "User or system that ran verification" }
    ],
    "relationships": [
      { "entity": "AuditLog", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.audit_logging",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### AuditableMixin

```json
{
  "id": "pattern.audit_logging.auditable_mixin",
  "name": "Auditable Mixin",
  "type": "pattern",
  "namespace": "audit_logging",
  "tags": ["integration-pattern", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Pattern for integrating any entity with the audit log system.",
    "fields": [
      { "name": "created_at", "type": "datetime", "required": true, "description": "Record creation timestamp" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "User who created record" },
      { "name": "updated_at", "type": "datetime", "required": true, "description": "Last modification timestamp" },
      { "name": "updated_by", "type": "uuid", "required": true, "description": "User who last modified" },
      { "name": "version", "type": "integer", "required": true, "description": "Optimistic locking version" }
    ],
    "implementation_notes": "Every auditable entity inherits these fields. On save, the system automatically writes to AuditLog with before/after state."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.audit_logging",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.audit_logging.log_action

```yaml
workflow:
  id: "wf.audit_logging.log_action"
  name: "Log Auditable Action"
  trigger: "Any create, update, delete, or access on auditable entity"
  actors: ["System"]

  steps:
    - step: 1
      name: "Capture Action Context"
      actor: "System"
      action: "Gather actor, timestamp, resource, changes"
      inputs: ["Action details", "User context", "Before/after state"]
      outputs: ["Raw audit data"]
      automatable: true

    - step: 2
      name: "Get Previous Hash"
      actor: "System"
      action: "Retrieve hash of most recent log entry"
      inputs: ["Latest sequence number"]
      outputs: ["Previous entry hash"]
      automatable: true

    - step: 3
      name: "Compute Entry Hash"
      actor: "System"
      action: "Calculate SHA-256 of entry including previous hash"
      inputs: ["Raw audit data", "Previous hash"]
      outputs: ["Entry hash"]
      automatable: true

    - step: 4
      name: "Write Log Entry"
      actor: "System"
      action: "Append entry to audit log (atomic with main transaction)"
      inputs: ["Complete audit entry"]
      outputs: ["Persisted log entry"]
      automatable: true

    - step: 5
      name: "Classify and Alert"
      actor: "System"
      action: "Check classification rules, trigger alerts if needed"
      inputs: ["Log entry", "Alert rules"]
      outputs: ["Alerts (if triggered)"]
      automatable: true
      condition: "Entry matches alert criteria"
```

#### wf.audit_logging.verify_chain

```yaml
workflow:
  id: "wf.audit_logging.verify_chain"
  name: "Verify Audit Log Integrity"
  trigger: "Scheduled or on-demand"
  actors: ["System", "Compliance Officer"]

  steps:
    - step: 1
      name: "Initialize Verification"
      actor: "System"
      action: "Create verification record, determine range to verify"
      inputs: ["Last verified sequence", "Current sequence"]
      outputs: ["Verification record"]
      automatable: true

    - step: 2
      name: "Iterate and Verify"
      actor: "System"
      action: "For each entry, recompute hash and compare"
      inputs: ["Entries in range"]
      outputs: ["Verification results per entry"]
      automatable: true

    - step: 3a
      name: "Record Success"
      actor: "System"
      action: "Mark verification as passed"
      inputs: ["All hashes match"]
      outputs: ["Passed verification record"]
      condition: "No breaks found"
      automatable: true

    - step: 3b
      name: "Record Failure and Alert"
      actor: "System"
      action: "Record break location, alert compliance team"
      inputs: ["Break details"]
      outputs: ["Failed verification record", "Critical alert"]
      condition: "Chain break detected"
      automatable: true

    - step: 4
      name: "Investigate Break"
      actor: "Compliance Officer"
      action: "Review break, determine cause, document findings"
      inputs: ["Break location", "Surrounding entries"]
      outputs: ["Investigation report"]
      condition: "Verification failed"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-CMP-001 | **Hash chain break detected** | Critical | Isolate affected range; forensic analysis; restore from backup if tampering confirmed |
| EC-CMP-002 | **Audit log write fails during transaction** | High | Transaction must fail; audit log and business data must be atomic |
| EC-CMP-003 | **Bulk operation generates thousands of log entries** | Medium | Batch write with single chain link; summarize in one entry if appropriate |
| EC-CMP-004 | **System clock manipulation suspected** | High | Use NTP with multiple sources; flag entries with timestamp anomalies |
| EC-CMP-005 | **Actor cannot be determined** | Medium | Use "system" actor; flag for review; investigate authentication gaps |
| EC-CMP-006 | **Sensitive data in audit log changes** | High | Mask/redact sensitive fields; store reference instead of value |
| EC-CMP-007 | **Log storage approaching capacity** | Medium | Archive to cold storage; maintain chain continuity; never delete |
| EC-CMP-008 | **Concurrent writes create sequence gap** | Medium | Use database sequences; handle gaps gracefully in verification |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CMP-001 | **Anomaly detection** | Audit log patterns | Unusual activity alerts | Identifies potential security incidents |
| AI-CMP-002 | **Log classification** | Entry content | Sensitivity classification | Automates entry categorization |
| AI-CMP-003 | **Investigation assistance** | Log entries, query | Related entries, timeline | Speeds forensic analysis |
| AI-CMP-004 | **Natural language queries** | "Show all changes to invoices over $10k last month" | Filtered log results | Accessible audit log search |

---

## Package 2: Compliance Tracking

### Purpose

Monitor and report on compliance status against regulatory requirements, track control implementation, and manage compliance gaps.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- Which regulatory frameworks apply? (SOC2, HIPAA, GDPR, PCI-DSS, ISO27001)
- How do you track compliance requirements?
- What constitutes a compliant vs non-compliant state?
- Do you need multi-framework mapping (one control satisfies multiple requirements)?
- How frequently must compliance be assessed?

**Workflow Discovery**:
- Who is responsible for compliance assessments?
- How are compliance gaps identified and remediated?
- What triggers a compliance review?
- How is compliance status reported to management?
- What happens when compliance status changes?

**Edge Case Probing**:
- What if a control is partially compliant?
- How do you handle conflicting requirements across frameworks?
- What if compliance evidence expires?
- How do you track exceptions and compensating controls?

### Entity Templates

#### ComplianceRequirement

```json
{
  "id": "data.compliance_tracking.compliance_requirement",
  "name": "Compliance Requirement",
  "type": "data",
  "namespace": "compliance_tracking",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A specific regulatory or framework requirement that must be satisfied.",
    "fields": [
      { "name": "requirement_id", "type": "string", "required": true, "description": "Framework-specific ID (e.g., SOC2-CC6.1)" },
      { "name": "framework", "type": "enum", "required": true, "values": ["SOC2", "HIPAA", "GDPR", "PCI-DSS", "ISO27001", "NIST", "CCPA", "custom"], "description": "Regulatory framework" },
      { "name": "category", "type": "string", "required": true, "description": "Requirement category (e.g., Access Control)" },
      { "name": "title", "type": "string", "required": true, "description": "Short requirement title" },
      { "name": "description", "type": "text", "required": true, "description": "Full requirement description" },
      { "name": "control_type", "type": "enum", "required": true, "values": ["preventive", "detective", "corrective"], "description": "Type of control required" },
      { "name": "evidence_types", "type": "array", "required": false, "description": "Types of evidence that satisfy this requirement" },
      { "name": "assessment_frequency", "type": "enum", "required": true, "values": ["continuous", "daily", "weekly", "monthly", "quarterly", "annually"], "description": "How often to assess" },
      { "name": "owner_id", "type": "uuid", "required": false, "description": "Person responsible for this requirement" },
      { "name": "active", "type": "boolean", "required": true, "description": "Whether requirement is currently applicable" }
    ],
    "relationships": [
      { "entity": "ComplianceStatus", "type": "one_to_many", "required": false },
      { "entity": "Evidence", "type": "many_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.compliance_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ComplianceStatus

```json
{
  "id": "data.compliance_tracking.compliance_status",
  "name": "Compliance Status",
  "type": "data",
  "namespace": "compliance_tracking",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Current compliance state for a specific requirement.",
    "fields": [
      { "name": "requirement_id", "type": "uuid", "required": true, "description": "Linked compliance requirement" },
      { "name": "status", "type": "enum", "required": true, "values": ["compliant", "non_compliant", "partial", "not_assessed", "not_applicable", "exception_granted"], "description": "Current compliance state" },
      { "name": "assessed_at", "type": "datetime", "required": true, "description": "When status was last assessed" },
      { "name": "assessed_by", "type": "uuid", "required": true, "description": "Who performed assessment" },
      { "name": "next_assessment_due", "type": "date", "required": false, "description": "When next assessment is due" },
      { "name": "evidence_ids", "type": "array", "required": false, "description": "Evidence supporting this status" },
      { "name": "gap_description", "type": "text", "required": false, "description": "Description of compliance gap if not compliant" },
      { "name": "remediation_plan", "type": "text", "required": false, "description": "Plan to achieve compliance" },
      { "name": "remediation_due_date", "type": "date", "required": false, "description": "Target date for remediation" },
      { "name": "exception_reason", "type": "text", "required": false, "description": "Reason if exception granted" },
      { "name": "exception_expiry", "type": "date", "required": false, "description": "When exception expires" },
      { "name": "compensating_controls", "type": "text", "required": false, "description": "Compensating controls if exception" }
    ],
    "relationships": [
      { "entity": "ComplianceRequirement", "type": "many_to_one", "required": true },
      { "entity": "Evidence", "type": "many_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.compliance_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ControlMapping

```json
{
  "id": "data.compliance_tracking.control_mapping",
  "name": "Control Mapping",
  "type": "data",
  "namespace": "compliance_tracking",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Maps a single control to multiple framework requirements.",
    "fields": [
      { "name": "control_id", "type": "string", "required": true, "description": "Internal control identifier" },
      { "name": "control_name", "type": "string", "required": true, "description": "Human-readable control name" },
      { "name": "control_description", "type": "text", "required": true, "description": "What the control does" },
      { "name": "implementation_status", "type": "enum", "required": true, "values": ["not_started", "in_progress", "implemented", "verified"], "description": "Implementation state" },
      { "name": "requirement_mappings", "type": "array", "required": true, "description": "List of requirement IDs this control satisfies" },
      { "name": "owner_id", "type": "uuid", "required": false, "description": "Control owner" },
      { "name": "last_tested", "type": "datetime", "required": false, "description": "When control was last tested" },
      { "name": "test_frequency", "type": "enum", "required": false, "values": ["continuous", "monthly", "quarterly", "annually"], "description": "How often to test" }
    ],
    "relationships": [
      { "entity": "ComplianceRequirement", "type": "many_to_many", "required": true },
      { "entity": "Evidence", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false }
    ],
    "notes": "Avoid over-complex framework ontologies. Keep mappings simple and maintainable."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "compliance.compliance_tracking",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.compliance_tracking.assess_requirement

```yaml
workflow:
  id: "wf.compliance_tracking.assess_requirement"
  name: "Assess Compliance Requirement"
  trigger: "Scheduled assessment due or manual trigger"
  actors: ["Compliance Officer", "Control Owner", "System"]

  steps:
    - step: 1
      name: "Initiate Assessment"
      actor: "System"
      action: "Create assessment task, notify control owner"
      inputs: ["Requirement due for assessment"]
      outputs: ["Assessment task"]
      automatable: true

    - step: 2
      name: "Gather Evidence"
      actor: "Control Owner"
      action: "Collect and attach evidence of compliance"
      inputs: ["Requirement details", "Evidence types needed"]
      outputs: ["Attached evidence"]

    - step: 3
      name: "Evaluate Compliance"
      actor: "Compliance Officer"
      action: "Review evidence, determine compliance status"
      inputs: ["Evidence", "Requirement criteria"]
      outputs: ["Compliance determination"]
      decision_point: "Compliant, partial, or non-compliant?"

    - step: 4a
      name: "Record Compliant Status"
      actor: "System"
      action: "Update status to compliant, set next assessment date"
      inputs: ["Compliance determination (compliant)"]
      outputs: ["Updated compliance status"]
      condition: "Determined compliant"
      automatable: true

    - step: 4b
      name: "Document Gap and Plan Remediation"
      actor: "Compliance Officer"
      action: "Record gap details, create remediation plan"
      inputs: ["Compliance determination (non-compliant)", "Gap details"]
      outputs: ["Non-compliant status with remediation plan"]
      condition: "Determined non-compliant or partial"

    - step: 5
      name: "Escalate if Critical"
      actor: "System"
      action: "Notify management of critical compliance gaps"
      inputs: ["Non-compliant status", "Severity"]
      outputs: ["Management notification"]
      condition: "Gap is critical"
      automatable: true
```

#### wf.compliance_tracking.remediate_gap

```yaml
workflow:
  id: "wf.compliance_tracking.remediate_gap"
  name: "Remediate Compliance Gap"
  trigger: "Compliance gap identified"
  actors: ["Control Owner", "Compliance Officer", "Management"]

  steps:
    - step: 1
      name: "Create Remediation Task"
      actor: "Compliance Officer"
      action: "Define remediation steps and timeline"
      inputs: ["Gap details", "Requirement"]
      outputs: ["Remediation task"]

    - step: 2
      name: "Implement Fix"
      actor: "Control Owner"
      action: "Implement required changes"
      inputs: ["Remediation task"]
      outputs: ["Implementation evidence"]

    - step: 3
      name: "Verify Implementation"
      actor: "Compliance Officer"
      action: "Test that fix addresses gap"
      inputs: ["Implementation evidence", "Requirement"]
      outputs: ["Verification result"]
      decision_point: "Gap resolved?"

    - step: 4a
      name: "Close Gap"
      actor: "System"
      action: "Update status to compliant"
      inputs: ["Verification (passed)"]
      outputs: ["Updated compliance status"]
      condition: "Verification passed"
      automatable: true

    - step: 4b
      name: "Request Exception"
      actor: "Control Owner"
      action: "Request exception if remediation not feasible"
      inputs: ["Verification (failed)", "Business justification"]
      outputs: ["Exception request"]
      condition: "Remediation not feasible"

    - step: 5
      name: "Approve Exception"
      actor: "Management"
      action: "Review and approve exception with compensating controls"
      inputs: ["Exception request"]
      outputs: ["Approved exception with expiry"]
      condition: "Exception requested"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-CMP-009 | **Control satisfies conflicting requirements** | Medium | Document interpretation; get auditor input; create separate assessments |
| EC-CMP-010 | **Evidence expires before next assessment** | Medium | Set evidence expiry alerts; require refresh before expiration |
| EC-CMP-011 | **Requirement changes mid-assessment cycle** | Medium | Version requirements; complete current assessment; schedule new baseline |
| EC-CMP-012 | **Exception expires with no remediation** | High | Auto-escalate to management; require renewal or remediation commitment |
| EC-CMP-013 | **Partial compliance percentage unclear** | Low | Define clear rubrics per requirement; document partial criteria |
| EC-CMP-014 | **Multiple frameworks have overlapping deadlines** | Medium | Prioritize by risk and penalty; communicate resource constraints |
| EC-CMP-015 | **Third-party dependency affects compliance** | High | Track vendor compliance; require attestations; have contingency plans |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CMP-005 | **Gap prioritization** | Gaps, risk factors, resources | Prioritized remediation list | Focus on highest-risk gaps first |
| AI-CMP-006 | **Requirement interpretation** | Requirement text, organization context | Implementation guidance | Clarifies ambiguous requirements |
| AI-CMP-007 | **Cross-framework mapping** | New requirement, existing controls | Suggested control mappings | Reduces duplicate work |
| AI-CMP-008 | **Compliance forecasting** | Current status, trends, upcoming changes | Predicted compliance posture | Proactive planning |

---

## Package 3: Policy Management

### Purpose

Create, version, distribute, and track acknowledgment of organizational policies required for compliance.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of policies do you maintain? (security, acceptable use, privacy)
- How are policies versioned and updated?
- Who must acknowledge which policies?
- How often must acknowledgments be renewed?
- Are there different acknowledgment requirements by role?

**Workflow Discovery**:
- Who creates and approves policies?
- How are policy updates communicated?
- What triggers a policy acknowledgment request?
- How do you handle employees who don't acknowledge?
- What reporting is needed on acknowledgment status?

**Edge Case Probing**:
- What if an employee is on leave when acknowledgment is due?
- How do you handle contractors or temporary workers?
- What if a policy is updated right after acknowledgment?
- How do you prove acknowledgment years later?

### Entity Templates

#### Policy

```json
{
  "id": "data.policy_management.policy",
  "name": "Policy",
  "type": "data",
  "namespace": "policy_management",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "An organizational policy document requiring acknowledgment.",
    "fields": [
      { "name": "policy_id", "type": "string", "required": true, "description": "Unique policy identifier (e.g., POL-SEC-001)" },
      { "name": "title", "type": "string", "required": true, "description": "Policy title" },
      { "name": "category", "type": "enum", "required": true, "values": ["security", "privacy", "acceptable_use", "hr", "financial", "operational", "regulatory"], "description": "Policy category" },
      { "name": "version", "type": "string", "required": true, "description": "Policy version (e.g., 2.1)" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "active", "superseded", "retired"], "description": "Policy lifecycle status" },
      { "name": "effective_date", "type": "date", "required": true, "description": "When policy becomes effective" },
      { "name": "review_date", "type": "date", "required": false, "description": "When policy must be reviewed" },
      { "name": "content", "type": "text", "required": true, "description": "Full policy text or document reference" },
      { "name": "document_id", "type": "uuid", "required": false, "description": "Link to policy document in document management" },
      { "name": "summary", "type": "text", "required": false, "description": "Brief summary for acknowledgment screen" },
      { "name": "owner_id", "type": "uuid", "required": true, "description": "Policy owner responsible for updates" },
      { "name": "approver_id", "type": "uuid", "required": false, "description": "Who approved current version" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "When approved" },
      { "name": "acknowledgment_required", "type": "boolean", "required": true, "description": "Whether acknowledgment is required" },
      { "name": "acknowledgment_frequency", "type": "enum", "required": false, "values": ["once", "annually", "quarterly", "on_change"], "description": "How often to re-acknowledge" },
      { "name": "applies_to", "type": "array", "required": false, "description": "Roles, departments, or groups this applies to" },
      { "name": "related_frameworks", "type": "array", "required": false, "description": "Compliance frameworks this supports" }
    ],
    "relationships": [
      { "entity": "PolicyAcknowledgment", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Document", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.policy_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PolicyAcknowledgment

```json
{
  "id": "data.policy_management.policy_acknowledgment",
  "name": "Policy Acknowledgment",
  "type": "data",
  "namespace": "policy_management",
  "tags": ["core-entity", "mvp", "immutable"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of a user acknowledging a specific policy version.",
    "fields": [
      { "name": "policy_id", "type": "uuid", "required": true, "description": "Acknowledged policy" },
      { "name": "policy_version", "type": "string", "required": true, "description": "Specific version acknowledged" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "User who acknowledged" },
      { "name": "acknowledged_at", "type": "datetime", "required": true, "description": "When acknowledgment occurred" },
      { "name": "acknowledgment_method", "type": "enum", "required": true, "values": ["electronic", "physical_signature", "verbal", "implied"], "description": "How acknowledgment was captured" },
      { "name": "ip_address", "type": "string", "required": false, "description": "IP address at time of acknowledgment" },
      { "name": "user_agent", "type": "string", "required": false, "description": "Browser/device information" },
      { "name": "attestation_text", "type": "text", "required": false, "description": "Text user agreed to" },
      { "name": "expires_at", "type": "datetime", "required": false, "description": "When acknowledgment expires" },
      { "name": "superseded_by", "type": "uuid", "required": false, "description": "Newer acknowledgment that replaces this" }
    ],
    "relationships": [
      { "entity": "Policy", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ],
    "notes": "IMMUTABLE: Once created, acknowledgments cannot be modified or deleted."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.policy_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PolicyDistribution

```json
{
  "id": "data.policy_management.policy_distribution",
  "name": "Policy Distribution",
  "type": "data",
  "namespace": "policy_management",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of policy being distributed to users for acknowledgment.",
    "fields": [
      { "name": "policy_id", "type": "uuid", "required": true, "description": "Policy being distributed" },
      { "name": "policy_version", "type": "string", "required": true, "description": "Version being distributed" },
      { "name": "distributed_at", "type": "datetime", "required": true, "description": "When distribution started" },
      { "name": "distributed_by", "type": "uuid", "required": true, "description": "Who initiated distribution" },
      { "name": "target_users", "type": "array", "required": true, "description": "Users who must acknowledge" },
      { "name": "acknowledgment_deadline", "type": "date", "required": false, "description": "Deadline for acknowledgment" },
      { "name": "reminder_schedule", "type": "array", "required": false, "description": "Days before deadline to send reminders" },
      { "name": "acknowledged_count", "type": "integer", "required": true, "description": "Number who have acknowledged" },
      { "name": "pending_count", "type": "integer", "required": true, "description": "Number still pending" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "completed", "canceled"], "description": "Distribution status" }
    ],
    "relationships": [
      { "entity": "Policy", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "compliance.policy_management",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.policy_management.distribute_policy

```yaml
workflow:
  id: "wf.policy_management.distribute_policy"
  name: "Distribute Policy for Acknowledgment"
  trigger: "New or updated policy activated"
  actors: ["Compliance Officer", "System", "Employee"]

  steps:
    - step: 1
      name: "Identify Target Audience"
      actor: "Compliance Officer"
      action: "Determine who must acknowledge based on policy scope"
      inputs: ["Policy", "Applies_to criteria"]
      outputs: ["Target user list"]

    - step: 2
      name: "Create Distribution Record"
      actor: "System"
      action: "Create distribution with deadline and reminder schedule"
      inputs: ["Policy", "Target users", "Deadline"]
      outputs: ["Distribution record"]
      automatable: true

    - step: 3
      name: "Send Initial Notification"
      actor: "System"
      action: "Email/notify all target users"
      inputs: ["Distribution record"]
      outputs: ["Notifications sent"]
      automatable: true

    - step: 4
      name: "User Acknowledges"
      actor: "Employee"
      action: "Review policy and confirm acknowledgment"
      inputs: ["Policy content", "Attestation text"]
      outputs: ["Acknowledgment record"]

    - step: 5
      name: "Send Reminders"
      actor: "System"
      action: "Send reminders to users who haven't acknowledged"
      inputs: ["Distribution record", "Reminder schedule"]
      outputs: ["Reminder notifications"]
      condition: "Reminder date reached and pending users exist"
      automatable: true

    - step: 6
      name: "Escalate Non-Compliance"
      actor: "System"
      action: "Notify manager/HR of users past deadline"
      inputs: ["Distribution record", "Past deadline"]
      outputs: ["Escalation notifications"]
      condition: "Deadline passed with pending acknowledgments"
      automatable: true

    - step: 7
      name: "Complete Distribution"
      actor: "System"
      action: "Mark distribution complete when all acknowledged"
      inputs: ["Distribution record", "All acknowledged"]
      outputs: ["Completed distribution"]
      automatable: true
```

#### wf.policy_management.update_policy

```yaml
workflow:
  id: "wf.policy_management.update_policy"
  name: "Update and Approve Policy"
  trigger: "Policy review due or change required"
  actors: ["Policy Owner", "Approver", "System"]

  steps:
    - step: 1
      name: "Draft Update"
      actor: "Policy Owner"
      action: "Create new version with changes"
      inputs: ["Current policy", "Change requirements"]
      outputs: ["Draft policy version"]

    - step: 2
      name: "Submit for Approval"
      actor: "Policy Owner"
      action: "Submit draft to approver"
      inputs: ["Draft policy version"]
      outputs: ["Approval request"]

    - step: 3
      name: "Review and Approve"
      actor: "Approver"
      action: "Review changes, approve or request revisions"
      inputs: ["Draft policy version", "Change summary"]
      outputs: ["Approval decision"]
      decision_point: "Approve, request changes, or reject?"

    - step: 4
      name: "Activate New Version"
      actor: "System"
      action: "Set new version as active, supersede old version"
      inputs: ["Approved policy version"]
      outputs: ["Active policy"]
      condition: "Approved"
      automatable: true

    - step: 5
      name: "Trigger Re-acknowledgment"
      actor: "System"
      action: "Initiate distribution if acknowledgment required"
      inputs: ["Active policy", "Acknowledgment settings"]
      outputs: ["New distribution (if needed)"]
      condition: "Acknowledgment frequency is 'on_change'"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-CMP-016 | **Employee on leave when acknowledgment due** | Low | Extend deadline for individual; track separately; require on return |
| EC-CMP-017 | **Policy updated immediately after acknowledgment** | Low | New acknowledgment required only if material change; grace period |
| EC-CMP-018 | **Contractor needs policy access without system account** | Medium | Guest acknowledgment portal; manual record if needed |
| EC-CMP-019 | **User disputes they acknowledged** | Medium | Show immutable record with IP, timestamp, attestation text |
| EC-CMP-020 | **Acknowledgment system unavailable** | Medium | Queue acknowledgments offline; sync when available; timestamp original intent |
| EC-CMP-021 | **Policy applies to role that no longer exists** | Low | Update applies_to on policy; review distribution targets |
| EC-CMP-022 | **Multiple policies have same deadline** | Low | Allow batch acknowledgment; prioritize by criticality |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CMP-009 | **Policy summarization** | Full policy text | Plain-language summary | Improves understanding |
| AI-CMP-010 | **Change detection** | Old version, new version | Highlighted changes | Faster review of updates |
| AI-CMP-011 | **Compliance gap analysis** | Policies, regulatory requirements | Missing policy recommendations | Ensures coverage |
| AI-CMP-012 | **Readability scoring** | Policy text | Readability metrics, simplification suggestions | More accessible policies |

---

## Package 4: Evidence Collection

### Purpose

Gather, organize, and maintain evidence that demonstrates compliance with requirements, ready for audit review.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of evidence do you collect? (screenshots, logs, reports, attestations)
- How is evidence linked to requirements?
- What metadata must accompany evidence?
- How long must evidence be retained?
- What format requirements exist for evidence?

**Workflow Discovery**:
- Who collects evidence? (automated, control owners, compliance team)
- How is evidence validated?
- What triggers evidence collection?
- How do you handle evidence that expires or becomes stale?
- How is evidence shared with auditors?

**Edge Case Probing**:
- What if evidence is lost or corrupted?
- How do you handle sensitive evidence (PII, credentials)?
- What if the same evidence supports multiple requirements?
- How do you handle continuous vs point-in-time evidence?

### Entity Templates

#### Evidence

```json
{
  "id": "data.evidence_collection.evidence",
  "name": "Evidence",
  "type": "data",
  "namespace": "evidence_collection",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "A piece of evidence demonstrating compliance with a requirement.",
    "fields": [
      { "name": "evidence_id", "type": "string", "required": true, "description": "Unique evidence identifier" },
      { "name": "title", "type": "string", "required": true, "description": "Evidence title/name" },
      { "name": "description", "type": "text", "required": true, "description": "What this evidence demonstrates" },
      { "name": "type", "type": "enum", "required": true, "values": ["document", "screenshot", "log_export", "report", "attestation", "configuration", "test_result", "policy_ack", "system_generated"], "description": "Type of evidence" },
      { "name": "source", "type": "string", "required": true, "description": "Where evidence came from (system, person, vendor)" },
      { "name": "collected_at", "type": "datetime", "required": true, "description": "When evidence was collected" },
      { "name": "collected_by", "type": "uuid", "required": true, "description": "Who collected the evidence" },
      { "name": "valid_from", "type": "date", "required": true, "description": "Start of period evidence covers" },
      { "name": "valid_to", "type": "date", "required": false, "description": "End of period evidence covers" },
      { "name": "expires_at", "type": "date", "required": false, "description": "When evidence becomes stale" },
      { "name": "file_path", "type": "string", "required": false, "description": "Path to evidence file if applicable" },
      { "name": "file_hash", "type": "string", "required": false, "description": "SHA-256 hash of file for integrity" },
      { "name": "content", "type": "text", "required": false, "description": "Text content if not file-based" },
      { "name": "classification", "type": "enum", "required": true, "values": ["public", "internal", "confidential", "restricted"], "description": "Sensitivity classification" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_review", "approved", "rejected", "expired", "superseded"], "description": "Evidence status" },
      { "name": "reviewed_by", "type": "uuid", "required": false, "description": "Who approved the evidence" },
      { "name": "reviewed_at", "type": "datetime", "required": false, "description": "When evidence was approved" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why evidence was rejected" }
    ],
    "relationships": [
      { "entity": "ComplianceRequirement", "type": "many_to_many", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Document", "type": "many_to_one", "required": false },
      { "entity": "Audit", "type": "many_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.evidence_collection",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### EvidenceRequest

```json
{
  "id": "data.evidence_collection.evidence_request",
  "name": "Evidence Request",
  "type": "data",
  "namespace": "evidence_collection",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "A request for specific evidence to be collected.",
    "fields": [
      { "name": "requirement_id", "type": "uuid", "required": true, "description": "Requirement needing evidence" },
      { "name": "audit_id", "type": "uuid", "required": false, "description": "Audit this is for (if applicable)" },
      { "name": "requested_by", "type": "uuid", "required": true, "description": "Who requested the evidence" },
      { "name": "assigned_to", "type": "uuid", "required": true, "description": "Who should collect the evidence" },
      { "name": "description", "type": "text", "required": true, "description": "What evidence is needed" },
      { "name": "due_date", "type": "date", "required": true, "description": "When evidence must be provided" },
      { "name": "priority", "type": "enum", "required": true, "values": ["low", "medium", "high", "critical"], "description": "Request priority" },
      { "name": "status", "type": "enum", "required": true, "values": ["open", "in_progress", "submitted", "accepted", "rejected"], "description": "Request status" },
      { "name": "evidence_id", "type": "uuid", "required": false, "description": "Submitted evidence (once provided)" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why submitted evidence was rejected" }
    ],
    "relationships": [
      { "entity": "ComplianceRequirement", "type": "many_to_one", "required": true },
      { "entity": "Audit", "type": "many_to_one", "required": false },
      { "entity": "Evidence", "type": "one_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "compliance.evidence_collection",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### EvidenceCollection

```json
{
  "id": "data.evidence_collection.evidence_collection",
  "name": "Evidence Collection",
  "type": "data",
  "namespace": "evidence_collection",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "A grouped set of evidence for an audit or assessment period.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Collection name (e.g., 'SOC2 2025 Type II')" },
      { "name": "description", "type": "text", "required": false, "description": "Collection purpose" },
      { "name": "audit_id", "type": "uuid", "required": false, "description": "Associated audit if applicable" },
      { "name": "period_start", "type": "date", "required": true, "description": "Start of audit/assessment period" },
      { "name": "period_end", "type": "date", "required": true, "description": "End of audit/assessment period" },
      { "name": "frameworks", "type": "array", "required": true, "description": "Frameworks this collection supports" },
      { "name": "status", "type": "enum", "required": true, "values": ["in_progress", "review", "complete", "archived"], "description": "Collection status" },
      { "name": "evidence_count", "type": "integer", "required": true, "description": "Number of evidence items" },
      { "name": "created_by", "type": "uuid", "required": true, "description": "Who created the collection" }
    ],
    "relationships": [
      { "entity": "Evidence", "type": "one_to_many", "required": false },
      { "entity": "Audit", "type": "one_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "compliance.evidence_collection",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.evidence_collection.collect_evidence

```yaml
workflow:
  id: "wf.evidence_collection.collect_evidence"
  name: "Collect and Submit Evidence"
  trigger: "Evidence request created or scheduled collection"
  actors: ["Control Owner", "Compliance Officer", "System"]

  steps:
    - step: 1
      name: "Receive Request"
      actor: "Control Owner"
      action: "Review evidence request, understand requirements"
      inputs: ["Evidence request", "Requirement details"]
      outputs: ["Request acknowledged"]

    - step: 2
      name: "Gather Evidence"
      actor: "Control Owner"
      action: "Collect required evidence (export, screenshot, document)"
      inputs: ["Request requirements"]
      outputs: ["Raw evidence"]

    - step: 3
      name: "Upload and Document"
      actor: "Control Owner"
      action: "Upload evidence with metadata and description"
      inputs: ["Raw evidence"]
      outputs: ["Evidence record"]

    - step: 4
      name: "Validate Evidence"
      actor: "Compliance Officer"
      action: "Review evidence completeness and relevance"
      inputs: ["Evidence record", "Requirement"]
      outputs: ["Validation result"]
      decision_point: "Evidence acceptable?"

    - step: 5a
      name: "Approve Evidence"
      actor: "Compliance Officer"
      action: "Mark evidence as approved, link to requirements"
      inputs: ["Evidence record (approved)"]
      outputs: ["Approved evidence"]
      condition: "Evidence acceptable"

    - step: 5b
      name: "Reject and Request Revision"
      actor: "Compliance Officer"
      action: "Reject with feedback, request new evidence"
      inputs: ["Evidence record (rejected)", "Rejection reason"]
      outputs: ["Rejected evidence", "New request"]
      condition: "Evidence not acceptable"

    - step: 6
      name: "Archive to Collection"
      actor: "System"
      action: "Add approved evidence to appropriate collection"
      inputs: ["Approved evidence", "Collection context"]
      outputs: ["Evidence in collection"]
      automatable: true
```

#### wf.evidence_collection.automated_collection

```yaml
workflow:
  id: "wf.evidence_collection.automated_collection"
  name: "Automated Evidence Collection"
  trigger: "Scheduled or event-driven"
  actors: ["System"]

  steps:
    - step: 1
      name: "Trigger Collection"
      actor: "System"
      action: "Start automated collection based on schedule or event"
      inputs: ["Collection schedule", "Evidence type"]
      outputs: ["Collection job"]
      automatable: true

    - step: 2
      name: "Execute Collection"
      actor: "System"
      action: "Run collection script/integration"
      inputs: ["Collection configuration"]
      outputs: ["Raw evidence data"]
      automatable: true

    - step: 3
      name: "Process and Store"
      actor: "System"
      action: "Format evidence, calculate hash, store file"
      inputs: ["Raw evidence data"]
      outputs: ["Evidence record"]
      automatable: true

    - step: 4
      name: "Link to Requirements"
      actor: "System"
      action: "Associate evidence with relevant requirements"
      inputs: ["Evidence record", "Requirement mappings"]
      outputs: ["Linked evidence"]
      automatable: true

    - step: 5
      name: "Flag for Review"
      actor: "System"
      action: "Queue for human review if required"
      inputs: ["Evidence record", "Review rules"]
      outputs: ["Review queue item"]
      condition: "Manual review required"
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-CMP-023 | **Evidence file corrupted or lost** | High | Maintain hash for detection; require re-collection; backup policy |
| EC-CMP-024 | **Evidence contains sensitive data (PII/credentials)** | High | Redact before storage; mark classification; restrict access |
| EC-CMP-025 | **Same evidence supports multiple requirements** | Low | Allow many-to-many linking; single source of truth |
| EC-CMP-026 | **Evidence expires before audit** | Medium | Set expiry alerts; schedule refresh collection |
| EC-CMP-027 | **Automated collection fails** | Medium | Alert control owner; fallback to manual; track collection gaps |
| EC-CMP-028 | **Auditor requests evidence not previously collected** | High | Create ad-hoc request; extend deadline if needed; document limitation |
| EC-CMP-029 | **Evidence validity period doesn't match audit period** | Medium | Accept overlapping coverage; note gaps; collect supplemental |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CMP-013 | **Evidence relevance scoring** | Evidence, requirement | Relevance score | Validates evidence quality |
| AI-CMP-014 | **Missing evidence detection** | Requirements, existing evidence | Gap list | Identifies collection needs |
| AI-CMP-015 | **Evidence summarization** | Long evidence document | Concise summary | Faster auditor review |
| AI-CMP-016 | **Sensitive data detection** | Evidence content | Flagged sensitive items | Prevents accidental exposure |

---

## Package 5: Audit Preparation

### Purpose

Prepare for and manage internal and external audits, including auditor coordination, finding management, and remediation tracking.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of audits do you undergo? (SOC2, financial, regulatory)
- How do you track audit findings and observations?
- What information do auditors typically request?
- How do you manage auditor access and communication?
- How are audit findings prioritized and remediated?

**Workflow Discovery**:
- Who coordinates with external auditors?
- What's the typical audit timeline?
- How do you prepare evidence packages for auditors?
- How are audit findings tracked to closure?
- What reporting does management need on audit status?

**Edge Case Probing**:
- What if auditor requests access to sensitive systems?
- How do you handle unexpected audit findings?
- What if remediation timeline conflicts with business priorities?
- How do you handle repeat findings?

### Entity Templates

#### Audit

```json
{
  "id": "data.audit_preparation.audit",
  "name": "Audit",
  "type": "data",
  "namespace": "audit_preparation",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "A scheduled or in-progress audit engagement.",
    "fields": [
      { "name": "audit_id", "type": "string", "required": true, "description": "Unique audit identifier" },
      { "name": "title", "type": "string", "required": true, "description": "Audit title" },
      { "name": "type", "type": "enum", "required": true, "values": ["internal", "external", "regulatory", "certification"], "description": "Type of audit" },
      { "name": "framework", "type": "enum", "required": false, "values": ["SOC2", "HIPAA", "GDPR", "PCI-DSS", "ISO27001", "financial", "operational", "custom"], "description": "Framework being audited" },
      { "name": "auditor_name", "type": "string", "required": false, "description": "Audit firm or internal team" },
      { "name": "lead_auditor", "type": "string", "required": false, "description": "Primary auditor contact" },
      { "name": "status", "type": "enum", "required": true, "values": ["planning", "fieldwork", "reporting", "remediation", "complete", "canceled"], "description": "Audit lifecycle status" },
      { "name": "period_start", "type": "date", "required": true, "description": "Start of audit period" },
      { "name": "period_end", "type": "date", "required": true, "description": "End of audit period" },
      { "name": "fieldwork_start", "type": "date", "required": false, "description": "When fieldwork begins" },
      { "name": "fieldwork_end", "type": "date", "required": false, "description": "When fieldwork ends" },
      { "name": "report_due", "type": "date", "required": false, "description": "Expected report delivery date" },
      { "name": "internal_owner_id", "type": "uuid", "required": true, "description": "Internal audit coordinator" },
      { "name": "findings_count", "type": "integer", "required": false, "description": "Number of findings" },
      { "name": "open_findings_count", "type": "integer", "required": false, "description": "Number of unresolved findings" },
      { "name": "opinion", "type": "enum", "required": false, "values": ["unqualified", "qualified", "adverse", "disclaimer", "pending"], "description": "Audit opinion (if applicable)" }
    ],
    "relationships": [
      { "entity": "AuditFinding", "type": "one_to_many", "required": false },
      { "entity": "EvidenceCollection", "type": "one_to_one", "required": false },
      { "entity": "AuditRequest", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.audit_preparation",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### AuditFinding

```json
{
  "id": "data.audit_preparation.audit_finding",
  "name": "Audit Finding",
  "type": "data",
  "namespace": "audit_preparation",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "An observation or issue identified during an audit.",
    "fields": [
      { "name": "audit_id", "type": "uuid", "required": true, "description": "Parent audit" },
      { "name": "finding_number", "type": "string", "required": true, "description": "Finding identifier within audit" },
      { "name": "title", "type": "string", "required": true, "description": "Finding title" },
      { "name": "description", "type": "text", "required": true, "description": "Detailed finding description" },
      { "name": "type", "type": "enum", "required": true, "values": ["deficiency", "significant_deficiency", "material_weakness", "observation", "recommendation"], "description": "Finding severity type" },
      { "name": "risk_level", "type": "enum", "required": true, "values": ["low", "medium", "high", "critical"], "description": "Risk level" },
      { "name": "status", "type": "enum", "required": true, "values": ["open", "acknowledged", "remediation_planned", "in_remediation", "pending_validation", "closed", "accepted_risk"], "description": "Finding status" },
      { "name": "requirement_id", "type": "uuid", "required": false, "description": "Related compliance requirement" },
      { "name": "root_cause", "type": "text", "required": false, "description": "Root cause analysis" },
      { "name": "management_response", "type": "text", "required": false, "description": "Management's response to finding" },
      { "name": "remediation_plan", "type": "text", "required": false, "description": "Plan to address finding" },
      { "name": "remediation_owner_id", "type": "uuid", "required": false, "description": "Person responsible for remediation" },
      { "name": "target_date", "type": "date", "required": false, "description": "Target remediation completion date" },
      { "name": "closed_date", "type": "date", "required": false, "description": "When finding was closed" },
      { "name": "repeat_finding", "type": "boolean", "required": false, "description": "Whether this is a repeat from prior audit" },
      { "name": "prior_finding_id", "type": "uuid", "required": false, "description": "Link to prior audit finding if repeat" }
    ],
    "relationships": [
      { "entity": "Audit", "type": "many_to_one", "required": true },
      { "entity": "ComplianceRequirement", "type": "many_to_one", "required": false },
      { "entity": "User", "type": "many_to_one", "required": false },
      { "entity": "AuditFinding", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "compliance.audit_preparation",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### AuditRequest

```json
{
  "id": "data.audit_preparation.audit_request",
  "name": "Audit Request (PBC)",
  "type": "data",
  "namespace": "audit_preparation",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "A request from auditors for information or evidence (Prepared By Client).",
    "fields": [
      { "name": "audit_id", "type": "uuid", "required": true, "description": "Parent audit" },
      { "name": "request_number", "type": "string", "required": true, "description": "PBC item number" },
      { "name": "description", "type": "text", "required": true, "description": "What auditor is requesting" },
      { "name": "category", "type": "string", "required": false, "description": "Request category (documentation, access, interview)" },
      { "name": "assigned_to", "type": "uuid", "required": true, "description": "Person responsible for fulfilling" },
      { "name": "due_date", "type": "date", "required": true, "description": "When response is due" },
      { "name": "status", "type": "enum", "required": true, "values": ["open", "in_progress", "submitted", "accepted", "rejected", "withdrawn"], "description": "Request status" },
      { "name": "priority", "type": "enum", "required": true, "values": ["low", "medium", "high", "critical"], "description": "Request priority" },
      { "name": "response", "type": "text", "required": false, "description": "Response or clarification" },
      { "name": "evidence_ids", "type": "array", "required": false, "description": "Evidence provided in response" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When response was submitted" },
      { "name": "auditor_feedback", "type": "text", "required": false, "description": "Auditor response to submission" }
    ],
    "relationships": [
      { "entity": "Audit", "type": "many_to_one", "required": true },
      { "entity": "Evidence", "type": "many_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "compliance.audit_preparation",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.audit_preparation.conduct_audit

```yaml
workflow:
  id: "wf.audit_preparation.conduct_audit"
  name: "Conduct Audit"
  trigger: "Scheduled audit begins"
  actors: ["Audit Coordinator", "Control Owners", "Auditor", "Management"]

  steps:
    - step: 1
      name: "Planning Phase"
      actor: "Audit Coordinator"
      action: "Create audit record, define scope, schedule fieldwork"
      inputs: ["Audit requirements", "Available dates"]
      outputs: ["Audit record", "Schedule"]

    - step: 2
      name: "Prepare Evidence Package"
      actor: "Audit Coordinator"
      action: "Create evidence collection, gather preliminary documents"
      inputs: ["Scope", "Requirement list"]
      outputs: ["Evidence collection"]

    - step: 3
      name: "Fieldwork Kickoff"
      actor: "Auditor"
      action: "Begin fieldwork, submit initial PBC requests"
      inputs: ["Scope", "Evidence collection"]
      outputs: ["PBC requests"]

    - step: 4
      name: "Fulfill Requests"
      actor: "Control Owners"
      action: "Respond to auditor requests with evidence"
      inputs: ["PBC requests"]
      outputs: ["Submitted evidence"]

    - step: 5
      name: "Conduct Testing"
      actor: "Auditor"
      action: "Test controls, review evidence, conduct interviews"
      inputs: ["Evidence", "Control documentation"]
      outputs: ["Testing workpapers"]

    - step: 6
      name: "Draft Findings"
      actor: "Auditor"
      action: "Document findings and observations"
      inputs: ["Testing results"]
      outputs: ["Draft findings"]

    - step: 7
      name: "Management Response"
      actor: "Management"
      action: "Review findings, provide responses"
      inputs: ["Draft findings"]
      outputs: ["Management responses"]

    - step: 8
      name: "Final Report"
      actor: "Auditor"
      action: "Issue final audit report"
      inputs: ["Findings", "Management responses"]
      outputs: ["Audit report"]

    - step: 9
      name: "Remediation Tracking"
      actor: "Audit Coordinator"
      action: "Track remediation of findings"
      inputs: ["Open findings"]
      outputs: ["Remediation status"]
```

#### wf.audit_preparation.remediate_finding

```yaml
workflow:
  id: "wf.audit_preparation.remediate_finding"
  name: "Remediate Audit Finding"
  trigger: "Audit finding created"
  actors: ["Remediation Owner", "Audit Coordinator", "Management"]

  steps:
    - step: 1
      name: "Acknowledge Finding"
      actor: "Remediation Owner"
      action: "Review finding, acknowledge responsibility"
      inputs: ["Audit finding"]
      outputs: ["Acknowledged finding"]

    - step: 2
      name: "Develop Remediation Plan"
      actor: "Remediation Owner"
      action: "Create plan with timeline and milestones"
      inputs: ["Finding details", "Root cause"]
      outputs: ["Remediation plan"]

    - step: 3
      name: "Approve Plan"
      actor: "Management"
      action: "Review and approve remediation plan"
      inputs: ["Remediation plan"]
      outputs: ["Approved plan"]
      decision_point: "Approve plan or request revision?"

    - step: 4
      name: "Execute Remediation"
      actor: "Remediation Owner"
      action: "Implement fixes per plan"
      inputs: ["Approved plan"]
      outputs: ["Implementation evidence"]

    - step: 5
      name: "Validate Fix"
      actor: "Audit Coordinator"
      action: "Verify remediation addresses finding"
      inputs: ["Implementation evidence", "Original finding"]
      outputs: ["Validation result"]
      decision_point: "Finding resolved?"

    - step: 6a
      name: "Close Finding"
      actor: "Audit Coordinator"
      action: "Mark finding as closed"
      inputs: ["Validation (passed)"]
      outputs: ["Closed finding"]
      condition: "Validation passed"

    - step: 6b
      name: "Reopen Remediation"
      actor: "Remediation Owner"
      action: "Address validation gaps"
      inputs: ["Validation (failed)", "Gaps identified"]
      outputs: ["Updated remediation plan"]
      condition: "Validation failed"

    - step: 7
      name: "Accept Risk (if applicable)"
      actor: "Management"
      action: "Accept risk if remediation not feasible"
      inputs: ["Finding", "Business justification"]
      outputs: ["Risk acceptance record"]
      condition: "Remediation not feasible"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-CMP-030 | **Auditor requests access to production system** | High | Provide read-only access; monitor activity; time-limited credentials |
| EC-CMP-031 | **Finding remediation delayed by business priorities** | Medium | Escalate to management; document delay; request deadline extension |
| EC-CMP-032 | **Repeat finding from prior year** | High | Escalate priority; root cause analysis; management attention |
| EC-CMP-033 | **Auditor and management disagree on finding** | Medium | Document positions; escalate if needed; may result in qualified opinion |
| EC-CMP-034 | **Critical finding discovered mid-audit** | High | Immediate management notification; accelerated remediation; may pause audit |
| EC-CMP-035 | **Auditor changes scope mid-audit** | Medium | Document scope change; assess impact; adjust timeline/resources |
| EC-CMP-036 | **Key personnel unavailable during fieldwork** | Medium | Designate backups; prepare documentation in advance |
| EC-CMP-037 | **Evidence unavailable for audit period** | High | Document gap; provide compensating evidence; note limitation |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-CMP-017 | **PBC request triage** | Incoming requests | Prioritized, categorized list | Efficient request management |
| AI-CMP-018 | **Finding similarity detection** | New finding, historical findings | Similar past findings | Identifies patterns and repeats |
| AI-CMP-019 | **Remediation plan generation** | Finding details | Draft remediation plan | Speeds response development |
| AI-CMP-020 | **Audit readiness assessment** | Current compliance status, upcoming audit | Readiness score, gap list | Proactive preparation |

---

## Cross-Package Relationships

The Compliance module packages interconnect to form a complete compliance management system:

```
                    ┌─────────────────────────────────────────────┐
                    │              AUDIT LOGGING                   │
                    │  (Foundation: all actions write to log)      │
                    └─────────────────┬───────────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐
│  COMPLIANCE         │  │  POLICY             │  │  EVIDENCE           │
│  TRACKING           │  │  MANAGEMENT         │  │  COLLECTION         │
│  (Requirements &    │  │  (Policies &        │  │  (Evidence &        │
│  status tracking)   │  │  acknowledgments)   │  │  documentation)     │
└─────────┬───────────┘  └─────────┬───────────┘  └─────────┬───────────┘
          │                        │                        │
          └────────────────────────┼────────────────────────┘
                                   │
                                   ▼
                    ┌─────────────────────────────────────────────┐
                    │           AUDIT PREPARATION                  │
                    │  (Audits, findings, remediation)             │
                    └─────────────────────────────────────────────┘
```

### Key Integration Points Within Compliance

| From | To | Integration |
|------|-----|-------------|
| Audit Logging | All Packages | All changes write to audit log via AuditableMixin |
| Compliance Tracking | Evidence Collection | Requirements specify evidence types needed |
| Compliance Tracking | Audit Preparation | Compliance gaps become audit findings |
| Policy Management | Compliance Tracking | Policy acknowledgments support compliance status |
| Policy Management | Evidence Collection | Acknowledgment records serve as evidence |
| Evidence Collection | Audit Preparation | Evidence packages support audit fieldwork |
| Audit Preparation | Compliance Tracking | Findings drive compliance status updates |

---

## Integration Points (External Systems)

### GRC Platforms

| System | Use Case | Notes |
|--------|----------|-------|
| **ServiceNow GRC** | Enterprise GRC | Full platform integration |
| **OneTrust** | Privacy & compliance | Strong GDPR/CCPA support |
| **LogicGate** | Risk & compliance workflows | Flexible workflow builder |
| **Archer** | Enterprise GRC | RSA ecosystem |
| **Vanta** | Continuous compliance | SOC2 automation |
| **Drata** | Compliance automation | Real-time monitoring |

### Security Tools

| System | Use Case | Notes |
|--------|----------|-------|
| **SIEM (Splunk, etc.)** | Security log aggregation | Feed security events to audit log |
| **IAM systems** | Access control evidence | Export access reviews, provisioning logs |
| **Vulnerability scanners** | Security compliance evidence | Scan reports as evidence |
| **EDR platforms** | Endpoint security evidence | Compliance reporting |

### Document Management

| System | Use Case | Notes |
|--------|----------|-------|
| **SharePoint** | Policy document storage | Version control, access tracking |
| **Confluence** | Policy wiki | Collaborative editing |
| **DocuSign** | Electronic signatures | Policy acknowledgments |

### Identity Providers

| System | Use Case | Notes |
|--------|----------|-------|
| **Okta** | Authentication logging | Login events to audit log |
| **Azure AD** | Access management | User provisioning evidence |
| **Auth0** | Authentication | Session and access logs |

---

## Framework-Specific Considerations

### SOC2

| Trust Principle | Key Evidence Types |
|-----------------|-------------------|
| Security | Access logs, vulnerability scans, incident records |
| Availability | Uptime reports, disaster recovery tests, SLAs |
| Processing Integrity | Change management records, QA testing |
| Confidentiality | Encryption configurations, data classification |
| Privacy | Privacy notices, consent records, data handling |

### HIPAA

| Requirement Area | Key Evidence Types |
|------------------|-------------------|
| Administrative Safeguards | Policies, training records, risk assessments |
| Physical Safeguards | Access logs, facility security, device inventory |
| Technical Safeguards | Access controls, encryption, audit logs |
| Breach Notification | Incident records, notification procedures |

### GDPR

| Requirement Area | Key Evidence Types |
|------------------|-------------------|
| Lawful Basis | Consent records, legitimate interest assessments |
| Data Subject Rights | Request handling records, response timelines |
| Data Protection | DPIAs, encryption, access controls |
| International Transfers | Transfer agreements, adequacy documentation |

### PCI-DSS

| Requirement Area | Key Evidence Types |
|------------------|-------------------|
| Network Security | Firewall configs, network diagrams |
| Data Protection | Encryption, key management, tokenization |
| Vulnerability Management | Scan reports, patch records |
| Access Control | User access reviews, MFA configuration |
| Monitoring | Log reviews, incident response |

### ISO 27001

| Requirement Area | Key Evidence Types |
|------------------|-------------------|
| ISMS | Scope documentation, risk register |
| Control Objectives | Control implementation evidence |
| Internal Audit | Audit reports, nonconformities |
| Management Review | Meeting minutes, decisions |

---

## Anti-Patterns to Avoid

### Logging Everything

**Problem**: Capturing every system event creates noise, storage costs, and makes finding relevant entries difficult.

**Solution**: Define clear criteria for what must be logged:
- Security-relevant actions (authentication, authorization)
- Data changes to sensitive or regulated data
- Administrative actions
- Failed access attempts

### Complex Framework Ontologies

**Problem**: Creating elaborate data models to represent every possible regulatory requirement and mapping creates maintenance burden and complexity without proportional value.

**Solution**: Keep control mappings simple:
- One control can satisfy multiple requirements
- Use tags/arrays for requirement links
- Document interpretations in notes, not data structures

### Blockchain Overkill

**Problem**: Some organizations consider blockchain for audit logs, adding massive complexity for minimal benefit over hash-chained append-only logs.

**Solution**: Hash-chain provides tamper evidence without:
- Distributed consensus overhead
- Cryptocurrency complexity
- Vendor lock-in
- Performance penalties

A simple SHA-256 chain in a well-protected database provides sufficient integrity for most regulatory requirements.

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Audit Logging | AuditLog, AuditLogVerification | AuditableMixin (pattern) |
| Compliance Tracking | ComplianceRequirement, ComplianceStatus | ControlMapping |
| Policy Management | Policy, PolicyAcknowledgment | PolicyDistribution |
| Evidence Collection | Evidence, EvidenceRequest | EvidenceCollection |
| Audit Preparation | Audit, AuditFinding | AuditRequest |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.audit_logging.log_action | Log Auditable Action | Any CRUD on auditable entity |
| wf.audit_logging.verify_chain | Verify Audit Log Integrity | Scheduled or on-demand |
| wf.compliance_tracking.assess_requirement | Assess Compliance Requirement | Scheduled or manual |
| wf.compliance_tracking.remediate_gap | Remediate Compliance Gap | Gap identified |
| wf.policy_management.distribute_policy | Distribute Policy | Policy activated |
| wf.policy_management.update_policy | Update and Approve Policy | Review due or change needed |
| wf.evidence_collection.collect_evidence | Collect and Submit Evidence | Request created |
| wf.evidence_collection.automated_collection | Automated Evidence Collection | Scheduled |
| wf.audit_preparation.conduct_audit | Conduct Audit | Scheduled audit |
| wf.audit_preparation.remediate_finding | Remediate Audit Finding | Finding created |

### Edge Case ID Ranges

| Package | ID Range |
|---------|----------|
| Audit Logging | EC-CMP-001 to EC-CMP-008 |
| Compliance Tracking | EC-CMP-009 to EC-CMP-015 |
| Policy Management | EC-CMP-016 to EC-CMP-022 |
| Evidence Collection | EC-CMP-023 to EC-CMP-029 |
| Audit Preparation | EC-CMP-030 to EC-CMP-037 |

### AI Touchpoint ID Ranges

| Package | ID Range |
|---------|----------|
| Audit Logging | AI-CMP-001 to AI-CMP-004 |
| Compliance Tracking | AI-CMP-005 to AI-CMP-008 |
| Policy Management | AI-CMP-009 to AI-CMP-012 |
| Evidence Collection | AI-CMP-013 to AI-CMP-016 |
| Audit Preparation | AI-CMP-017 to AI-CMP-020 |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
