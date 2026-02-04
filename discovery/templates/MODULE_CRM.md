# Module Catalog: CRM (Customer Relationship Management)

**Module ID**: `crm`
**Version**: 1.0
**Last Updated**: 2025-01-26

---

## Overview

CRM handles the complete lifecycle of customer relationships - from first contact to long-term retention. This module provides pre-built patterns for tracking who your customers are, how you interact with them, and where they are in their journey with your business.

### When to Use This Module

Select CRM when R1 context includes:
- "customer", "client", "account" terminology
- Need to track interaction history
- Sales or support team actors
- "customer 360", "single view of customer"
- Lead or prospect tracking
- Customer lifecycle or journey tracking

### What CRM Provides

| Capability | Packages |
|------------|----------|
| Store customer/contact data | customer_management |
| Track all interactions | interaction_tracking |
| Manage customer journey | lifecycle |

### Cross-Module Integration Points

| Integrates With | How |
|-----------------|-----|
| Financial | Customer -> Invoice linkage, payment history |
| Field Service | Customer -> Work Order assignments |
| Sales | Customer -> Opportunity ownership |
| Communication | Auto-log emails, calls, meetings |
| Compliance | Consent tracking, audit trails |

---

## Package: customer_management

**Purpose**: Core customer and contact data storage with relationship hierarchies.

### Discovery Questions (R2/R3)

Use these questions during entity and workflow discovery:

**Entity Questions (R2)**:
1. "What uniquely identifies a customer in your system?" (email, account number, external ID)
2. "Do you distinguish between organizations (Accounts) and individuals (Contacts)?"
3. "Can one Contact belong to multiple Accounts?" (many-to-many vs many-to-one)
4. "Do you track relationships between customers?" (parent/child, partner, referral)
5. "What customer data is required vs optional?"
6. "Do you support multiple addresses per customer?" (billing, shipping, service)
7. "How do you handle international customers?" (country-specific fields, localization)

**Workflow Questions (R3)**:
1. "How does a new customer get created?" (self-registration, sales entry, import)
2. "What happens when a customer is identified as duplicate?"
3. "Can customers be deactivated vs deleted?"
4. "Who can edit customer records?" (role-based access)
5. "Do customers self-service their profile updates?"

### Entity Templates

#### Customer

```json
{
  "id": "data.crm.customer",
  "name": "Customer",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity", "pii"],
  "status": "discovered",

  "requires": ["infrastructure.core.database"],
  "parallel_hints": ["data.crm.contact", "data.crm.account"],

  "spec": {
    "purpose": "Primary customer record - may represent individual or organization.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "type", "type": "enum", "values": ["individual", "organization"], "required": true },
      { "name": "display_name", "type": "string", "required": true, "max_length": 200 },
      { "name": "status", "type": "enum", "values": ["active", "inactive", "prospect", "churned"], "default": "prospect" },
      { "name": "source", "type": "enum", "values": ["web", "referral", "sales", "import", "api"], "required": false },
      { "name": "external_id", "type": "string", "required": false, "notes": "ID from external system" },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true },
      { "name": "created_by", "type": "uuid", "required": true, "references": "User" }
    ],
    "relationships": [
      { "name": "contacts", "type": "one-to-many", "target": "Contact" },
      { "name": "addresses", "type": "one-to-many", "target": "Address" },
      { "name": "interactions", "type": "one-to-many", "target": "Interaction" },
      { "name": "owner", "type": "many-to-one", "target": "User", "notes": "Account owner/rep" },
      { "name": "parent", "type": "many-to-one", "target": "Customer", "notes": "Parent account for hierarchy" }
    ],
    "indexes": [
      { "fields": ["display_name"], "type": "btree" },
      { "fields": ["external_id"], "type": "unique", "where": "external_id IS NOT NULL" },
      { "fields": ["owner_id", "status"], "type": "btree" },
      { "fields": ["created_at"], "type": "btree" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "CRUD operations work correctly", "verification_method": "automated" },
      { "id": "AC-2", "description": "Duplicate detection on create", "verification_method": "automated" },
      { "id": "AC-3", "description": "Cascade soft-delete to child records", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.customer_management",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Contact

```json
{
  "id": "data.crm.contact",
  "name": "Contact",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity", "pii"],
  "status": "discovered",

  "requires": ["infrastructure.core.database"],
  "parallel_hints": ["data.crm.customer"],

  "spec": {
    "purpose": "Individual person associated with a customer/account.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "first_name", "type": "string", "required": true, "max_length": 100 },
      { "name": "last_name", "type": "string", "required": true, "max_length": 100 },
      { "name": "email", "type": "email", "required": false },
      { "name": "phone", "type": "phone", "required": false },
      { "name": "job_title", "type": "string", "required": false, "max_length": 100 },
      { "name": "is_primary", "type": "boolean", "default": false, "notes": "Primary contact for account" },
      { "name": "status", "type": "enum", "values": ["active", "inactive"], "default": "active" },
      { "name": "communication_preference", "type": "enum", "values": ["email", "phone", "any"], "default": "any" },
      { "name": "do_not_contact", "type": "boolean", "default": false },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "relationships": [
      { "name": "customer", "type": "many-to-one", "target": "Customer" },
      { "name": "interactions", "type": "one-to-many", "target": "Interaction" }
    ],
    "indexes": [
      { "fields": ["customer_id"], "type": "btree" },
      { "fields": ["email"], "type": "btree" },
      { "fields": ["last_name", "first_name"], "type": "btree" }
    ],
    "constraints": [
      { "name": "one_primary_per_customer", "type": "unique_partial", "fields": ["customer_id"], "where": "is_primary = true" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Only one primary contact per customer", "verification_method": "automated" },
      { "id": "AC-2", "description": "Email format validation", "verification_method": "automated" },
      { "id": "AC-3", "description": "Respects do_not_contact flag in communications", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.customer_management",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Account

```json
{
  "id": "data.crm.account",
  "name": "Account",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Business/organization details for organizational customers.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "legal_name", "type": "string", "required": true, "max_length": 300 },
      { "name": "dba_name", "type": "string", "required": false, "notes": "Doing Business As" },
      { "name": "tax_id", "type": "string", "required": false, "notes": "EIN, VAT, etc." },
      { "name": "industry", "type": "string", "required": false },
      { "name": "employee_count", "type": "enum", "values": ["1-10", "11-50", "51-200", "201-500", "501-1000", "1000+"], "required": false },
      { "name": "annual_revenue", "type": "enum", "values": ["<100K", "100K-1M", "1M-10M", "10M-100M", "100M+"], "required": false },
      { "name": "website", "type": "url", "required": false },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "relationships": [
      { "name": "customer", "type": "one-to-one", "target": "Customer" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "One-to-one with Customer where type=organization", "verification_method": "automated" },
      { "id": "AC-2", "description": "Tax ID format validation by country", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.customer_management",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Relationship

```json
{
  "id": "data.crm.relationship",
  "name": "Relationship",
  "type": "data",
  "namespace": "crm",
  "tags": ["linking-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Tracks relationships between customers (parent/child, partner, referral).",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "from_customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "to_customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "relationship_type", "type": "enum", "values": ["parent_child", "partner", "referral", "reseller", "subsidiary"], "required": true },
      { "name": "notes", "type": "text", "required": false },
      { "name": "start_date", "type": "date", "required": false },
      { "name": "end_date", "type": "date", "required": false },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "constraints": [
      { "name": "no_self_relationship", "type": "check", "condition": "from_customer_id != to_customer_id" },
      { "name": "unique_relationship", "type": "unique", "fields": ["from_customer_id", "to_customer_id", "relationship_type"] }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Prevent self-referential relationships", "verification_method": "automated" },
      { "id": "AC-2", "description": "Unique constraint on relationship pairs", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.customer_management",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Address

```json
{
  "id": "data.crm.address",
  "name": "Address",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity", "pii"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Physical addresses for customers (billing, shipping, service locations).",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "address_type", "type": "enum", "values": ["billing", "shipping", "service", "headquarters", "other"], "required": true },
      { "name": "is_default", "type": "boolean", "default": false },
      { "name": "street_line_1", "type": "string", "required": true, "max_length": 200 },
      { "name": "street_line_2", "type": "string", "required": false, "max_length": 200 },
      { "name": "city", "type": "string", "required": true, "max_length": 100 },
      { "name": "state_province", "type": "string", "required": false, "max_length": 100 },
      { "name": "postal_code", "type": "string", "required": false, "max_length": 20 },
      { "name": "country", "type": "string", "required": true, "max_length": 2, "notes": "ISO 3166-1 alpha-2" },
      { "name": "latitude", "type": "decimal", "required": false },
      { "name": "longitude", "type": "decimal", "required": false },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "indexes": [
      { "fields": ["customer_id", "address_type"], "type": "btree" },
      { "fields": ["postal_code"], "type": "btree" }
    ],
    "constraints": [
      { "name": "one_default_per_type", "type": "unique_partial", "fields": ["customer_id", "address_type"], "where": "is_default = true" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "One default address per type per customer", "verification_method": "automated" },
      { "id": "AC-2", "description": "Country code validation", "verification_method": "automated" },
      { "id": "AC-3", "description": "Geocoding populates lat/long when address saved", "verification_method": "manual" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.customer_management",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

### Workflow Templates

#### WF-CM-001: Create New Customer

```yaml
workflow_id: WF-CM-001
name: Create New Customer
trigger: User clicks "New Customer" or imports customer data
actors: [Sales Rep, Admin, System (import)]
happy_path:
  - step: 1
    action: Enter customer type (individual/organization)
    screen: CustomerForm
    validation: Required selection
  - step: 2
    action: Enter basic info (name, email, phone)
    screen: CustomerForm
    validation: Required fields, email format
  - step: 3
    action: System checks for duplicates
    screen: DuplicateModal
    validation: Match score threshold
  - step: 4
    if: Duplicates found
    action: User reviews potential matches
    options: [Merge, Create Anyway, Cancel]
  - step: 5
    action: Assign owner (defaults to current user)
    screen: CustomerForm
    validation: Owner must be active user
  - step: 6
    action: Save customer record
    outcome: Customer created with status=prospect
  - step: 7
    action: Show customer detail page
    screen: CustomerDetail
alternate_paths:
  - name: Bulk Import
    steps:
      - Upload CSV/Excel
      - Map columns to fields
      - Preview import
      - Run duplicate check on batch
      - Review exceptions
      - Confirm import
```

#### WF-CM-002: Merge Duplicate Customers

```yaml
workflow_id: WF-CM-002
name: Merge Duplicate Customers
trigger: User selects multiple customers and clicks "Merge"
actors: [Admin, Sales Manager]
preconditions:
  - At least 2 customers selected
  - User has merge permission
happy_path:
  - step: 1
    action: Select primary (surviving) record
    screen: MergeWizard
  - step: 2
    action: Review field-by-field comparison
    screen: MergeWizard
    notes: Show which value will be kept
  - step: 3
    action: Choose values for conflicting fields
    screen: MergeWizard
  - step: 4
    action: Preview merged record
    screen: MergePreview
  - step: 5
    action: Confirm merge
    outcome: |
      - Secondary records soft-deleted
      - All child records (contacts, interactions) moved to primary
      - Audit log entry created
      - External ID mappings preserved
postconditions:
  - Secondary customer IDs redirect to primary
  - No orphaned child records
  - Merge is reversible for 30 days
```

#### WF-CM-003: Customer Self-Service Profile Update

```yaml
workflow_id: WF-CM-003
name: Customer Self-Service Profile Update
trigger: Customer logs into portal and edits profile
actors: [Customer]
happy_path:
  - step: 1
    action: Customer views current profile
    screen: CustomerPortal/Profile
  - step: 2
    action: Customer edits allowed fields
    screen: CustomerPortal/ProfileEdit
    validation: Only non-sensitive fields editable
  - step: 3
    if: Email changed
    action: Send verification email to new address
  - step: 4
    action: Save changes
    outcome: Updated fields, audit log entry
security_notes:
  - Some fields require admin approval (legal name, tax ID)
  - Email changes require verification
  - All changes logged with IP address
```

### Edge Case Library

| Edge Case | Detection | Resolution | Priority |
|-----------|-----------|------------|----------|
| **Duplicate on create** | Email/phone match score > 80% | Show merge dialog, allow "create anyway" | P1 |
| **Customer without contacts** | Organization with contacts.count = 0 | Warning banner, suggest adding contact | P2 |
| **Circular hierarchy** | Parent chain loops back to self | Block assignment, show error | P1 |
| **Inactive owner** | Owner user is deactivated | Auto-reassign to manager or pool | P1 |
| **International phone format** | Phone doesn't match expected pattern | Accept any format, normalize on save | P2 |
| **Missing required for export** | Tax ID required for invoicing | Block invoice creation, show error | P1 |
| **PII in notes field** | Free-text contains SSN/credit card pattern | Flag for review, warn on save | P2 |
| **Bulk delete request** | GDPR deletion affects 100+ records | Queue for batch processing, notify admin | P2 |

### Screens

| Screen | Purpose | Key Components |
|--------|---------|----------------|
| CustomerList | Browse/search customers | Search bar, filters, sortable table, bulk actions |
| CustomerDetail | View single customer | Header, tabs (Overview, Contacts, Interactions, Addresses), quick actions |
| CustomerForm | Create/edit customer | Form fields, duplicate warning, owner selector |
| ContactForm | Create/edit contact | Form fields, customer picker, communication preferences |
| AccountHierarchy | View parent/child tree | Tree visualization, drag-drop reorganization |
| MergeWizard | Merge duplicates | Side-by-side comparison, field selector |
| ImportWizard | Bulk import | File upload, column mapping, preview, progress |

---

## Package: interaction_tracking

**Purpose**: Log and retrieve all touchpoints between your organization and customers.

### Discovery Questions (R2/R3)

**Entity Questions (R2)**:
1. "What types of interactions do you track?" (email, call, meeting, note, chat)
2. "Are interactions automatically logged or manually entered?"
3. "Do you track interaction sentiment or outcome?"
4. "Can interactions be associated with multiple entities?" (customer + opportunity)
5. "How long do you retain interaction history?"
6. "Do you need to track interaction duration?" (call length, meeting time)

**Workflow Questions (R3)**:
1. "How do sales/support teams log calls?"
2. "Should emails be auto-captured from Gmail/Outlook?"
3. "Can customers see their interaction history?"
4. "How do you search past interactions?"
5. "Do you need call recording playback?"

### Entity Templates

#### Interaction

```json
{
  "id": "data.crm.interaction",
  "name": "Interaction",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity", "audit-sensitive"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],
  "parallel_hints": ["data.crm.note"],

  "spec": {
    "purpose": "Single touchpoint between organization and customer.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "contact_id", "type": "uuid", "required": false, "references": "Contact" },
      { "name": "interaction_type", "type": "enum", "values": ["email", "call", "meeting", "chat", "sms", "social", "in_person", "other"], "required": true },
      { "name": "direction", "type": "enum", "values": ["inbound", "outbound"], "required": true },
      { "name": "subject", "type": "string", "required": false, "max_length": 500 },
      { "name": "description", "type": "text", "required": false },
      { "name": "occurred_at", "type": "timestamp", "required": true },
      { "name": "duration_minutes", "type": "integer", "required": false },
      { "name": "outcome", "type": "enum", "values": ["successful", "no_answer", "left_message", "bounced", "follow_up_needed", "completed"], "required": false },
      { "name": "sentiment", "type": "enum", "values": ["positive", "neutral", "negative"], "required": false },
      { "name": "source", "type": "enum", "values": ["manual", "email_sync", "phone_integration", "calendar_sync", "api"], "required": true },
      { "name": "external_id", "type": "string", "required": false, "notes": "ID from integrated system" },
      { "name": "created_by", "type": "uuid", "required": true, "references": "User" },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "relationships": [
      { "name": "customer", "type": "many-to-one", "target": "Customer" },
      { "name": "contact", "type": "many-to-one", "target": "Contact" },
      { "name": "attachments", "type": "one-to-many", "target": "Attachment" },
      { "name": "related_entities", "type": "polymorphic", "targets": ["Opportunity", "Case", "WorkOrder"] }
    ],
    "indexes": [
      { "fields": ["customer_id", "occurred_at"], "type": "btree", "order": "desc" },
      { "fields": ["contact_id", "occurred_at"], "type": "btree", "order": "desc" },
      { "fields": ["interaction_type", "occurred_at"], "type": "btree" },
      { "fields": ["external_id"], "type": "unique", "where": "external_id IS NOT NULL" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Interactions appear in customer timeline", "verification_method": "manual" },
      { "id": "AC-2", "description": "Duplicate detection for synced interactions", "verification_method": "automated" },
      { "id": "AC-3", "description": "Search works across subject and description", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.interaction_tracking",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Note

```json
{
  "id": "data.crm.note",
  "name": "Note",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Freeform notes attached to customers or other entities.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": false, "references": "Customer" },
      { "name": "related_type", "type": "string", "required": false, "notes": "Polymorphic: Contact, Opportunity, etc." },
      { "name": "related_id", "type": "uuid", "required": false },
      { "name": "title", "type": "string", "required": false, "max_length": 200 },
      { "name": "content", "type": "text", "required": true },
      { "name": "is_pinned", "type": "boolean", "default": false },
      { "name": "visibility", "type": "enum", "values": ["private", "team", "all"], "default": "team" },
      { "name": "created_by", "type": "uuid", "required": true, "references": "User" },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "indexes": [
      { "fields": ["customer_id", "created_at"], "type": "btree", "order": "desc" },
      { "fields": ["related_type", "related_id"], "type": "btree" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Notes searchable via full-text search", "verification_method": "automated" },
      { "id": "AC-2", "description": "Visibility rules enforced", "verification_method": "automated" },
      { "id": "AC-3", "description": "Pinned notes appear first in timeline", "verification_method": "manual" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.interaction_tracking",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Activity

```json
{
  "id": "data.crm.activity",
  "name": "Activity",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Scheduled activities (tasks, follow-ups) for customer engagement.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": false, "references": "Customer" },
      { "name": "contact_id", "type": "uuid", "required": false, "references": "Contact" },
      { "name": "activity_type", "type": "enum", "values": ["call", "email", "meeting", "task", "follow_up", "demo"], "required": true },
      { "name": "subject", "type": "string", "required": true, "max_length": 300 },
      { "name": "description", "type": "text", "required": false },
      { "name": "due_date", "type": "timestamp", "required": true },
      { "name": "reminder_at", "type": "timestamp", "required": false },
      { "name": "priority", "type": "enum", "values": ["low", "normal", "high", "urgent"], "default": "normal" },
      { "name": "status", "type": "enum", "values": ["pending", "in_progress", "completed", "cancelled"], "default": "pending" },
      { "name": "completed_at", "type": "timestamp", "required": false },
      { "name": "assigned_to", "type": "uuid", "required": true, "references": "User" },
      { "name": "created_by", "type": "uuid", "required": true, "references": "User" },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "relationships": [
      { "name": "customer", "type": "many-to-one", "target": "Customer" },
      { "name": "contact", "type": "many-to-one", "target": "Contact" },
      { "name": "result_interaction", "type": "one-to-one", "target": "Interaction", "notes": "Created when activity completes" }
    ],
    "indexes": [
      { "fields": ["assigned_to", "status", "due_date"], "type": "btree" },
      { "fields": ["customer_id", "due_date"], "type": "btree" },
      { "fields": ["due_date"], "type": "btree", "where": "status = 'pending'" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Overdue activities highlighted", "verification_method": "manual" },
      { "id": "AC-2", "description": "Completing activity creates interaction record", "verification_method": "automated" },
      { "id": "AC-3", "description": "Reminders trigger notifications", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.interaction_tracking",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Communication

```json
{
  "id": "data.crm.communication",
  "name": "Communication",
  "type": "data",
  "namespace": "crm",
  "tags": ["integration-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.interaction"],

  "spec": {
    "purpose": "Email/SMS messages with full content for reference.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "interaction_id", "type": "uuid", "required": true, "references": "Interaction" },
      { "name": "channel", "type": "enum", "values": ["email", "sms", "chat"], "required": true },
      { "name": "from_address", "type": "string", "required": true },
      { "name": "to_addresses", "type": "array", "items": "string", "required": true },
      { "name": "cc_addresses", "type": "array", "items": "string", "required": false },
      { "name": "subject", "type": "string", "required": false, "max_length": 1000 },
      { "name": "body_text", "type": "text", "required": false },
      { "name": "body_html", "type": "text", "required": false },
      { "name": "message_id", "type": "string", "required": false, "notes": "Email message ID for threading" },
      { "name": "thread_id", "type": "string", "required": false },
      { "name": "sent_at", "type": "timestamp", "required": true },
      { "name": "opened_at", "type": "timestamp", "required": false },
      { "name": "clicked_at", "type": "timestamp", "required": false },
      { "name": "bounced", "type": "boolean", "default": false },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Email threading works correctly", "verification_method": "automated" },
      { "id": "AC-2", "description": "Open/click tracking updates records", "verification_method": "automated" },
      { "id": "AC-3", "description": "Bounced emails update contact status", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.interaction_tracking",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

### Workflow Templates

#### WF-IT-001: Log Manual Interaction

```yaml
workflow_id: WF-IT-001
name: Log Manual Interaction
trigger: User clicks "Log Interaction" from customer or global
actors: [Sales Rep, Support Rep]
happy_path:
  - step: 1
    action: Select interaction type (call, meeting, etc.)
    screen: InteractionForm
  - step: 2
    action: Select customer (if not already in context)
    screen: InteractionForm
    validation: Customer required
  - step: 3
    action: Optionally select specific contact
    screen: InteractionForm
  - step: 4
    action: Enter date/time and duration
    screen: InteractionForm
    default: Now, auto-populate duration for calls
  - step: 5
    action: Enter subject and description
    screen: InteractionForm
  - step: 6
    action: Select outcome and sentiment (optional)
    screen: InteractionForm
  - step: 7
    action: Link to related records (opportunity, case)
    screen: InteractionForm
  - step: 8
    action: Save interaction
    outcome: Appears in customer timeline
quick_log_variant:
  - Voice memo transcription
  - Auto-populate from calendar meeting
  - One-click "Call completed" button
```

#### WF-IT-002: Auto-Sync Email

```yaml
workflow_id: WF-IT-002
name: Auto-Sync Email
trigger: Email received/sent matching customer domain or contact email
actors: [System]
happy_path:
  - step: 1
    action: Email integration detects new message
    source: Gmail API / Outlook API / IMAP
  - step: 2
    action: Match email addresses to contacts
    matching_logic: |
      - Direct email match to Contact
      - Domain match to Customer
      - Thread ID match to existing conversation
  - step: 3
    if: Match found
    action: Create Interaction + Communication record
  - step: 4
    if: No match
    action: Queue for manual review or discard
  - step: 5
    action: Extract attachments if present
    storage: Link to document storage
  - step: 6
    action: Run sentiment analysis (if enabled)
    ai_touchpoint: Sentiment classification
exclusions:
  - System notifications (noreply@)
  - Internal emails (same domain)
  - Opt-out patterns (unsubscribe)
rate_limits:
  - Max 1000 emails per sync
  - Deduplicate by message_id
```

#### WF-IT-003: Create Follow-Up Activity

```yaml
workflow_id: WF-IT-003
name: Create Follow-Up Activity
trigger: User clicks "Schedule Follow-Up" after interaction
actors: [Sales Rep]
happy_path:
  - step: 1
    action: Pre-fill activity type from interaction
    screen: ActivityForm
  - step: 2
    action: Set due date
    screen: ActivityForm
    default: Tomorrow, or detect from notes ("call next week")
  - step: 3
    action: Enter task description
    screen: ActivityForm
    default: Pre-fill from interaction notes
  - step: 4
    action: Set reminder
    screen: ActivityForm
  - step: 5
    action: Assign (defaults to self)
    screen: ActivityForm
  - step: 6
    action: Save activity
    outcome: Activity linked to customer, appears in My Tasks
automation_option:
  - AI extracts follow-up dates from conversation
  - Auto-create activity with one click
```

### Edge Case Library

| Edge Case | Detection | Resolution | Priority |
|-----------|-----------|------------|----------|
| **Duplicate email sync** | Same message_id already exists | Skip, dedupe by message_id | P1 |
| **Email from unknown sender** | No matching contact/customer | Create interaction in "unmatched" queue | P2 |
| **Large attachment** | Attachment > 25MB | Store reference only, link to cloud storage | P2 |
| **Thread reconstruction** | Out-of-order email arrival | Use In-Reply-To and References headers | P2 |
| **Timezone mismatch** | Call logged in wrong timezone | Store all times in UTC, display in user TZ | P1 |
| **Retroactive logging** | Interaction from 2 weeks ago | Allow backdating, flag if > 30 days | P2 |
| **Bulk interaction delete** | Compliance request to purge | Require admin approval, audit log | P1 |
| **Offline activity completion** | Mobile completes activity without signal | Sync on reconnect, handle conflicts | P2 |

### Screens

| Screen | Purpose | Key Components |
|--------|---------|----------------|
| ActivityTimeline | Chronological interaction history | Infinite scroll, filters, search, grouped by date |
| InteractionForm | Log new interaction | Type selector, customer/contact picker, outcome |
| NoteEditor | Create/edit notes | Rich text editor, @mentions, attachments |
| InteractionLog | Tabular view of interactions | Sortable columns, export, bulk actions |
| MyActivities | User's scheduled activities | Today/upcoming/overdue sections, quick complete |
| EmailViewer | View synced email content | Threading, attachments, reply link |

---

## Package: lifecycle

**Purpose**: Track customer journey stages, scoring, and segmentation for targeting and retention.

### Discovery Questions (R2/R3)

**Entity Questions (R2)**:
1. "What stages does a customer go through?" (lead, prospect, customer, churned)
2. "How do you define an 'active' customer?"
3. "Do you score or rank customers?" (health score, value tier)
4. "What segments do you use?" (industry, size, behavior)
5. "Do you track customer milestones?" (first purchase, renewal)

**Workflow Questions (R3)**:
1. "How does a lead become a customer?"
2. "What triggers a 'churn risk' alert?"
3. "How do you handle re-engagement campaigns?"
4. "Who reviews customer health scores?"
5. "What actions does a stage change trigger?"

### Entity Templates

#### LifecycleStage

```json
{
  "id": "data.crm.lifecycle_stage",
  "name": "LifecycleStage",
  "type": "data",
  "namespace": "crm",
  "tags": ["configuration"],
  "status": "discovered",

  "requires": ["infrastructure.core.database"],

  "spec": {
    "purpose": "Defines available customer lifecycle stages.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "name", "type": "string", "required": true, "max_length": 100 },
      { "name": "display_order", "type": "integer", "required": true },
      { "name": "category", "type": "enum", "values": ["pre_customer", "customer", "post_customer"], "required": true },
      { "name": "color", "type": "string", "required": false, "notes": "Hex color for UI" },
      { "name": "description", "type": "text", "required": false },
      { "name": "is_active", "type": "boolean", "default": true },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "default_stages": [
      { "name": "Lead", "category": "pre_customer", "order": 1 },
      { "name": "Prospect", "category": "pre_customer", "order": 2 },
      { "name": "Opportunity", "category": "pre_customer", "order": 3 },
      { "name": "Customer", "category": "customer", "order": 4 },
      { "name": "At Risk", "category": "customer", "order": 5 },
      { "name": "Churned", "category": "post_customer", "order": 6 },
      { "name": "Won Back", "category": "customer", "order": 7 }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Stages are orderable", "verification_method": "manual" },
      { "id": "AC-2", "description": "Cannot delete stage with assigned customers", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### CustomerLifecycle

```json
{
  "id": "data.crm.customer_lifecycle",
  "name": "CustomerLifecycle",
  "type": "data",
  "namespace": "crm",
  "tags": ["core-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer", "data.crm.lifecycle_stage"],

  "spec": {
    "purpose": "Tracks a customer's current and historical lifecycle stages.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "current_stage_id", "type": "uuid", "required": true, "references": "LifecycleStage" },
      { "name": "entered_stage_at", "type": "timestamp", "required": true },
      { "name": "previous_stage_id", "type": "uuid", "required": false, "references": "LifecycleStage" },
      { "name": "first_purchase_date", "type": "date", "required": false },
      { "name": "last_purchase_date", "type": "date", "required": false },
      { "name": "total_revenue", "type": "decimal", "required": false, "default": 0 },
      { "name": "purchase_count", "type": "integer", "required": false, "default": 0 },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "relationships": [
      { "name": "customer", "type": "one-to-one", "target": "Customer" },
      { "name": "current_stage", "type": "many-to-one", "target": "LifecycleStage" },
      { "name": "history", "type": "one-to-many", "target": "LifecycleHistory" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Stage change creates history record", "verification_method": "automated" },
      { "id": "AC-2", "description": "Revenue/purchase metrics update from Financial module", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### LifecycleHistory

```json
{
  "id": "data.crm.lifecycle_history",
  "name": "LifecycleHistory",
  "type": "data",
  "namespace": "crm",
  "tags": ["audit-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer_lifecycle"],

  "spec": {
    "purpose": "Audit trail of lifecycle stage changes.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "from_stage_id", "type": "uuid", "required": false, "references": "LifecycleStage" },
      { "name": "to_stage_id", "type": "uuid", "required": true, "references": "LifecycleStage" },
      { "name": "changed_at", "type": "timestamp", "required": true },
      { "name": "changed_by", "type": "uuid", "required": false, "references": "User", "notes": "Null if system-triggered" },
      { "name": "reason", "type": "string", "required": false, "max_length": 500 },
      { "name": "trigger", "type": "enum", "values": ["manual", "rule", "api", "system"], "required": true }
    ],
    "indexes": [
      { "fields": ["customer_id", "changed_at"], "type": "btree", "order": "desc" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "History is immutable (no updates/deletes)", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Segment

```json
{
  "id": "data.crm.segment",
  "name": "Segment",
  "type": "data",
  "namespace": "crm",
  "tags": ["configuration"],
  "status": "discovered",

  "requires": ["infrastructure.core.database"],

  "spec": {
    "purpose": "Dynamic or static customer groupings for targeting.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "name", "type": "string", "required": true, "max_length": 100 },
      { "name": "description", "type": "text", "required": false },
      { "name": "type", "type": "enum", "values": ["static", "dynamic"], "required": true },
      { "name": "criteria", "type": "json", "required": false, "notes": "For dynamic segments" },
      { "name": "member_count", "type": "integer", "required": false, "notes": "Cached count" },
      { "name": "last_calculated_at", "type": "timestamp", "required": false },
      { "name": "is_active", "type": "boolean", "default": true },
      { "name": "created_by", "type": "uuid", "required": true, "references": "User" },
      { "name": "created_at", "type": "timestamp", "required": true },
      { "name": "updated_at", "type": "timestamp", "required": true }
    ],
    "criteria_example": {
      "type": "dynamic",
      "criteria": {
        "all": [
          { "field": "lifecycle.current_stage.category", "operator": "eq", "value": "customer" },
          { "field": "lifecycle.last_purchase_date", "operator": "gte", "value": "now-90d" },
          { "field": "account.industry", "operator": "in", "value": ["technology", "finance"] }
        ]
      }
    },
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Dynamic segments recalculate on schedule", "verification_method": "automated" },
      { "id": "AC-2", "description": "Segment membership exportable", "verification_method": "manual" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Score

```json
{
  "id": "data.crm.score",
  "name": "Score",
  "type": "data",
  "namespace": "crm",
  "tags": ["computed-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Computed scores for customers (health, engagement, value).",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "score_type", "type": "enum", "values": ["health", "engagement", "value", "churn_risk", "upsell_potential"], "required": true },
      { "name": "score_value", "type": "integer", "required": true, "min": 0, "max": 100 },
      { "name": "grade", "type": "enum", "values": ["A", "B", "C", "D", "F"], "required": false },
      { "name": "factors", "type": "json", "required": false, "notes": "Breakdown of score components" },
      { "name": "calculated_at", "type": "timestamp", "required": true },
      { "name": "valid_until", "type": "timestamp", "required": false }
    ],
    "factors_example": {
      "score_type": "health",
      "factors": {
        "login_frequency": { "weight": 0.2, "raw": 85, "weighted": 17 },
        "support_tickets": { "weight": 0.2, "raw": 90, "weighted": 18 },
        "payment_history": { "weight": 0.3, "raw": 100, "weighted": 30 },
        "feature_adoption": { "weight": 0.3, "raw": 60, "weighted": 18 }
      }
    },
    "indexes": [
      { "fields": ["customer_id", "score_type"], "type": "unique" },
      { "fields": ["score_type", "score_value"], "type": "btree", "order": "desc" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Scores recalculate on schedule or trigger", "verification_method": "automated" },
      { "id": "AC-2", "description": "Score changes trigger alerts when threshold crossed", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Journey

```json
{
  "id": "data.crm.journey",
  "name": "Journey",
  "type": "data",
  "namespace": "crm",
  "tags": ["tracking-entity"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Tracks customer milestones and key events.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "milestone_type", "type": "enum", "values": ["first_contact", "first_purchase", "onboarding_complete", "renewal", "upsell", "referral_made", "support_escalation", "churn_signal", "win_back"], "required": true },
      { "name": "occurred_at", "type": "timestamp", "required": true },
      { "name": "details", "type": "json", "required": false },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "indexes": [
      { "fields": ["customer_id", "occurred_at"], "type": "btree" },
      { "fields": ["milestone_type", "occurred_at"], "type": "btree" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Milestones appear in customer timeline", "verification_method": "manual" },
      { "id": "AC-2", "description": "Key milestones trigger automations", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "crm.lifecycle",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

### Workflow Templates

#### WF-LC-001: Advance Lifecycle Stage

```yaml
workflow_id: WF-LC-001
name: Advance Lifecycle Stage
trigger: Manual change or automated rule
actors: [Sales Rep, System]
happy_path:
  - step: 1
    action: Trigger detected (manual or rule match)
  - step: 2
    action: Validate stage transition is allowed
    validation: Check transition rules (can't skip stages, etc.)
  - step: 3
    if: Transition requires approval
    action: Route to approver
  - step: 4
    action: Update customer_lifecycle.current_stage
  - step: 5
    action: Create lifecycle_history record
  - step: 6
    action: Fire stage change webhook/event
  - step: 7
    action: Trigger downstream automations
    examples: |
      - Lead -> Prospect: Add to nurture campaign
      - Prospect -> Customer: Trigger onboarding
      - Customer -> At Risk: Alert account manager
      - Customer -> Churned: Schedule win-back sequence
stage_transition_rules:
  - from: Lead
    allowed_to: [Prospect, Churned]
  - from: Prospect
    allowed_to: [Opportunity, Lead, Churned]
  - from: Opportunity
    allowed_to: [Customer, Prospect, Churned]
  - from: Customer
    allowed_to: [At Risk, Churned]
  - from: At Risk
    allowed_to: [Customer, Churned]
  - from: Churned
    allowed_to: [Won Back]
  - from: Won Back
    allowed_to: [Customer, Churned]
```

#### WF-LC-002: Calculate Customer Health Score

```yaml
workflow_id: WF-LC-002
name: Calculate Customer Health Score
trigger: Scheduled (daily) or on-demand
actors: [System]
happy_path:
  - step: 1
    action: Fetch scoring factors
    factors:
      - Recent login activity (from auth logs)
      - Support ticket volume/sentiment (from support module)
      - Payment history (from financial module)
      - Feature adoption (from analytics)
      - NPS/survey responses (if available)
  - step: 2
    action: Apply scoring model
    calculation: Weighted average of normalized factors
  - step: 3
    action: Determine grade (A-F)
    thresholds:
      A: 80-100
      B: 60-79
      C: 40-59
      D: 20-39
      F: 0-19
  - step: 4
    action: Store score with factor breakdown
  - step: 5
    if: Score crosses threshold
    action: Trigger alerts
    thresholds:
      - Drops below 40: Alert account manager
      - Drops below 20: Escalate to leadership
      - Rises above 80: Upsell opportunity flag
  - step: 6
    action: Update segment memberships based on new score
ai_model_option:
  - Train on historical churn data
  - Predict churn probability
  - Identify leading indicators
```

#### WF-LC-003: Build Dynamic Segment

```yaml
workflow_id: WF-LC-003
name: Build Dynamic Segment
trigger: Segment created or edited
actors: [Marketing, Sales Manager]
happy_path:
  - step: 1
    action: Define segment criteria
    screen: SegmentBuilder
    examples:
      - Industry = Technology AND Revenue > $1M
      - Last purchase > 90 days AND Health score < 50
      - Lifecycle stage = Customer AND NOT in segment "Enterprise"
  - step: 2
    action: Preview matching customers
    screen: SegmentPreview
  - step: 3
    action: Save segment
    outcome: Segment stored with criteria
  - step: 4
    action: Schedule recalculation
    frequency: Daily or on-demand
  - step: 5
    action: System evaluates all customers against criteria
  - step: 6
    action: Update cached member count
recalculation_optimization:
  - Incremental: Only re-evaluate changed customers
  - Full: Re-evaluate all (weekly or on criteria change)
```

### Edge Case Library

| Edge Case | Detection | Resolution | Priority |
|-----------|-----------|------------|----------|
| **Backward stage movement** | Attempt to go from Customer to Lead | Block unless admin override | P1 |
| **Score calculation timeout** | > 10 min for batch scoring | Process in chunks, continue on timeout | P2 |
| **Conflicting segment rules** | Customer matches mutually exclusive segments | Priority ordering, warn admin | P2 |
| **Stale score** | Score not updated in > 7 days | Flag for recalculation, show warning | P2 |
| **No scoring data** | New customer with no history | Assign default score, flag for review | P2 |
| **Churn during renewal** | Customer churns while renewal in progress | Alert sales, pause renewal workflow | P1 |
| **Win-back re-churn** | Won back customer churns again quickly | Flag as high-risk, different handling | P2 |
| **Segment explosion** | Dynamic segment matches 100K+ customers | Paginate UI, async export | P2 |

### Screens

| Screen | Purpose | Key Components |
|--------|---------|----------------|
| LifecycleView | View customer's journey | Stage indicator, history timeline, milestones |
| SegmentBuilder | Create/edit segments | Criteria builder, preview, schedule config |
| ScoringRules | Configure scoring model | Factor weights, thresholds, grade mapping |
| SegmentList | Browse segments | Table with member counts, last calculated |
| HealthDashboard | Overview of customer health | Score distribution, at-risk list, trends |
| JourneyVisualization | Visual customer journey | Timeline with milestones, touchpoints |

### AI Touchpoints

| Touchpoint | Input | Output | Use Case |
|------------|-------|--------|----------|
| **Next Best Action** | Customer profile, history, context | Recommended action (call, email, offer) | Sales rep guidance |
| **Churn Risk Prediction** | Behavioral signals, engagement data | Probability score, contributing factors | Proactive retention |
| **Upsell Opportunity** | Purchase history, product usage | Product recommendations, timing | Revenue growth |
| **Sentiment Analysis** | Interaction text, support tickets | Sentiment score, key topics | Health scoring input |
| **Win-Back Timing** | Churn date, past behavior, market signals | Optimal re-engagement timing | Recovery campaigns |

---

## Customer 360 View Patterns

### Purpose

A unified view of all customer information across modules - the "single source of truth" for customer-facing teams.

### Data Aggregation Strategy

```yaml
customer_360:
  core_profile:
    source: crm.customer_management
    fields: [name, type, status, owner, addresses]

  contacts:
    source: crm.customer_management
    fields: [all contacts with roles]

  lifecycle:
    source: crm.lifecycle
    fields: [current_stage, scores, segments, journey_milestones]

  financial_summary:
    source: financial (cross-module)
    fields:
      - total_revenue (lifetime)
      - outstanding_balance
      - payment_status
      - recent_invoices (last 5)

  interactions:
    source: crm.interaction_tracking
    aggregation:
      - last_interaction_date
      - interaction_count_30d
      - last_5_interactions

  opportunities:
    source: sales (cross-module)
    fields: [open_opportunities, pipeline_value, win_rate]

  support:
    source: support (cross-module)
    fields: [open_tickets, avg_response_time, satisfaction_score]

  field_service:
    source: field_service (cross-module)
    fields: [scheduled_visits, completed_jobs, equipment_list]
```

### Timeline Construction

```yaml
timeline_sources:
  - entity: Interaction
    display: "{{ type }} - {{ subject }}"
    icon_by_type: { email: envelope, call: phone, meeting: calendar }

  - entity: Note
    display: "Note: {{ title }}"
    icon: sticky-note

  - entity: Journey
    display: "Milestone: {{ milestone_type }}"
    icon: flag
    highlight: true

  - entity: Invoice
    source_module: financial
    display: "Invoice {{ number }} - {{ amount }}"
    icon: file-invoice

  - entity: Order
    source_module: sales
    display: "Order {{ number }} - {{ status }}"
    icon: shopping-cart

  - entity: WorkOrder
    source_module: field_service
    display: "Service: {{ description }}"
    icon: wrench

  - entity: Case
    source_module: support
    display: "Ticket #{{ number }}: {{ subject }}"
    icon: ticket

timeline_config:
  default_period: 90_days
  grouping: by_day
  filters: [type, date_range, actor]
  max_items_initial: 50
  infinite_scroll: true
```

### Cross-Module Integration Points

| Integration | Direction | Trigger | Data Flow |
|-------------|-----------|---------|-----------|
| CRM -> Financial | Push | Invoice created | Link customer_id to invoice |
| Financial -> CRM | Pull | Payment received | Update lifecycle metrics |
| CRM -> Sales | Push | Lead qualified | Create opportunity |
| Sales -> CRM | Pull | Deal closed | Update lifecycle stage |
| CRM -> Field Service | Push | Service requested | Create work order with customer context |
| Field Service -> CRM | Pull | Job completed | Create interaction record |
| CRM -> Communication | Push | Email sent | Log as interaction |
| Communication -> CRM | Pull | Email received | Auto-create interaction |

---

## Privacy Considerations

### GDPR Compliance Patterns

#### Data Subject Rights Implementation

| Right | Implementation | CRM Impact |
|-------|----------------|------------|
| **Right to Access** | Export all customer data | API endpoint + UI for data export |
| **Right to Rectification** | Allow data correction | Standard edit workflows |
| **Right to Erasure** | Delete or anonymize | Soft delete + anonymization job |
| **Right to Restriction** | Flag to limit processing | `processing_restricted` flag |
| **Right to Portability** | Machine-readable export | JSON/CSV export in standard format |
| **Right to Object** | Opt-out of processing | `do_not_process` flag, honored by all modules |

#### Entity: ConsentRecord

```json
{
  "id": "data.crm.consent_record",
  "name": "ConsentRecord",
  "type": "data",
  "namespace": "crm",
  "tags": ["compliance", "pii"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Track consent for data processing activities.",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "consent_type", "type": "enum", "values": ["marketing_email", "marketing_sms", "profiling", "third_party_sharing", "analytics", "essential_communications"], "required": true },
      { "name": "granted", "type": "boolean", "required": true },
      { "name": "granted_at", "type": "timestamp", "required": false },
      { "name": "revoked_at", "type": "timestamp", "required": false },
      { "name": "source", "type": "enum", "values": ["web_form", "email_link", "phone", "in_person", "api", "import"], "required": true },
      { "name": "ip_address", "type": "string", "required": false },
      { "name": "legal_basis", "type": "enum", "values": ["consent", "contract", "legal_obligation", "vital_interest", "public_task", "legitimate_interest"], "required": true },
      { "name": "privacy_policy_version", "type": "string", "required": false },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "indexes": [
      { "fields": ["customer_id", "consent_type"], "type": "btree" }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Consent records are immutable - new record on change", "verification_method": "automated" },
      { "id": "AC-2", "description": "Marketing blocked when consent not granted", "verification_method": "automated" },
      { "id": "AC-3", "description": "Audit trail of all consent changes", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.compliance",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

#### Entity: DeletionRequest

```json
{
  "id": "data.crm.deletion_request",
  "name": "DeletionRequest",
  "type": "data",
  "namespace": "crm",
  "tags": ["compliance"],
  "status": "discovered",

  "requires": ["infrastructure.core.database", "data.crm.customer"],

  "spec": {
    "purpose": "Track and process data deletion requests (GDPR Article 17).",
    "fields": [
      { "name": "id", "type": "uuid", "required": true },
      { "name": "customer_id", "type": "uuid", "required": true, "references": "Customer" },
      { "name": "request_type", "type": "enum", "values": ["full_deletion", "anonymization", "partial_deletion"], "required": true },
      { "name": "requested_at", "type": "timestamp", "required": true },
      { "name": "requested_via", "type": "enum", "values": ["email", "web_form", "phone", "legal", "api"], "required": true },
      { "name": "verification_method", "type": "enum", "values": ["email_confirmed", "identity_verified", "legal_order"], "required": true },
      { "name": "status", "type": "enum", "values": ["pending_verification", "verified", "in_progress", "completed", "rejected", "blocked"], "required": true },
      { "name": "rejection_reason", "type": "text", "required": false, "notes": "Legal retention requirement, etc." },
      { "name": "deadline", "type": "timestamp", "required": true, "notes": "GDPR requires 30 days" },
      { "name": "completed_at", "type": "timestamp", "required": false },
      { "name": "affected_records", "type": "json", "required": false, "notes": "List of deleted/anonymized entities" },
      { "name": "processed_by", "type": "uuid", "required": false, "references": "User" },
      { "name": "created_at", "type": "timestamp", "required": true }
    ],
    "acceptance_criteria": [
      { "id": "AC-1", "description": "Deadline auto-set to 30 days from request", "verification_method": "automated" },
      { "id": "AC-2", "description": "Overdue requests escalate to DPO", "verification_method": "automated" },
      { "id": "AC-3", "description": "Cannot delete data with legal hold", "verification_method": "automated" }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "crm.compliance",
    "created_at": null,
    "updated_at": null,
    "version": 1
  }
}
```

### Data Retention Policies

```yaml
retention_policies:
  active_customers:
    retention: Indefinite
    review: Annual
    basis: Contract performance

  churned_customers:
    retention: 7 years
    basis: Legal/tax requirements
    after_expiry: Anonymize

  interaction_data:
    retention: 3 years
    basis: Legitimate interest
    after_expiry: Delete or anonymize

  consent_records:
    retention: 7 years after last activity
    basis: Proof of consent
    after_expiry: Archive

  marketing_data:
    retention: Until consent revoked + 30 days
    basis: Consent
    after_expiry: Delete

  audit_logs:
    retention: 7 years
    basis: Legal requirement
    after_expiry: Archive to cold storage
```

### Anonymization Strategy

```yaml
anonymization_rules:
  Customer:
    display_name: "Deleted Customer {{ hash(id)[:8] }}"
    email: null
    phone: null
    external_id: null
    preserve: [id, type, created_at, status=deleted]

  Contact:
    first_name: "Deleted"
    last_name: "Contact"
    email: null
    phone: null
    preserve: [id, customer_id, created_at]

  Address:
    street_line_1: "Deleted"
    street_line_2: null
    city: "[REDACTED]"
    postal_code: null
    preserve: [id, customer_id, country]

  Interaction:
    subject: "[REDACTED]"
    description: "[Content removed per deletion request]"
    preserve: [id, customer_id, interaction_type, occurred_at]

  Communication:
    action: Full delete (no preserve)
```

### Consent Management Workflow

```yaml
workflow_id: WF-PRIV-001
name: Manage Customer Consent
trigger: Customer submits preferences or admin updates
actors: [Customer, Admin]
happy_path:
  - step: 1
    action: Display current consent status
    screen: ConsentPreferences
  - step: 2
    action: Customer toggles consent options
    options:
      - Marketing emails
      - Marketing SMS
      - Third-party sharing
      - Profiling/personalization
  - step: 3
    action: Record consent change
    outcome: New ConsentRecord created (immutable)
  - step: 4
    if: Consent revoked
    action: Propagate to downstream systems
    systems: [Email marketing, Analytics, Ad platforms]
  - step: 5
    action: Send confirmation
    outcome: Email confirming preference changes
```

---

## Integration Points

### Email Integration

```yaml
integration_id: INT-CRM-EMAIL
name: Email Provider Integration
providers: [Gmail, Outlook, Generic IMAP]
capabilities:
  - Sync inbound/outbound emails
  - Match emails to customers/contacts
  - Extract attachments
  - Track opens and clicks (with consent)

configuration:
  sync_direction: bidirectional
  sync_frequency: 5 minutes or webhook
  historical_days: 90

matching_rules:
  - Match by: Contact.email (exact)
  - Match by: Customer domain (if no contact match)
  - Match by: Thread ID (for replies)

privacy_considerations:
  - Only sync emails matching known customers
  - Respect do_not_contact flags
  - Exclude internal emails
```

### Calendar Integration

```yaml
integration_id: INT-CRM-CALENDAR
name: Calendar Integration
providers: [Google Calendar, Outlook Calendar]
capabilities:
  - Sync meetings with customers
  - Create activities from calendar events
  - Block availability for scheduling

sync_rules:
  - Events with customer contacts -> Create Interaction
  - Canceled events -> Update Activity status
  - Recurring events -> Create individual Interaction instances
```

### Phone System Integration

```yaml
integration_id: INT-CRM-PHONE
name: Phone System Integration
providers: [Twilio, RingCentral, Aircall, Generic SIP]
capabilities:
  - Screen pop with customer info
  - Auto-log calls as interactions
  - Click-to-call from CRM
  - Call recording playback

data_captured:
  - Caller ID -> Match to Contact
  - Call duration
  - Call outcome (answered, voicemail, missed)
  - Recording URL (if enabled and consented)

screen_pop:
  trigger: Inbound call matched to customer
  display:
    - Customer name and company
    - Recent interactions
    - Open opportunities
    - Open support tickets
    - Churn risk score
```

### Marketing Automation Integration

```yaml
integration_id: INT-CRM-MARKETING
name: Marketing Automation Integration
providers: [HubSpot, Mailchimp, Marketo, ActiveCampaign]
capabilities:
  - Sync contacts bidirectionally
  - Push lifecycle stage changes
  - Receive campaign engagement data
  - Trigger campaigns from CRM events

sync_to_marketing:
  - Customer: email, name, company, lifecycle_stage
  - Contact: email, name, preferences
  - Consent: marketing_email status
  - Segments: dynamic segment membership

sync_from_marketing:
  - Email opens/clicks -> Interaction
  - Form submissions -> Lead/Activity
  - Campaign membership
  - Lead score (merge with CRM scoring)

event_triggers:
  - Lifecycle stage change -> Update marketing list
  - Segment entry/exit -> Trigger/stop campaign
  - Customer churned -> Add to win-back campaign
```

### Data Warehouse Integration

```yaml
integration_id: INT-CRM-DW
name: Data Warehouse Integration
providers: [Snowflake, BigQuery, Redshift]
purpose: Enable analytics and reporting across all customer data

export_entities:
  - Customer (with anonymization for deleted)
  - Contact
  - Interaction (aggregated)
  - Lifecycle history
  - Scores

export_schedule: Daily or near-real-time CDC

privacy_handling:
  - Exclude customers with processing_restricted
  - Anonymize PII for analytics-only datasets
  - Apply retention policies to warehouse data
```

---

## Quick Reference

### Entity Summary

| Entity | Package | Purpose |
|--------|---------|---------|
| Customer | customer_management | Core customer record |
| Contact | customer_management | Individual person |
| Account | customer_management | Organization details |
| Relationship | customer_management | Customer-to-customer links |
| Address | customer_management | Physical locations |
| Interaction | interaction_tracking | Touchpoint record |
| Note | interaction_tracking | Freeform notes |
| Activity | interaction_tracking | Scheduled tasks |
| Communication | interaction_tracking | Email/SMS content |
| LifecycleStage | lifecycle | Stage definitions |
| CustomerLifecycle | lifecycle | Current customer state |
| LifecycleHistory | lifecycle | Stage change audit |
| Segment | lifecycle | Customer groupings |
| Score | lifecycle | Health/engagement scores |
| Journey | lifecycle | Milestone tracking |
| ConsentRecord | compliance | GDPR consent |
| DeletionRequest | compliance | GDPR deletion |

### Workflow Summary

| Workflow | Package | Trigger |
|----------|---------|---------|
| WF-CM-001: Create Customer | customer_management | Manual/import |
| WF-CM-002: Merge Duplicates | customer_management | Admin action |
| WF-CM-003: Self-Service Update | customer_management | Customer portal |
| WF-IT-001: Log Interaction | interaction_tracking | Manual |
| WF-IT-002: Auto-Sync Email | interaction_tracking | Email received |
| WF-IT-003: Create Follow-Up | interaction_tracking | After interaction |
| WF-LC-001: Advance Stage | lifecycle | Rule or manual |
| WF-LC-002: Calculate Health | lifecycle | Scheduled |
| WF-LC-003: Build Segment | lifecycle | Admin action |
| WF-PRIV-001: Manage Consent | compliance | Customer request |

### Screen Summary

| Screen | Package | Purpose |
|--------|---------|---------|
| CustomerList | customer_management | Browse customers |
| CustomerDetail | customer_management | Customer 360 view |
| CustomerForm | customer_management | Create/edit |
| ContactForm | customer_management | Create/edit contact |
| AccountHierarchy | customer_management | Parent/child tree |
| MergeWizard | customer_management | Duplicate resolution |
| ImportWizard | customer_management | Bulk import |
| ActivityTimeline | interaction_tracking | Chronological history |
| InteractionForm | interaction_tracking | Log interaction |
| NoteEditor | interaction_tracking | Create/edit notes |
| MyActivities | interaction_tracking | User's tasks |
| LifecycleView | lifecycle | Customer journey |
| SegmentBuilder | lifecycle | Create segments |
| ScoringRules | lifecycle | Configure scoring |
| HealthDashboard | lifecycle | Overview metrics |
| ConsentPreferences | compliance | Manage consent |

### AI Touchpoint Summary

| Touchpoint | Package | Input | Output |
|------------|---------|-------|--------|
| Next Best Action | lifecycle | Profile, history | Recommended action |
| Churn Risk | lifecycle | Behavior signals | Probability, factors |
| Upsell Opportunity | lifecycle | Purchase history | Product recs |
| Sentiment Analysis | interaction_tracking | Interaction text | Sentiment score |
| Duplicate Detection | customer_management | New customer data | Match candidates |

---

## Module Selection Criteria

Select the **customer_management** package when:
- You need to store customer/contact information
- You have B2B customers with multiple contacts
- You need address management
- You need to track customer relationships/hierarchies

Select the **interaction_tracking** package when:
- You need to log calls, emails, meetings
- You integrate with email or phone systems
- Sales/support teams need activity history
- You want a customer timeline

Select the **lifecycle** package when:
- You have defined customer stages (lead -> customer -> churned)
- You want to score customer health or engagement
- You need customer segmentation
- You want to predict churn or identify upsell opportunities

Always select **all three packages** when building a full CRM system. Select individual packages when CRM is a supporting function for another primary module (e.g., Field Service may only need customer_management).
