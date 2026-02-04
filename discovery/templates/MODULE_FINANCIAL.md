# Financial Module Catalog

**Module**: Financial
**Version**: 1.0
**Last Updated**: 2026-01-26

---

## Overview

The Financial module covers all money movement within an application: tracking what's owed, collecting payments, managing expenses, and maintaining accurate financial records. This module is foundational for any business application that handles billing, receives payments, or tracks spending.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "invoice", "bill", "billing cycle" | Accountant, Business owner | Generate and send bills to customers |
| "payment", "pay", "charge", "checkout" | Customer, Finance team | Collect money from customers |
| "accounts receivable", "AR", "collections" | Finance team, Collectors | Track and collect outstanding balances |
| "accounts payable", "AP", "vendor payment" | Finance team, AP clerk | Pay bills owed to vendors |
| "expense", "receipt", "reimbursement" | Employees, Managers, Finance | Track and approve business spending |

### Module Dependencies

```
Financial Module
├── REQUIRES: Administrative (for settings, user preferences)
├── REQUIRES: Documents (for invoice PDFs, receipt images)
├── INTEGRATES_WITH: CRM (customer records)
├── INTEGRATES_WITH: Project/Job (billable time, cost tracking)
├── INTEGRATES_WITH: Compliance (audit trails, tax records)
```

---

## Packages

This module contains 5 packages:

1. **invoicing** - Creating and sending bills to customers
2. **payments** - Collecting and processing payments
3. **accounts_receivable** - Managing outstanding customer balances
4. **accounts_payable** - Managing bills owed to vendors
5. **expenses** - Tracking employee spending and reimbursements

---

## Package 1: Invoicing

### Purpose

Create, customize, and deliver invoices to customers. Supports line items, discounts, taxes, and multiple delivery methods.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What information appears on your invoices? (company logo, payment terms, custom fields)
- Do you bill for time, products, fixed fees, or a combination?
- How do you calculate taxes? (per line item, total, exempt items)
- Do you support multiple currencies?
- Can one invoice have multiple payment terms (deposit + balance)?

**Workflow Discovery**:
- What triggers invoice creation? (project completion, time period, manual)
- Who can create/edit/approve invoices?
- How are invoices delivered? (email, portal, print, mail)
- What happens when a customer disputes a line item?
- How do you handle invoice corrections or voids?

**Edge Case Probing**:
- Can customers pay invoices partially?
- What happens if a customer overpays?
- Do you issue credits or just refunds?
- How do you handle write-offs?

### Entity Templates

#### Invoice

```json
{
  "id": "data.invoicing.invoice",
  "name": "Invoice",
  "type": "data",
  "namespace": "invoicing",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a bill sent to a customer for goods or services.",
    "attributes": [
      { "name": "invoice_number", "type": "string", "required": true, "description": "Unique sequential identifier (e.g., INV-2026-0001)" },
      { "name": "client_id", "type": "uuid", "required": true, "description": "Foreign key to Client entity" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "sent", "viewed", "partial", "paid", "overdue", "void", "written_off"], "description": "Current invoice state" },
      { "name": "issue_date", "type": "date", "required": true, "description": "Date invoice was issued" },
      { "name": "due_date", "type": "date", "required": true, "description": "Payment due date" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "Sum of line items before tax and discounts" },
      { "name": "discount_amount", "type": "decimal", "required": false, "description": "Total discount applied" },
      { "name": "tax_amount", "type": "decimal", "required": true, "description": "Total tax amount" },
      { "name": "total", "type": "decimal", "required": true, "description": "Final amount due (subtotal - discount + tax)" },
      { "name": "balance_due", "type": "decimal", "required": true, "description": "Remaining unpaid amount" },
      { "name": "currency", "type": "string", "required": true, "description": "ISO 4217 currency code (e.g., USD)" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Net 30, Due on Receipt, etc." },
      { "name": "notes", "type": "text", "required": false, "description": "Customer-visible notes" },
      { "name": "internal_notes", "type": "text", "required": false, "description": "Internal notes not shown to customer" },
      { "name": "sent_at", "type": "datetime", "required": false, "description": "When invoice was first sent" },
      { "name": "viewed_at", "type": "datetime", "required": false, "description": "When customer first viewed invoice" },
      { "name": "paid_at", "type": "datetime", "required": false, "description": "When fully paid" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "InvoiceLine", "type": "one_to_many", "required": true },
      { "entity": "Payment", "type": "one_to_many", "required": false },
      { "entity": "InvoiceCredit", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.invoicing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### InvoiceLine

```json
{
  "id": "data.invoicing.invoice_line",
  "name": "Invoice Line Item",
  "type": "data",
  "namespace": "invoicing",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual line item on an invoice representing a charge.",
    "attributes": [
      { "name": "invoice_id", "type": "uuid", "required": true, "description": "Parent invoice" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "description", "type": "string", "required": true, "description": "Line item description" },
      { "name": "quantity", "type": "decimal", "required": true, "description": "Number of units" },
      { "name": "unit_price", "type": "decimal", "required": true, "description": "Price per unit" },
      { "name": "amount", "type": "decimal", "required": true, "description": "quantity * unit_price" },
      { "name": "tax_rate", "type": "decimal", "required": false, "description": "Tax percentage for this line" },
      { "name": "tax_amount", "type": "decimal", "required": false, "description": "Calculated tax" },
      { "name": "discount_percent", "type": "decimal", "required": false, "description": "Line-level discount %" },
      { "name": "billable_type", "type": "enum", "required": false, "values": ["time", "expense", "product", "service", "fixed_fee"], "description": "Source of charge" },
      { "name": "source_id", "type": "uuid", "required": false, "description": "Reference to TimeEntry, Expense, etc." }
    ],
    "relationships": [
      { "entity": "Invoice", "type": "many_to_one", "required": true },
      { "entity": "TimeEntry", "type": "many_to_one", "required": false },
      { "entity": "Product", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.invoicing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Client (Financial Context)

```json
{
  "id": "data.invoicing.client",
  "name": "Client",
  "type": "data",
  "namespace": "invoicing",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A customer who receives invoices and makes payments.",
    "attributes": [
      { "name": "name", "type": "string", "required": true, "description": "Client/company name" },
      { "name": "billing_email", "type": "email", "required": true, "description": "Primary billing contact email" },
      { "name": "billing_address", "type": "address", "required": false, "description": "Mailing address for invoices" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Default payment terms (Net 30)" },
      { "name": "tax_id", "type": "string", "required": false, "description": "Tax identification number" },
      { "name": "tax_exempt", "type": "boolean", "required": false, "description": "Whether client is tax exempt" },
      { "name": "credit_limit", "type": "decimal", "required": false, "description": "Maximum outstanding balance allowed" },
      { "name": "default_currency", "type": "string", "required": false, "description": "Preferred billing currency" },
      { "name": "notes", "type": "text", "required": false, "description": "Internal notes about billing" }
    ],
    "relationships": [
      { "entity": "Invoice", "type": "one_to_many", "required": false },
      { "entity": "Payment", "type": "one_to_many", "required": false },
      { "entity": "Matter", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.invoicing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### TimeEntry

```json
{
  "id": "data.invoicing.time_entry",
  "name": "Time Entry",
  "type": "data",
  "namespace": "invoicing",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of billable or non-billable time worked.",
    "attributes": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Who performed the work" },
      { "name": "client_id", "type": "uuid", "required": true, "description": "Client this time is for" },
      { "name": "matter_id", "type": "uuid", "required": false, "description": "Specific matter/project" },
      { "name": "date", "type": "date", "required": true, "description": "Date work was performed" },
      { "name": "hours", "type": "decimal", "required": true, "description": "Duration in hours" },
      { "name": "description", "type": "text", "required": true, "description": "Work description" },
      { "name": "billable", "type": "boolean", "required": true, "description": "Whether time is billable" },
      { "name": "billing_rate", "type": "decimal", "required": false, "description": "Rate per hour" },
      { "name": "amount", "type": "decimal", "required": false, "description": "hours * billing_rate" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "billed", "written_off"], "description": "Workflow status" },
      { "name": "invoice_line_id", "type": "uuid", "required": false, "description": "Link to invoice if billed" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "Matter", "type": "many_to_one", "required": false },
      { "entity": "InvoiceLine", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.invoicing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-INV-001: Invoice Creation and Delivery

```yaml
workflow:
  id: "wf.invoicing.create_and_deliver"
  name: "Create and Deliver Invoice"
  trigger: "Manual or scheduled billing cycle"
  actors: ["Accountant", "System"]

  steps:
    - step: 1
      name: "Select Billable Items"
      actor: "Accountant"
      action: "Review unbilled time entries and expenses"
      inputs: ["Client", "Date range"]
      outputs: ["Selected billable items"]
      decision_point: "Which items to include?"

    - step: 2
      name: "Generate Invoice"
      actor: "System"
      action: "Create invoice with selected line items"
      inputs: ["Selected billable items", "Client defaults"]
      outputs: ["Draft invoice"]
      automatable: true

    - step: 3
      name: "Review and Adjust"
      actor: "Accountant"
      action: "Review totals, add discounts, adjust descriptions"
      inputs: ["Draft invoice"]
      outputs: ["Finalized invoice"]
      decision_point: "Apply discounts? Add notes?"

    - step: 4
      name: "Approve Invoice"
      actor: "Manager"
      action: "Approve invoice for sending"
      inputs: ["Finalized invoice"]
      outputs: ["Approved invoice"]
      condition: "If invoice > approval threshold"

    - step: 5
      name: "Deliver Invoice"
      actor: "System"
      action: "Send via email and/or post to portal"
      inputs: ["Approved invoice", "Delivery preferences"]
      outputs: ["Sent invoice", "Delivery confirmation"]
      automatable: true

    - step: 6
      name: "Track Delivery"
      actor: "System"
      action: "Monitor email open/view events"
      inputs: ["Sent invoice"]
      outputs: ["viewed_at timestamp"]
      automatable: true
```

#### WF-INV-002: Invoice Dispute Resolution

```yaml
workflow:
  id: "wf.invoicing.dispute_resolution"
  name: "Handle Invoice Dispute"
  trigger: "Customer disputes invoice or line item"
  actors: ["Customer", "Accountant", "Manager"]

  steps:
    - step: 1
      name: "Receive Dispute"
      actor: "Accountant"
      action: "Log dispute reason and affected line items"
      inputs: ["Invoice", "Customer communication"]
      outputs: ["Dispute record"]

    - step: 2
      name: "Investigate"
      actor: "Accountant"
      action: "Review source records (time entries, contracts)"
      inputs: ["Dispute record", "Source documents"]
      outputs: ["Investigation findings"]
      decision_point: "Valid dispute or customer misunderstanding?"

    - step: 3a
      name: "Issue Credit (if valid)"
      actor: "Accountant"
      action: "Create credit memo for disputed amount"
      inputs: ["Investigation findings"]
      outputs: ["Credit memo"]
      condition: "Dispute is valid"

    - step: 3b
      name: "Explain and Provide Evidence (if invalid)"
      actor: "Accountant"
      action: "Send explanation with supporting docs"
      inputs: ["Investigation findings"]
      outputs: ["Customer communication"]
      condition: "Dispute is invalid"

    - step: 4
      name: "Escalate if Unresolved"
      actor: "Manager"
      action: "Review and make final determination"
      inputs: ["Dispute history", "Customer relationship value"]
      outputs: ["Final resolution"]
      condition: "Customer rejects initial resolution"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-INV-001 | **Partial payment received** | Medium | Track balance_due separately from total; allow multiple payments per invoice |
| EC-INV-002 | **Customer overpays** | Low | Create credit balance; apply to future invoices or issue refund |
| EC-INV-003 | **Invoice sent to wrong email** | Medium | Void and reissue with correct email; log in audit trail |
| EC-INV-004 | **Tax rate changes mid-billing** | Medium | Apply rate as of invoice date; maintain rate history |
| EC-INV-005 | **Line item disputed after partial payment** | High | Credit only disputed portion; recalculate balance |
| EC-INV-006 | **Recurring invoice for canceled service** | Medium | Stop recurrence immediately; void any unsent drafts |
| EC-INV-007 | **Multi-currency invoice with payment in different currency** | High | Record payment in received currency; track exchange rate at time of payment |
| EC-INV-008 | **Invoice number sequence gap** | Low | Document reason; do not reuse numbers; maintain integrity |
| EC-INV-009 | **Customer requests invoice date change** | Medium | Only allow if not yet sent; otherwise credit and reissue |
| EC-INV-010 | **Late fee calculation on partial payment** | Medium | Calculate late fees only on overdue balance, not full amount |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-INV-001 | **Auto-categorization** | Line item descriptions | Suggested categories/accounts | Reduces manual coding; improves accuracy |
| AI-INV-002 | **Payment prediction** | Invoice + client history | Predicted payment date | Enables cash flow forecasting |
| AI-INV-003 | **Anomaly detection** | Invoice details vs. historical | Flag unusual amounts/patterns | Catches billing errors before sending |
| AI-INV-004 | **Description generation** | Time entry notes | Professional invoice descriptions | Improves invoice quality |
| AI-INV-005 | **Collection timing** | Client payment patterns | Optimal reminder timing | Improves collection rates |

---

## Package 2: Payments

### Purpose

Process incoming payments via multiple methods, handle refunds, and reconcile transactions with invoices.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What payment methods do you accept? (credit card, ACH, check, wire, cash)
- Do customers pay via a portal or external processor?
- Do you store payment methods for recurring charges?
- How do you handle tips or variable amounts?

**Workflow Discovery**:
- Who processes payments? (automated, staff, customer self-service)
- What's your refund policy? (full, partial, time limits)
- How do you handle failed payments? (retry, notify, suspend)
- What reconciliation do you do? (bank to system, daily, weekly)

**Edge Case Probing**:
- What if a payment is applied to the wrong invoice?
- How do you handle chargebacks?
- What if the payment processor goes down?

### Entity Templates

#### Payment

```json
{
  "id": "data.payments.payment",
  "name": "Payment",
  "type": "data",
  "namespace": "payments",
  "tags": ["core-entity", "mvp", "pci"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of money received from a customer.",
    "attributes": [
      { "name": "payment_number", "type": "string", "required": true, "description": "Unique payment reference" },
      { "name": "client_id", "type": "uuid", "required": true, "description": "Who paid" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Amount received" },
      { "name": "currency", "type": "string", "required": true, "description": "ISO 4217 currency code" },
      { "name": "payment_date", "type": "date", "required": true, "description": "Date payment received" },
      { "name": "payment_method", "type": "enum", "required": true, "values": ["credit_card", "debit_card", "ach", "wire", "check", "cash", "other"], "description": "How payment was made" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "completed", "failed", "refunded", "partially_refunded", "disputed"], "description": "Current status" },
      { "name": "processor_reference", "type": "string", "required": false, "description": "External processor transaction ID" },
      { "name": "notes", "type": "text", "required": false, "description": "Payment notes (check number, wire reference)" },
      { "name": "unapplied_amount", "type": "decimal", "required": false, "description": "Amount not yet applied to invoices" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "PaymentApplication", "type": "one_to_many", "required": false },
      { "entity": "Refund", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.payments",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PaymentMethod

```json
{
  "id": "data.payments.payment_method",
  "name": "Payment Method",
  "type": "data",
  "namespace": "payments",
  "tags": ["core-entity", "pci-sensitive"],
  "status": "discovered",

  "spec": {
    "purpose": "Stored payment method for a customer (tokenized).",
    "attributes": [
      { "name": "client_id", "type": "uuid", "required": true, "description": "Owner of payment method" },
      { "name": "type", "type": "enum", "required": true, "values": ["credit_card", "debit_card", "bank_account"], "description": "Method type" },
      { "name": "processor_token", "type": "string", "required": true, "description": "Tokenized reference from processor" },
      { "name": "last_four", "type": "string", "required": true, "description": "Last 4 digits for display" },
      { "name": "brand", "type": "string", "required": false, "description": "Card brand (Visa, Mastercard) or bank name" },
      { "name": "expiration_month", "type": "integer", "required": false, "description": "Card expiry month (1-12)" },
      { "name": "expiration_year", "type": "integer", "required": false, "description": "Card expiry year" },
      { "name": "is_default", "type": "boolean", "required": true, "description": "Default payment method for client" },
      { "name": "billing_address", "type": "address", "required": false, "description": "Billing address associated with method" },
      { "name": "active", "type": "boolean", "required": true, "description": "Whether method can be charged" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "Payment", "type": "one_to_many", "required": false }
    ],
    "notes": "NEVER store full card numbers, CVV, or unencrypted bank account numbers. Use processor tokenization."
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.payments",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Refund

```json
{
  "id": "data.payments.refund",
  "name": "Refund",
  "type": "data",
  "namespace": "payments",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of money returned to a customer.",
    "attributes": [
      { "name": "payment_id", "type": "uuid", "required": true, "description": "Original payment being refunded" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Refund amount" },
      { "name": "reason", "type": "string", "required": true, "description": "Why refund was issued" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "completed", "failed"], "description": "Refund status" },
      { "name": "processor_reference", "type": "string", "required": false, "description": "External refund transaction ID" },
      { "name": "requested_by", "type": "uuid", "required": true, "description": "User who requested refund" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "User who approved refund" },
      { "name": "refunded_at", "type": "datetime", "required": false, "description": "When refund was processed" }
    ],
    "relationships": [
      { "entity": "Payment", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.payments",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Transaction

```json
{
  "id": "data.payments.transaction",
  "name": "Transaction",
  "type": "data",
  "namespace": "payments",
  "tags": ["core-entity", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Low-level record of payment processor activity.",
    "attributes": [
      { "name": "type", "type": "enum", "required": true, "values": ["authorization", "capture", "sale", "refund", "void", "chargeback"], "description": "Transaction type" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "success", "failed", "canceled"], "description": "Outcome" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Transaction amount" },
      { "name": "currency", "type": "string", "required": true, "description": "Currency code" },
      { "name": "processor", "type": "string", "required": true, "description": "Payment processor name" },
      { "name": "processor_transaction_id", "type": "string", "required": true, "description": "Processor's reference" },
      { "name": "payment_id", "type": "uuid", "required": false, "description": "Associated payment record" },
      { "name": "error_code", "type": "string", "required": false, "description": "Processor error code if failed" },
      { "name": "error_message", "type": "string", "required": false, "description": "Human-readable error" },
      { "name": "raw_response", "type": "json", "required": false, "description": "Full processor response (for debugging)" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When transaction occurred" }
    ],
    "relationships": [
      { "entity": "Payment", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.payments",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-PAY-001: Process Online Payment

```yaml
workflow:
  id: "wf.payments.process_online"
  name: "Process Online Payment"
  trigger: "Customer submits payment via portal"
  actors: ["Customer", "System", "Payment Processor"]

  steps:
    - step: 1
      name: "Customer Initiates Payment"
      actor: "Customer"
      action: "Select invoice(s) and payment method"
      inputs: ["Invoice selection", "Payment amount"]
      outputs: ["Payment intent"]

    - step: 2
      name: "Validate Payment"
      actor: "System"
      action: "Verify amount against balance, check method status"
      inputs: ["Payment intent", "Invoice balance"]
      outputs: ["Validated payment request"]
      automatable: true

    - step: 3
      name: "Process with Processor"
      actor: "System"
      action: "Submit payment to processor (Stripe, etc.)"
      inputs: ["Validated payment request", "Payment method token"]
      outputs: ["Processor response"]
      automatable: true

    - step: 4a
      name: "Record Success"
      actor: "System"
      action: "Create payment record, apply to invoice(s)"
      inputs: ["Processor response (success)"]
      outputs: ["Payment record", "Updated invoice balances"]
      condition: "Payment successful"
      automatable: true

    - step: 4b
      name: "Handle Failure"
      actor: "System"
      action: "Log failure, notify customer"
      inputs: ["Processor response (failure)"]
      outputs: ["Error notification"]
      condition: "Payment failed"
      automatable: true

    - step: 5
      name: "Send Receipt"
      actor: "System"
      action: "Email payment confirmation to customer"
      inputs: ["Payment record"]
      outputs: ["Receipt email"]
      automatable: true
```

#### WF-PAY-002: Process Refund

```yaml
workflow:
  id: "wf.payments.process_refund"
  name: "Process Refund"
  trigger: "Staff initiates refund request"
  actors: ["Staff", "Manager", "System"]

  steps:
    - step: 1
      name: "Request Refund"
      actor: "Staff"
      action: "Select payment and specify refund amount/reason"
      inputs: ["Original payment", "Refund amount", "Reason"]
      outputs: ["Refund request"]

    - step: 2
      name: "Validate Request"
      actor: "System"
      action: "Check refund amount <= original, within policy limits"
      inputs: ["Refund request", "Original payment"]
      outputs: ["Validated refund request"]
      automatable: true

    - step: 3
      name: "Approve Refund"
      actor: "Manager"
      action: "Review and approve refund"
      inputs: ["Validated refund request"]
      outputs: ["Approved refund"]
      condition: "Refund exceeds auto-approval limit"

    - step: 4
      name: "Process Refund"
      actor: "System"
      action: "Submit refund to processor"
      inputs: ["Approved refund"]
      outputs: ["Processor refund response"]
      automatable: true

    - step: 5
      name: "Update Records"
      actor: "System"
      action: "Create refund record, update payment status, reverse invoice application"
      inputs: ["Processor refund response"]
      outputs: ["Refund record", "Updated records"]
      automatable: true

    - step: 6
      name: "Notify Customer"
      actor: "System"
      action: "Send refund confirmation"
      inputs: ["Refund record"]
      outputs: ["Confirmation email"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PAY-001 | **Payment applied to wrong invoice** | Medium | Provide unapply/reapply function; maintain audit trail |
| EC-PAY-002 | **Credit card expired during recurring charge** | Medium | Notify customer in advance; retry with stored backup method |
| EC-PAY-003 | **Chargeback received** | High | Flag payment as disputed; gather evidence; submit response to processor |
| EC-PAY-004 | **Duplicate payment submitted** | Medium | Detect within short window; auto-refund or create credit |
| EC-PAY-005 | **Payment processor timeout** | High | Implement idempotency keys; check status before retry |
| EC-PAY-006 | **Partial refund leaves invoice balance** | Low | Update invoice status back to partial; recalculate balance |
| EC-PAY-007 | **Currency mismatch between payment and invoice** | High | Convert at payment time; store exchange rate |
| EC-PAY-008 | **Check bounces after recording** | High | Reverse payment application; notify AR; flag client |
| EC-PAY-009 | **ACH returns after settlement** | High | Handle NSF and other return codes; reverse within window |
| EC-PAY-010 | **Payment method token expired** | Low | Prompt customer to re-enter; never store raw card data |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PAY-001 | **Fraud detection** | Transaction details, client history | Risk score | Prevents fraudulent payments |
| AI-PAY-002 | **Smart retry** | Failed payment details | Optimal retry timing/method | Improves recovery rate |
| AI-PAY-003 | **Reconciliation matching** | Bank feed, payments | Matched transactions | Reduces manual reconciliation |
| AI-PAY-004 | **Chargeback prediction** | Payment patterns | Risk of dispute | Proactive intervention |

---

## Package 3: Accounts Receivable

### Purpose

Track outstanding customer balances, manage collections, and monitor cash flow health.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- How do you track aging? (30/60/90 days, custom buckets)
- Do you charge late fees or interest?
- What collection stages do you use?
- Do you use external collection agencies?

**Workflow Discovery**:
- What triggers collection activity? (days past due, amount threshold)
- Who owns collection calls/emails?
- How do you escalate collection efforts?
- When do you write off bad debt?

**Edge Case Probing**:
- Customer on payment plan but misses a payment?
- Customer declares bankruptcy?
- Disputed amount sits in limbo for months?

### Entity Templates

#### Receivable

```json
{
  "id": "data.accounts_receivable.receivable",
  "name": "Receivable",
  "type": "data",
  "namespace": "accounts_receivable",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents an amount owed by a customer.",
    "attributes": [
      { "name": "client_id", "type": "uuid", "required": true, "description": "Customer who owes" },
      { "name": "invoice_id", "type": "uuid", "required": true, "description": "Source invoice" },
      { "name": "original_amount", "type": "decimal", "required": true, "description": "Initial amount owed" },
      { "name": "current_balance", "type": "decimal", "required": true, "description": "Current outstanding amount" },
      { "name": "due_date", "type": "date", "required": true, "description": "Payment due date" },
      { "name": "days_past_due", "type": "integer", "required": false, "description": "Computed days overdue" },
      { "name": "aging_bucket", "type": "enum", "required": false, "values": ["current", "1_30", "31_60", "61_90", "over_90"], "description": "Aging category" },
      { "name": "collection_status", "type": "enum", "required": false, "values": ["normal", "reminder_sent", "in_collection", "payment_plan", "sent_to_agency", "written_off"], "description": "Collection stage" },
      { "name": "last_contact_date", "type": "date", "required": false, "description": "Last collection contact" },
      { "name": "next_action_date", "type": "date", "required": false, "description": "Scheduled next follow-up" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "Invoice", "type": "many_to_one", "required": true },
      { "entity": "CollectionNote", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.accounts_receivable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### AgingBucket

```json
{
  "id": "data.accounts_receivable.aging_bucket",
  "name": "Aging Bucket Configuration",
  "type": "data",
  "namespace": "accounts_receivable",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Configurable aging period definitions.",
    "attributes": [
      { "name": "name", "type": "string", "required": true, "description": "Bucket name (Current, 1-30, etc.)" },
      { "name": "days_from", "type": "integer", "required": true, "description": "Start of range (inclusive)" },
      { "name": "days_to", "type": "integer", "required": false, "description": "End of range (null for open-ended)" },
      { "name": "collection_action", "type": "string", "required": false, "description": "Default action for this bucket" },
      { "name": "late_fee_rate", "type": "decimal", "required": false, "description": "Late fee percentage to apply" },
      { "name": "display_order", "type": "integer", "required": true, "description": "Sort order in reports" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "financial.accounts_receivable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### CollectionNote

```json
{
  "id": "data.accounts_receivable.collection_note",
  "name": "Collection Note",
  "type": "data",
  "namespace": "accounts_receivable",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Log of collection activities and communications.",
    "attributes": [
      { "name": "receivable_id", "type": "uuid", "required": true, "description": "Associated receivable" },
      { "name": "user_id", "type": "uuid", "required": true, "description": "Who made the note" },
      { "name": "type", "type": "enum", "required": true, "values": ["call", "email", "letter", "sms", "note", "promise_to_pay", "payment_plan"], "description": "Contact type" },
      { "name": "content", "type": "text", "required": true, "description": "Note content or summary" },
      { "name": "outcome", "type": "enum", "required": false, "values": ["no_answer", "left_message", "spoke_with_contact", "promise_received", "dispute_raised", "payment_made"], "description": "Result of contact" },
      { "name": "follow_up_date", "type": "date", "required": false, "description": "Scheduled follow-up" },
      { "name": "created_at", "type": "datetime", "required": true, "description": "When note was created" }
    ],
    "relationships": [
      { "entity": "Receivable", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.accounts_receivable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### PaymentPlan

```json
{
  "id": "data.accounts_receivable.payment_plan",
  "name": "Payment Plan",
  "type": "data",
  "namespace": "accounts_receivable",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Structured payment arrangement for overdue balance.",
    "attributes": [
      { "name": "client_id", "type": "uuid", "required": true, "description": "Customer on plan" },
      { "name": "total_amount", "type": "decimal", "required": true, "description": "Total amount being paid off" },
      { "name": "installment_amount", "type": "decimal", "required": true, "description": "Amount per payment" },
      { "name": "frequency", "type": "enum", "required": true, "values": ["weekly", "biweekly", "monthly"], "description": "Payment frequency" },
      { "name": "start_date", "type": "date", "required": true, "description": "First payment date" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "completed", "defaulted", "canceled"], "description": "Plan status" },
      { "name": "payments_made", "type": "integer", "required": true, "description": "Number of payments received" },
      { "name": "payments_total", "type": "integer", "required": true, "description": "Total payments in plan" },
      { "name": "remaining_balance", "type": "decimal", "required": true, "description": "Amount still owed" },
      { "name": "late_payment_count", "type": "integer", "required": false, "description": "Number of missed/late payments" },
      { "name": "auto_charge", "type": "boolean", "required": false, "description": "Automatically charge on schedule" }
    ],
    "relationships": [
      { "entity": "Client", "type": "many_to_one", "required": true },
      { "entity": "Invoice", "type": "many_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "financial.accounts_receivable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-AR-001: Collection Escalation

```yaml
workflow:
  id: "wf.ar.collection_escalation"
  name: "Collection Escalation Process"
  trigger: "Invoice passes aging threshold"
  actors: ["System", "Collector", "Manager"]

  steps:
    - step: 1
      name: "Auto-Reminder (Day 1)"
      actor: "System"
      action: "Send automated payment reminder"
      inputs: ["Overdue invoice"]
      outputs: ["Reminder email"]
      condition: "1 day past due"
      automatable: true

    - step: 2
      name: "Second Reminder (Day 7)"
      actor: "System"
      action: "Send follow-up reminder with late fee warning"
      inputs: ["Still overdue invoice"]
      outputs: ["Second reminder"]
      condition: "7 days past due"
      automatable: true

    - step: 3
      name: "Phone Outreach (Day 15)"
      actor: "Collector"
      action: "Call customer, log result"
      inputs: ["Overdue receivable", "Contact info"]
      outputs: ["Collection note"]
      condition: "15 days past due"

    - step: 4
      name: "Demand Letter (Day 30)"
      actor: "System"
      action: "Send formal demand letter"
      inputs: ["30+ day receivable"]
      outputs: ["Demand letter"]
      condition: "30 days past due"
      automatable: true

    - step: 5
      name: "Manager Review (Day 45)"
      actor: "Manager"
      action: "Review account, decide next steps"
      inputs: ["Collection history", "Customer value"]
      outputs: ["Decision: payment plan, write-off, or agency"]
      decision_point: "Payment plan? Write off? Send to agency?"

    - step: 6a
      name: "Create Payment Plan"
      actor: "Collector"
      action: "Negotiate and set up payment plan"
      inputs: ["Manager decision", "Customer agreement"]
      outputs: ["Payment plan record"]
      condition: "Decision = payment plan"

    - step: 6b
      name: "Write Off"
      actor: "Manager"
      action: "Write off as bad debt"
      inputs: ["Manager decision"]
      outputs: ["Write-off record", "Updated receivable"]
      condition: "Decision = write off"

    - step: 6c
      name: "Send to Agency"
      actor: "System"
      action: "Transfer to external collection agency"
      inputs: ["Manager decision", "Receivable details"]
      outputs: ["Agency assignment"]
      condition: "Decision = agency"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-AR-001 | **Customer on payment plan misses payment** | Medium | Grace period (3-5 days), then warning, then default after 2nd miss |
| EC-AR-002 | **Customer declares bankruptcy** | High | Stop collection immediately; file proof of claim; monitor proceedings |
| EC-AR-003 | **Disputed amount sits in aging** | Medium | Exclude disputed amounts from collection; track separately |
| EC-AR-004 | **Write-off later recovered** | Low | Reverse write-off; credit back to income |
| EC-AR-005 | **Customer pays agency directly** | Medium | Agency reports payment; update records; reconcile commission |
| EC-AR-006 | **Multiple invoices, partial payment** | Medium | Define application order (oldest first, or customer-specified) |
| EC-AR-007 | **Late fees exceed principal on small balance** | Low | Cap late fees at percentage of principal |
| EC-AR-008 | **Customer contact info invalid** | Medium | Flag for research; skip to next escalation step |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-AR-001 | **Collection priority scoring** | Customer data, payment history, balance | Priority score | Focus efforts on recoverable accounts |
| AI-AR-002 | **Optimal contact timing** | Customer behavior patterns | Best day/time to call | Higher contact rates |
| AI-AR-003 | **Write-off prediction** | Aging, history, economic data | Probability of recovery | Proactive reserve calculations |
| AI-AR-004 | **Payment plan recommendation** | Customer cash flow indicators | Suggested plan terms | Realistic plans that customers can keep |

---

## Package 4: Accounts Payable

### Purpose

Track bills owed to vendors, manage payment timing, and maintain vendor relationships.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What types of vendors do you pay? (suppliers, contractors, utilities)
- How do you receive bills? (email, mail, portal, EDI)
- Do you use PO matching (2-way, 3-way)?
- What approval levels exist?

**Workflow Discovery**:
- Who enters bills? (AP clerk, auto-capture, vendors direct)
- What's your approval workflow? (amount thresholds, department)
- When do you run payments? (weekly, on-demand)
- Do you take early payment discounts?

**Edge Case Probing**:
- Bill doesn't match PO?
- Vendor sends duplicate invoice?
- Need to pay same vendor from multiple entities?

### Entity Templates

#### Payable

```json
{
  "id": "data.accounts_payable.payable",
  "name": "Payable",
  "type": "data",
  "namespace": "accounts_payable",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Represents a bill owed to a vendor.",
    "attributes": [
      { "name": "bill_number", "type": "string", "required": true, "description": "Vendor's invoice/bill number" },
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Who we owe" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "approved", "scheduled", "paid", "void"], "description": "Bill status" },
      { "name": "bill_date", "type": "date", "required": true, "description": "Date on vendor invoice" },
      { "name": "due_date", "type": "date", "required": true, "description": "Payment due date" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Total bill amount" },
      { "name": "balance_due", "type": "decimal", "required": true, "description": "Remaining unpaid" },
      { "name": "currency", "type": "string", "required": true, "description": "Bill currency" },
      { "name": "description", "type": "string", "required": false, "description": "Bill description" },
      { "name": "gl_account", "type": "string", "required": false, "description": "General ledger account" },
      { "name": "po_number", "type": "string", "required": false, "description": "Related purchase order" },
      { "name": "discount_date", "type": "date", "required": false, "description": "Early payment discount deadline" },
      { "name": "discount_percent", "type": "decimal", "required": false, "description": "Early payment discount %" }
    ],
    "relationships": [
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "BillLine", "type": "one_to_many", "required": false },
      { "entity": "BillPayment", "type": "one_to_many", "required": false },
      { "entity": "PurchaseOrder", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.accounts_payable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Vendor

```json
{
  "id": "data.accounts_payable.vendor",
  "name": "Vendor",
  "type": "data",
  "namespace": "accounts_payable",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A supplier or service provider we pay.",
    "attributes": [
      { "name": "name", "type": "string", "required": true, "description": "Vendor name" },
      { "name": "vendor_type", "type": "enum", "required": false, "values": ["supplier", "contractor", "service", "utility", "government"], "description": "Category of vendor" },
      { "name": "tax_id", "type": "string", "required": false, "description": "Tax ID / EIN for 1099 reporting" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Default payment terms (Net 30)" },
      { "name": "payment_method", "type": "enum", "required": false, "values": ["check", "ach", "wire", "credit_card"], "description": "Preferred payment method" },
      { "name": "bank_account", "type": "encrypted_string", "required": false, "description": "ACH routing/account (encrypted)" },
      { "name": "address", "type": "address", "required": false, "description": "Remit-to address" },
      { "name": "email", "type": "email", "required": false, "description": "AP contact email" },
      { "name": "phone", "type": "phone", "required": false, "description": "AP contact phone" },
      { "name": "w9_on_file", "type": "boolean", "required": false, "description": "W-9 form received" },
      { "name": "is_1099_vendor", "type": "boolean", "required": false, "description": "Requires 1099 reporting" },
      { "name": "status", "type": "enum", "required": true, "values": ["active", "inactive", "blocked"], "description": "Vendor status" }
    ],
    "relationships": [
      { "entity": "Payable", "type": "one_to_many", "required": false },
      { "entity": "VendorContact", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.accounts_payable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Bill (Alias for Payable detail)

```json
{
  "id": "data.accounts_payable.bill_line",
  "name": "Bill Line Item",
  "type": "data",
  "namespace": "accounts_payable",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual line item on a vendor bill.",
    "attributes": [
      { "name": "payable_id", "type": "uuid", "required": true, "description": "Parent bill" },
      { "name": "description", "type": "string", "required": true, "description": "Line description" },
      { "name": "quantity", "type": "decimal", "required": false, "description": "Quantity if applicable" },
      { "name": "unit_price", "type": "decimal", "required": false, "description": "Price per unit" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Line total" },
      { "name": "gl_account", "type": "string", "required": false, "description": "GL account for this line" },
      { "name": "department", "type": "string", "required": false, "description": "Cost center/department" },
      { "name": "project_id", "type": "uuid", "required": false, "description": "Project to charge" },
      { "name": "po_line_id", "type": "uuid", "required": false, "description": "Matched PO line" }
    ],
    "relationships": [
      { "entity": "Payable", "type": "many_to_one", "required": true },
      { "entity": "PurchaseOrderLine", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.accounts_payable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### VendorCredit

```json
{
  "id": "data.accounts_payable.vendor_credit",
  "name": "Vendor Credit",
  "type": "data",
  "namespace": "accounts_payable",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Credit issued by vendor reducing amount owed.",
    "attributes": [
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Vendor who issued credit" },
      { "name": "credit_number", "type": "string", "required": true, "description": "Vendor's credit memo number" },
      { "name": "date", "type": "date", "required": true, "description": "Credit date" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Credit amount" },
      { "name": "remaining_amount", "type": "decimal", "required": true, "description": "Unapplied credit" },
      { "name": "reason", "type": "string", "required": false, "description": "Reason for credit" },
      { "name": "status", "type": "enum", "required": true, "values": ["available", "partially_applied", "fully_applied"], "description": "Application status" }
    ],
    "relationships": [
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "Payable", "type": "many_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "financial.accounts_payable",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-AP-001: Bill Entry and Approval

```yaml
workflow:
  id: "wf.ap.bill_entry_approval"
  name: "Bill Entry and Approval"
  trigger: "Receive vendor invoice"
  actors: ["AP Clerk", "Manager", "System"]

  steps:
    - step: 1
      name: "Receive Bill"
      actor: "AP Clerk"
      action: "Enter bill details or capture from document"
      inputs: ["Vendor invoice"]
      outputs: ["Draft bill record"]

    - step: 2
      name: "Match to PO (if applicable)"
      actor: "System"
      action: "Match bill to purchase order and receipt"
      inputs: ["Draft bill", "PO database"]
      outputs: ["Match result"]
      automatable: true
      decision_point: "3-way match successful?"

    - step: 3a
      name: "Auto-Approve (if matched)"
      actor: "System"
      action: "Approve bill that matches PO within tolerance"
      inputs: ["Matched bill"]
      outputs: ["Approved bill"]
      condition: "Match successful and within variance tolerance"
      automatable: true

    - step: 3b
      name: "Route for Approval (if not matched)"
      actor: "System"
      action: "Route to appropriate approver based on amount/department"
      inputs: ["Unmatched bill"]
      outputs: ["Approval request"]
      condition: "No PO or match failed"
      automatable: true

    - step: 4
      name: "Manual Approval"
      actor: "Manager"
      action: "Review and approve or reject bill"
      inputs: ["Approval request", "Supporting documents"]
      outputs: ["Approval decision"]
      decision_point: "Approve, reject, or request more info?"

    - step: 5
      name: "Queue for Payment"
      actor: "System"
      action: "Add to next payment run"
      inputs: ["Approved bill"]
      outputs: ["Scheduled bill"]
      automatable: true
```

#### WF-AP-002: Payment Run

```yaml
workflow:
  id: "wf.ap.payment_run"
  name: "Execute Payment Run"
  trigger: "Scheduled payment date or manual trigger"
  actors: ["AP Manager", "System"]

  steps:
    - step: 1
      name: "Select Bills"
      actor: "AP Manager"
      action: "Review and select bills to pay"
      inputs: ["Approved bills", "Cash position"]
      outputs: ["Selected bills for payment"]
      decision_point: "Which bills to include? Take discounts?"

    - step: 2
      name: "Generate Payment Batch"
      actor: "System"
      action: "Create payment records grouped by method"
      inputs: ["Selected bills"]
      outputs: ["Payment batch (checks, ACH, wires)"]
      automatable: true

    - step: 3
      name: "Approve Batch"
      actor: "AP Manager"
      action: "Review totals and approve batch"
      inputs: ["Payment batch summary"]
      outputs: ["Approved batch"]

    - step: 4
      name: "Execute Payments"
      actor: "System"
      action: "Submit ACH file, print checks, initiate wires"
      inputs: ["Approved batch"]
      outputs: ["Payment confirmation"]
      automatable: true

    - step: 5
      name: "Update Records"
      actor: "System"
      action: "Mark bills as paid, record check numbers"
      inputs: ["Payment confirmation"]
      outputs: ["Updated bill status"]
      automatable: true

    - step: 6
      name: "Notify Vendors (optional)"
      actor: "System"
      action: "Send payment remittance advice"
      inputs: ["Payment records"]
      outputs: ["Remittance emails"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-AP-001 | **Bill doesn't match PO** | Medium | Flag variance; require approval with reason code |
| EC-AP-002 | **Duplicate bill submitted** | Medium | Detect by vendor + bill number + amount; warn before entry |
| EC-AP-003 | **Vendor changes bank account** | High | Require verification call; dual approval for banking changes |
| EC-AP-004 | **Early payment discount expiring** | Low | Alert AP; prioritize in next payment run |
| EC-AP-005 | **Partial shipment received** | Medium | Match to received quantity only; hold remainder |
| EC-AP-006 | **Vendor credit not applied** | Low | Show available credits during bill entry; suggest application |
| EC-AP-007 | **Check not cashed after 90 days** | Low | Void and reissue or write back to expense |
| EC-AP-008 | **Multi-currency vendor payment** | High | Convert at payment date rate; track FX gain/loss |
| EC-AP-009 | **1099 vendor missing W-9** | Medium | Block payment until W-9 received; track annually |
| EC-AP-010 | **Bill approved after vendor blocked** | High | Reject payment; route for review |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-AP-001 | **Invoice data extraction** | Scanned/PDF invoice | Structured bill data | Reduces manual entry |
| AI-AP-002 | **Duplicate detection** | New bill, historical bills | Duplicate probability | Prevents double payment |
| AI-AP-003 | **GL coding suggestion** | Bill description, history | Suggested GL account | Speeds coding; improves accuracy |
| AI-AP-004 | **Cash flow optimization** | Bills, discounts, cash position | Optimal payment timing | Maximizes discount capture |
| AI-AP-005 | **Fraud detection** | Vendor data, payment patterns | Risk flags | Catches suspicious changes |

---

## Package 5: Expenses

### Purpose

Capture employee business spending, enforce policies, and process reimbursements.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What expense categories do you track? (travel, meals, supplies)
- What's your receipt policy? (always required, over $X)
- Do you have per diem rates or actual expense?
- Do employees use corporate cards?

**Workflow Discovery**:
- How do employees submit expenses? (mobile app, web form)
- Who approves expenses? (manager, finance, auto-approve)
- How are reimbursements paid? (payroll, separate check)
- What reports do managers need?

**Edge Case Probing**:
- Employee loses receipt?
- Expense exceeds policy limit?
- Corporate card used for personal expense?

### Entity Templates

#### Expense

```json
{
  "id": "data.expenses.expense",
  "name": "Expense",
  "type": "data",
  "namespace": "expenses",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual expense item submitted for reimbursement.",
    "attributes": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Employee who incurred expense" },
      { "name": "expense_report_id", "type": "uuid", "required": false, "description": "Parent report if grouped" },
      { "name": "date", "type": "date", "required": true, "description": "Date expense incurred" },
      { "name": "category", "type": "string", "required": true, "description": "Expense category" },
      { "name": "description", "type": "string", "required": true, "description": "Expense description" },
      { "name": "amount", "type": "decimal", "required": true, "description": "Expense amount" },
      { "name": "currency", "type": "string", "required": true, "description": "Original currency" },
      { "name": "converted_amount", "type": "decimal", "required": false, "description": "Amount in home currency" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "approved", "rejected", "reimbursed"], "description": "Workflow status" },
      { "name": "payment_method", "type": "enum", "required": false, "values": ["personal", "corporate_card", "cash_advance", "per_diem"], "description": "How expense was paid" },
      { "name": "billable", "type": "boolean", "required": false, "description": "Charge to client" },
      { "name": "client_id", "type": "uuid", "required": false, "description": "Client to bill if billable" },
      { "name": "project_id", "type": "uuid", "required": false, "description": "Associated project" },
      { "name": "policy_violation", "type": "boolean", "required": false, "description": "Flagged as policy violation" },
      { "name": "violation_reason", "type": "string", "required": false, "description": "Why policy was violated" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "ExpenseReport", "type": "many_to_one", "required": false },
      { "entity": "Receipt", "type": "one_to_many", "required": false },
      { "entity": "Client", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.expenses",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ExpenseReport

```json
{
  "id": "data.expenses.expense_report",
  "name": "Expense Report",
  "type": "data",
  "namespace": "expenses",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Collection of expenses submitted together for approval.",
    "attributes": [
      { "name": "user_id", "type": "uuid", "required": true, "description": "Employee submitting report" },
      { "name": "title", "type": "string", "required": true, "description": "Report title (e.g., 'January Travel')" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "under_review", "approved", "rejected", "reimbursed"], "description": "Report status" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When submitted" },
      { "name": "total_amount", "type": "decimal", "required": true, "description": "Sum of all expenses" },
      { "name": "reimbursable_amount", "type": "decimal", "required": true, "description": "Amount due to employee" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "Approving manager" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "Approval timestamp" },
      { "name": "rejection_reason", "type": "text", "required": false, "description": "Why rejected" },
      { "name": "reimbursed_at", "type": "datetime", "required": false, "description": "When paid" },
      { "name": "reimbursement_method", "type": "enum", "required": false, "values": ["payroll", "direct_deposit", "check"], "description": "Payment method" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Expense", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.expenses",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### Receipt

```json
{
  "id": "data.expenses.receipt",
  "name": "Receipt",
  "type": "data",
  "namespace": "expenses",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Digital copy of expense receipt for documentation.",
    "attributes": [
      { "name": "expense_id", "type": "uuid", "required": true, "description": "Associated expense" },
      { "name": "file_path", "type": "string", "required": true, "description": "Storage path" },
      { "name": "file_type", "type": "string", "required": true, "description": "MIME type (image/jpeg, application/pdf)" },
      { "name": "file_size", "type": "integer", "required": true, "description": "Size in bytes" },
      { "name": "uploaded_at", "type": "datetime", "required": true, "description": "Upload timestamp" },
      { "name": "ocr_processed", "type": "boolean", "required": false, "description": "OCR extraction complete" },
      { "name": "extracted_data", "type": "json", "required": false, "description": "OCR extracted fields" }
    ],
    "relationships": [
      { "entity": "Expense", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "financial.expenses",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ExpensePolicy

```json
{
  "id": "data.expenses.expense_policy",
  "name": "Expense Policy",
  "type": "data",
  "namespace": "expenses",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Rules governing expense submissions.",
    "attributes": [
      { "name": "name", "type": "string", "required": true, "description": "Policy name" },
      { "name": "category", "type": "string", "required": true, "description": "Expense category this applies to" },
      { "name": "max_amount", "type": "decimal", "required": false, "description": "Maximum amount without approval" },
      { "name": "receipt_required_threshold", "type": "decimal", "required": false, "description": "Receipt required above this amount" },
      { "name": "per_diem_rate", "type": "decimal", "required": false, "description": "Daily allowance if per diem" },
      { "name": "requires_preapproval", "type": "boolean", "required": false, "description": "Preapproval needed" },
      { "name": "allowed_vendors", "type": "array", "required": false, "description": "Approved vendor list if restricted" },
      { "name": "auto_approve_below", "type": "decimal", "required": false, "description": "Auto-approve threshold" },
      { "name": "active", "type": "boolean", "required": true, "description": "Policy is active" },
      { "name": "applies_to", "type": "array", "required": false, "description": "User groups/roles this applies to" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "medium",
    "module_source": "financial.expenses",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### WF-EXP-001: Expense Submission and Approval

```yaml
workflow:
  id: "wf.expenses.submit_and_approve"
  name: "Submit and Approve Expenses"
  trigger: "Employee submits expense report"
  actors: ["Employee", "Manager", "Finance", "System"]

  steps:
    - step: 1
      name: "Capture Expenses"
      actor: "Employee"
      action: "Enter expenses and upload receipts"
      inputs: ["Receipts", "Expense details"]
      outputs: ["Draft expenses"]

    - step: 2
      name: "Create Report"
      actor: "Employee"
      action: "Group expenses into report and submit"
      inputs: ["Draft expenses"]
      outputs: ["Submitted expense report"]

    - step: 3
      name: "Policy Check"
      actor: "System"
      action: "Validate against expense policies"
      inputs: ["Submitted report", "Policies"]
      outputs: ["Validation results", "Policy flags"]
      automatable: true

    - step: 4a
      name: "Auto-Approve (within policy)"
      actor: "System"
      action: "Approve report if all items within policy"
      inputs: ["Report with no violations", "Auto-approve rules"]
      outputs: ["Approved report"]
      condition: "All items within auto-approve threshold"
      automatable: true

    - step: 4b
      name: "Manager Review"
      actor: "Manager"
      action: "Review and approve/reject report"
      inputs: ["Report with flags", "Validation results"]
      outputs: ["Approval decision"]
      condition: "Requires manager approval"
      decision_point: "Approve all? Approve partial? Reject?"

    - step: 5
      name: "Finance Review (if escalated)"
      actor: "Finance"
      action: "Secondary review for large amounts or exceptions"
      inputs: ["Manager-approved report"]
      outputs: ["Final approval"]
      condition: "Report exceeds finance review threshold"

    - step: 6
      name: "Queue for Reimbursement"
      actor: "System"
      action: "Add to next payroll or payment run"
      inputs: ["Approved report"]
      outputs: ["Scheduled reimbursement"]
      automatable: true

    - step: 7
      name: "Process Reimbursement"
      actor: "System"
      action: "Include in payroll or issue payment"
      inputs: ["Scheduled reimbursement"]
      outputs: ["Payment confirmation"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-EXP-001 | **Receipt lost or unavailable** | Medium | Allow declaration of lost receipt with manager approval; document reason |
| EC-EXP-002 | **Expense exceeds policy limit** | Medium | Flag for manager approval; require justification |
| EC-EXP-003 | **Personal expense on corporate card** | Medium | Mark as personal; deduct from reimbursement or next payroll |
| EC-EXP-004 | **Duplicate expense submitted** | Medium | Detect by date + amount + merchant; warn user |
| EC-EXP-005 | **Exchange rate dispute** | Low | Use rate from card statement or standard rate service |
| EC-EXP-006 | **Expense submitted for terminated employee** | Medium | Process through final payroll; require finance approval |
| EC-EXP-007 | **Group expense split among team** | Low | Allow splitting; track individual portions |
| EC-EXP-008 | **Mileage rate changes mid-trip** | Low | Apply rate as of expense date |
| EC-EXP-009 | **Pre-approval not obtained** | Medium | Flag violation; allow manager to approve with exception |
| EC-EXP-010 | **Receipt in foreign language** | Low | Accept with translation or description; OCR may help |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-EXP-001 | **Receipt OCR** | Receipt image | Extracted merchant, date, amount, items | Reduces manual entry |
| AI-EXP-002 | **Category suggestion** | Merchant name, description | Suggested expense category | Speeds submission |
| AI-EXP-003 | **Duplicate detection** | New expense, expense history | Potential duplicates | Prevents double submission |
| AI-EXP-004 | **Anomaly detection** | Expense patterns, policies | Unusual expense flags | Catches errors and fraud |
| AI-EXP-005 | **Mileage verification** | Start/end addresses, claimed miles | Verified distance | Validates mileage claims |

---

## Cross-Package Relationships

The Financial module packages interconnect to form a complete money movement system:

```
                    ┌─────────────────────────────────────────────┐
                    │              INVOICING                       │
                    │  (Creates receivables when invoice sent)     │
                    └─────────────────┬───────────────────────────┘
                                      │
                                      ▼
┌───────────────────────────────────────────────────────────────────┐
│                     ACCOUNTS RECEIVABLE                            │
│  (Tracks outstanding balances, aging, collections)                 │
└───────────────────────────────┬───────────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────┐
│                         PAYMENTS                                   │
│  (Receives money, applies to invoices, reduces AR)                 │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                     ACCOUNTS PAYABLE                               │
│  (Tracks bills owed to vendors)                                    │
│                          │                                         │
│                          ▼                                         │
│  (Payment run sends money to vendors)                              │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                         EXPENSES                                   │
│  (Employee spending → may become AP if corporate card)             │
│  (Billable expenses → may become invoice line items)               │
└───────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Financial

| From | To | Integration |
|------|-----|-------------|
| Invoicing | Payments | Payment applied to invoice reduces balance |
| Invoicing | AR | Sent invoice creates receivable record |
| Payments | AR | Payment reduces receivable; updates aging |
| AR | Invoicing | Collection notes may trigger credit memo |
| AP | Payments | Payment run creates outbound payments |
| Expenses | Invoicing | Billable expenses become invoice line items |
| Expenses | AP | Corporate card expenses reconcile with card statement |

---

## Integration Points (External Systems)

### Payment Processors

| System | Use Case | Notes |
|--------|----------|-------|
| **Stripe** | Credit/debit cards, ACH | Most common; excellent API; supports saved methods |
| **PayPal** | Alternative payment option | Customer-facing; good for international |
| **Square** | In-person payments | Good for businesses with physical presence |
| **Authorize.net** | Legacy card processing | Common in established businesses |
| **Plaid** | Bank account verification | Required for ACH; identity verification |

### Accounting Systems

| System | Use Case | Notes |
|--------|----------|-------|
| **QuickBooks Online** | Small-medium business accounting | Most popular; good API |
| **Xero** | Cloud accounting | Strong international support |
| **NetSuite** | Enterprise ERP | Complex; full-featured |
| **Sage** | Mid-market accounting | Multiple products |
| **FreshBooks** | Service business invoicing | Good for time-based billing |

### Banking

| System | Use Case | Notes |
|--------|----------|-------|
| **Bank feeds** | Transaction import | Via Plaid or direct |
| **ACH networks** | Direct deposit, payments | NACHA file format |
| **Wire services** | Large/international payments | Higher fees; same-day |
| **Positive Pay** | Check fraud prevention | Compare issued vs presented |

### Expense Management

| System | Use Case | Notes |
|--------|----------|-------|
| **Expensify** | Expense tracking/OCR | Popular standalone |
| **Concur** | Enterprise expense/travel | SAP ecosystem |
| **Brex/Ramp** | Corporate cards with expense | Integrated card + software |
| **Bill.com** | AP automation | Strong AP workflows |

### Tax Services

| System | Use Case | Notes |
|--------|----------|-------|
| **Avalara** | Sales tax calculation | Real-time tax rates |
| **TaxJar** | Sales tax compliance | Good for e-commerce |
| **Vertex** | Enterprise tax | Complex B2B scenarios |

---

## Compliance Considerations

### PCI DSS (Payment Card Industry)

**Applies when**: Accepting credit/debit card payments

| Requirement | Implementation |
|-------------|----------------|
| Never store CVV | Use tokenization |
| Never store full card number | Use processor tokens |
| Encrypt card data in transit | TLS 1.2+ only |
| Limit access to cardholder data | Role-based access |
| Maintain audit trail | Log all access |
| Quarterly security scans | If storing any card data |

**Best Practice**: Use hosted payment forms (Stripe Elements, etc.) to keep card data off your servers entirely.

### Tax Compliance

**Sales Tax**:
- Nexus determination (where you must collect)
- Tax rate by jurisdiction
- Exemption certificate management
- Filing and remittance

**Income Tax (1099)**:
- Track vendor payments over $600
- Collect W-9 before first payment
- Generate and file 1099 forms annually
- Backup withholding if no W-9

### Audit Requirements

| Area | Retention | Notes |
|------|-----------|-------|
| Invoices | 7 years | Digital or physical |
| Payments | 7 years | Include processor records |
| Bank statements | 7 years | Reconciliation evidence |
| Expense receipts | 7 years | IRS documentation |
| AR aging reports | 7 years | Bad debt support |
| AP approvals | 7 years | Authorization trail |

### SOX Compliance (if applicable)

For publicly traded companies:

- Segregation of duties (who can create vs approve)
- Approval limits and thresholds
- Immutable audit trails
- Quarterly review and sign-off
- Access controls and reviews

### GAAP/Revenue Recognition

- Invoice timing vs revenue recognition
- Deferred revenue for prepayments
- Accrual vs cash basis
- Multi-element arrangements
- Percentage of completion (for projects)

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Invoicing | Invoice, InvoiceLine, Client | TimeEntry, Matter |
| Payments | Payment, Refund | PaymentMethod, Transaction |
| AR | Receivable, CollectionNote | AgingBucket, PaymentPlan |
| AP | Payable, Vendor | BillLine, VendorCredit |
| Expenses | Expense, ExpenseReport | Receipt, ExpensePolicy |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| WF-INV-001 | Create and Deliver Invoice | Billing cycle or manual |
| WF-INV-002 | Dispute Resolution | Customer raises dispute |
| WF-PAY-001 | Process Online Payment | Customer submits payment |
| WF-PAY-002 | Process Refund | Staff initiates refund |
| WF-AR-001 | Collection Escalation | Invoice becomes overdue |
| WF-AP-001 | Bill Entry and Approval | Receive vendor invoice |
| WF-AP-002 | Payment Run | Scheduled payment date |
| WF-EXP-001 | Expense Submission | Employee submits report |

### Common Edge Case Themes

1. **Partial transactions** - Payments, refunds, receipts that don't match expected amounts
2. **Currency conversion** - Multi-currency operations with rate tracking
3. **Duplicates** - Prevention and detection of double entries
4. **Status transitions** - Invalid state changes (paying void invoice, etc.)
5. **Policy enforcement** - Threshold violations, missing documentation
6. **External system failures** - Processor timeouts, bank file rejections
7. **Reconciliation mismatches** - Bank vs system discrepancies

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-26 | Initial release |
