# Procurement Module Catalog

**Module**: Procurement
**Version**: 1.0
**Last Updated**: 2026-02-05

---

## Overview

The Procurement module covers the entire purchase-to-pay lifecycle: from identifying needs and selecting vendors, through purchase orders and receiving, to invoice matching and payment authorization. This module is foundational for any business that purchases goods or services from external suppliers.

### When to Use This Module

Select this module when R1 context includes any of:

| Trigger Phrases | Typical Actors | Business Need |
|-----------------|----------------|---------------|
| "requisition", "purchase request", "need to buy" | Requester, Department head | Request goods or services |
| "purchase order", "PO", "ordering" | Buyer, Purchasing agent | Formalize orders with vendors |
| "vendor", "supplier", "sourcing" | Procurement, Supply chain | Manage supplier relationships |
| "receiving", "goods receipt", "delivery" | Warehouse, Receiving clerk | Track incoming shipments |
| "three-way match", "invoice match" | AP, Procurement | Verify invoices against orders and receipts |

### Module Dependencies

```
Procurement Module
├── REQUIRES: Administrative (for settings, user preferences)
├── REQUIRES: Documents (for PO PDFs, contracts)
├── INTEGRATES_WITH: Inventory (stock levels, reorder points)
├── INTEGRATES_WITH: Financial.AP (invoice payment)
├── INTEGRATES_WITH: Financial.GL (expense coding)
├── INTEGRATES_WITH: Budgeting (spend tracking, budget checks)
```

---

## Packages

This module contains 5 packages:

1. **requisitions** - Requesting goods or services
2. **purchasing** - Creating and managing purchase orders
3. **vendors** - Vendor management and scoring
4. **receiving** - Goods receipt and inspection
5. **matching** - Three-way match and invoice verification

---

## Package 1: Requisitions

### Purpose

Capture purchase requests from employees, route for approval, and convert approved requests to purchase orders.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What information do requesters provide? (item, quantity, estimated cost, justification)
- Do you have a catalog of pre-approved items?
- How do you handle one-time vs recurring purchases?
- Do requisitions need budget codes or cost centers?

**Workflow Discovery**:
- Who can create requisitions? (anyone, specific roles)
- What are your approval levels? (by amount, by category)
- How do emergency purchases bypass normal approval?
- Can requisitions be combined into a single PO?

**Edge Case Probing**:
- What if budget is exceeded?
- Can a requisition be split across multiple vendors?
- How do you handle requisitions for services vs goods?

### Entity Templates

#### Requisition

```json
{
  "id": "data.requisitions.requisition",
  "name": "Requisition",
  "type": "data",
  "namespace": "requisitions",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "A request to purchase goods or services submitted by an employee.",
    "fields": [
      { "name": "requisition_number", "type": "string", "required": true, "description": "Unique sequential identifier (e.g., REQ-2026-0001)" },
      { "name": "requester_id", "type": "uuid", "required": true, "description": "Employee who submitted the request" },
      { "name": "department_id", "type": "uuid", "required": true, "description": "Department making the request" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "submitted", "pending_approval", "approved", "rejected", "converted", "canceled"], "description": "Current requisition state" },
      { "name": "priority", "type": "enum", "required": false, "values": ["low", "normal", "high", "urgent"], "description": "Request urgency" },
      { "name": "needed_by_date", "type": "date", "required": false, "description": "When items are needed" },
      { "name": "justification", "type": "text", "required": false, "description": "Business reason for purchase" },
      { "name": "estimated_total", "type": "decimal", "required": true, "description": "Sum of line item estimates" },
      { "name": "budget_code", "type": "string", "required": false, "description": "Budget or cost center to charge" },
      { "name": "suggested_vendor_id", "type": "uuid", "required": false, "description": "Preferred vendor if known" },
      { "name": "submitted_at", "type": "datetime", "required": false, "description": "When requisition was submitted" },
      { "name": "approved_at", "type": "datetime", "required": false, "description": "When final approval received" },
      { "name": "approved_by", "type": "uuid", "required": false, "description": "Final approver" }
    ],
    "relationships": [
      { "entity": "User", "type": "many_to_one", "required": true },
      { "entity": "Department", "type": "many_to_one", "required": true },
      { "entity": "RequisitionLine", "type": "one_to_many", "required": true },
      { "entity": "PurchaseOrder", "type": "one_to_many", "required": false },
      { "entity": "ApprovalRecord", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.requisitions",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### RequisitionLine

```json
{
  "id": "data.requisitions.requisition_line",
  "name": "Requisition Line Item",
  "type": "data",
  "namespace": "requisitions",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual item requested on a requisition.",
    "fields": [
      { "name": "requisition_id", "type": "uuid", "required": true, "description": "Parent requisition" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "item_type", "type": "enum", "required": true, "values": ["goods", "service", "subscription"], "description": "Type of purchase" },
      { "name": "description", "type": "string", "required": true, "description": "Item description" },
      { "name": "catalog_item_id", "type": "uuid", "required": false, "description": "Reference to catalog if from catalog" },
      { "name": "quantity", "type": "decimal", "required": true, "description": "Number of units needed" },
      { "name": "unit_of_measure", "type": "string", "required": true, "description": "Unit (each, box, hour, etc.)" },
      { "name": "estimated_unit_price", "type": "decimal", "required": true, "description": "Estimated price per unit" },
      { "name": "estimated_total", "type": "decimal", "required": true, "description": "quantity * estimated_unit_price" },
      { "name": "gl_account", "type": "string", "required": false, "description": "General ledger account" },
      { "name": "notes", "type": "text", "required": false, "description": "Additional specifications" }
    ],
    "relationships": [
      { "entity": "Requisition", "type": "many_to_one", "required": true },
      { "entity": "CatalogItem", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.requisitions",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ApprovalRule

```json
{
  "id": "data.requisitions.approval_rule",
  "name": "Approval Rule",
  "type": "data",
  "namespace": "requisitions",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Defines approval requirements based on amount thresholds.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Rule name" },
      { "name": "min_amount", "type": "decimal", "required": true, "description": "Minimum amount for this rule" },
      { "name": "max_amount", "type": "decimal", "required": false, "description": "Maximum amount (null for unlimited)" },
      { "name": "approver_role", "type": "string", "required": true, "description": "Role required to approve (manager, director, vp, cfo)" },
      { "name": "auto_approve", "type": "boolean", "required": true, "description": "Automatically approve if within limits" },
      { "name": "category_filter", "type": "array", "required": false, "description": "Applies only to specific categories" },
      { "name": "department_filter", "type": "array", "required": false, "description": "Applies only to specific departments" },
      { "name": "active", "type": "boolean", "required": true, "description": "Rule is currently active" },
      { "name": "priority", "type": "integer", "required": true, "description": "Order for rule evaluation" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.requisitions",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.requisitions.submit_and_approve

```yaml
workflow:
  id: "wf.requisitions.submit_and_approve"
  name: "Submit and Approve Requisition"
  trigger: "Employee submits purchase request"
  actors: ["Requester", "Manager", "Director", "VP", "CFO", "System"]

  steps:
    - step: 1
      name: "Create Requisition"
      actor: "Requester"
      action: "Enter items needed with quantities and estimates"
      inputs: ["Item descriptions", "Quantities", "Estimated prices"]
      outputs: ["Draft requisition"]

    - step: 2
      name: "Submit for Approval"
      actor: "Requester"
      action: "Submit requisition with justification"
      inputs: ["Draft requisition", "Justification"]
      outputs: ["Submitted requisition"]

    - step: 3
      name: "Determine Approval Path"
      actor: "System"
      action: "Evaluate amount against approval rules"
      inputs: ["Requisition total", "Approval rules"]
      outputs: ["Required approvers"]
      automatable: true

    - step: 4a
      name: "Auto-Approve (Low Value)"
      actor: "System"
      action: "Approve requisitions under $500 automatically"
      inputs: ["Requisition under auto-approve threshold"]
      outputs: ["Approved requisition"]
      condition: "Total <= $500 and within budget"
      automatable: true

    - step: 4b
      name: "Manager Approval ($500-$5K)"
      actor: "Manager"
      action: "Review and approve/reject requisition"
      inputs: ["Requisition", "Budget status"]
      outputs: ["Approval decision"]
      condition: "$500 < Total <= $5,000"
      decision_point: "Approve, reject, or request changes?"

    - step: 4c
      name: "Director Approval ($5K-$25K)"
      actor: "Director"
      action: "Review and approve/reject requisition"
      inputs: ["Manager-approved requisition"]
      outputs: ["Approval decision"]
      condition: "$5,000 < Total <= $25,000"

    - step: 4d
      name: "VP Approval ($25K-$100K)"
      actor: "VP"
      action: "Review and approve/reject requisition"
      inputs: ["Director-approved requisition"]
      outputs: ["Approval decision"]
      condition: "$25,000 < Total <= $100,000"

    - step: 4e
      name: "CFO Approval (>$100K)"
      actor: "CFO"
      action: "Review and approve/reject requisition"
      inputs: ["VP-approved requisition"]
      outputs: ["Approval decision"]
      condition: "Total > $100,000"

    - step: 5
      name: "Convert to Purchase Order"
      actor: "System"
      action: "Create PO from approved requisition"
      inputs: ["Approved requisition"]
      outputs: ["Draft purchase order"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRO-001 | **Budget exceeded by requisition** | High | Block submission; show budget vs request; require override approval |
| EC-PRO-002 | **Approver on vacation** | Medium | Delegate to backup approver; escalate after timeout |
| EC-PRO-003 | **Requisition split across multiple vendors** | Medium | Allow multiple POs from single requisition; track parent-child |
| EC-PRO-004 | **Emergency purchase bypasses approval** | High | Allow with post-facto approval; flag for audit; require justification |
| EC-PRO-005 | **Duplicate requisition submitted** | Low | Detect by requester + items + date; warn before submission |
| EC-PRO-006 | **Price estimate significantly wrong** | Medium | Allow PO to differ within tolerance; require re-approval if exceeded |
| EC-PRO-007 | **Partial approval of line items** | Medium | Allow line-by-line approval; split requisition if needed |
| EC-PRO-008 | **Requisition for terminated employee** | High | Cancel pending requisitions; notify manager |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRO-001 | **Catalog matching** | Item description | Suggested catalog items | Faster entry; better pricing |
| AI-PRO-002 | **Budget prediction** | Historical spending | Forecasted budget usage | Proactive budget management |
| AI-PRO-003 | **Vendor suggestion** | Item description, history | Recommended vendors | Better vendor selection |
| AI-PRO-004 | **Price validation** | Estimated price, market data | Price reasonableness score | Catches estimation errors |

---

## Package 2: Purchasing

### Purpose

Create, manage, and track purchase orders from issuance through fulfillment.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What terms appear on your POs? (delivery, payment, warranty)
- Do you use blanket/standing orders for recurring purchases?
- How do you handle amendments to issued POs?
- Do you track PO revisions?

**Workflow Discovery**:
- Who can create purchase orders?
- Do POs require additional approval beyond requisition?
- How do you communicate POs to vendors? (email, portal, EDI)
- How do you track PO status?

**Edge Case Probing**:
- What if vendor can only partially fill order?
- How do you handle price changes after PO issued?
- What if wrong items are shipped?

### Entity Templates

#### PurchaseOrder

```json
{
  "id": "data.purchasing.purchase_order",
  "name": "Purchase Order",
  "type": "data",
  "namespace": "purchasing",
  "tags": ["core-entity", "mvp", "auditable"],
  "status": "discovered",

  "spec": {
    "purpose": "Formal order issued to a vendor for goods or services.",
    "fields": [
      { "name": "po_number", "type": "string", "required": true, "description": "Unique sequential identifier (e.g., PO-2026-0001)" },
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Vendor receiving the order" },
      { "name": "requisition_id", "type": "uuid", "required": false, "description": "Source requisition if applicable" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_approval", "approved", "sent", "acknowledged", "partially_received", "received", "closed", "canceled"], "description": "Current PO state" },
      { "name": "order_date", "type": "date", "required": true, "description": "Date PO was issued" },
      { "name": "expected_delivery_date", "type": "date", "required": false, "description": "When delivery is expected" },
      { "name": "ship_to_address", "type": "address", "required": true, "description": "Delivery location" },
      { "name": "subtotal", "type": "decimal", "required": true, "description": "Sum of line items" },
      { "name": "tax_amount", "type": "decimal", "required": false, "description": "Tax amount" },
      { "name": "shipping_amount", "type": "decimal", "required": false, "description": "Shipping charges" },
      { "name": "total", "type": "decimal", "required": true, "description": "Final PO total" },
      { "name": "currency", "type": "string", "required": true, "description": "ISO 4217 currency code" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Payment terms (Net 30, etc.)" },
      { "name": "shipping_method", "type": "string", "required": false, "description": "Requested shipping method" },
      { "name": "buyer_id", "type": "uuid", "required": true, "description": "Purchasing agent who created PO" },
      { "name": "notes", "type": "text", "required": false, "description": "Special instructions for vendor" },
      { "name": "internal_notes", "type": "text", "required": false, "description": "Internal notes not sent to vendor" },
      { "name": "sent_at", "type": "datetime", "required": false, "description": "When PO was sent to vendor" },
      { "name": "acknowledged_at", "type": "datetime", "required": false, "description": "When vendor acknowledged receipt" },
      { "name": "revision_number", "type": "integer", "required": true, "description": "PO revision count" }
    ],
    "relationships": [
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "Requisition", "type": "many_to_one", "required": false },
      { "entity": "POLine", "type": "one_to_many", "required": true },
      { "entity": "Receipt", "type": "one_to_many", "required": false },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.purchasing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### POLine

```json
{
  "id": "data.purchasing.po_line",
  "name": "Purchase Order Line Item",
  "type": "data",
  "namespace": "purchasing",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual item on a purchase order.",
    "fields": [
      { "name": "purchase_order_id", "type": "uuid", "required": true, "description": "Parent purchase order" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "item_number", "type": "string", "required": false, "description": "Vendor's item/SKU number" },
      { "name": "description", "type": "string", "required": true, "description": "Item description" },
      { "name": "quantity_ordered", "type": "decimal", "required": true, "description": "Quantity ordered" },
      { "name": "quantity_received", "type": "decimal", "required": true, "description": "Quantity received to date" },
      { "name": "quantity_invoiced", "type": "decimal", "required": true, "description": "Quantity invoiced to date" },
      { "name": "unit_of_measure", "type": "string", "required": true, "description": "Unit (each, box, etc.)" },
      { "name": "unit_price", "type": "decimal", "required": true, "description": "Price per unit" },
      { "name": "amount", "type": "decimal", "required": true, "description": "quantity_ordered * unit_price" },
      { "name": "gl_account", "type": "string", "required": false, "description": "General ledger account" },
      { "name": "cost_center", "type": "string", "required": false, "description": "Cost center to charge" },
      { "name": "expected_delivery_date", "type": "date", "required": false, "description": "Line-level delivery date" },
      { "name": "status", "type": "enum", "required": true, "values": ["open", "partially_received", "received", "closed", "canceled"], "description": "Line status" }
    ],
    "relationships": [
      { "entity": "PurchaseOrder", "type": "many_to_one", "required": true },
      { "entity": "ReceiptLine", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.purchasing",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.purchasing.create_and_send

```yaml
workflow:
  id: "wf.purchasing.create_and_send"
  name: "Create and Send Purchase Order"
  trigger: "Approved requisition or manual PO creation"
  actors: ["Buyer", "Manager", "System"]

  steps:
    - step: 1
      name: "Create Purchase Order"
      actor: "Buyer"
      action: "Select vendor and enter line items"
      inputs: ["Approved requisition or manual entry", "Vendor selection"]
      outputs: ["Draft PO"]

    - step: 2
      name: "Verify Pricing"
      actor: "Buyer"
      action: "Confirm prices against contracts or quotes"
      inputs: ["Draft PO", "Vendor contracts"]
      outputs: ["Verified PO"]
      decision_point: "Use contract pricing? Request quote?"

    - step: 3
      name: "PO Approval (if required)"
      actor: "Manager"
      action: "Approve PO if exceeds buyer authority"
      inputs: ["Draft PO"]
      outputs: ["Approved PO"]
      condition: "PO exceeds buyer approval limit"

    - step: 4
      name: "Send to Vendor"
      actor: "System"
      action: "Transmit PO via email, portal, or EDI"
      inputs: ["Approved PO", "Vendor preferences"]
      outputs: ["Sent PO", "Transmission confirmation"]
      automatable: true

    - step: 5
      name: "Await Acknowledgment"
      actor: "System"
      action: "Monitor for vendor acknowledgment"
      inputs: ["Sent PO"]
      outputs: ["Acknowledgment status"]
      automatable: true

    - step: 6
      name: "Follow Up if No Response"
      actor: "Buyer"
      action: "Contact vendor if no acknowledgment within SLA"
      inputs: ["Unacknowledged PO"]
      outputs: ["Vendor communication"]
      condition: "No acknowledgment within 48 hours"
```

#### wf.purchasing.change_order

```yaml
workflow:
  id: "wf.purchasing.change_order"
  name: "Process PO Change"
  trigger: "Need to modify existing PO"
  actors: ["Buyer", "Manager", "System"]

  steps:
    - step: 1
      name: "Request Change"
      actor: "Buyer"
      action: "Document required changes (quantity, price, items)"
      inputs: ["Original PO", "Change request"]
      outputs: ["Proposed changes"]

    - step: 2
      name: "Evaluate Impact"
      actor: "System"
      action: "Calculate price/budget impact of changes"
      inputs: ["Proposed changes"]
      outputs: ["Impact analysis"]
      automatable: true

    - step: 3
      name: "Approve Changes"
      actor: "Manager"
      action: "Approve if change exceeds threshold"
      inputs: ["Impact analysis"]
      outputs: ["Approved changes"]
      condition: "Change amount exceeds threshold"

    - step: 4
      name: "Issue Revised PO"
      actor: "System"
      action: "Increment revision, send updated PO to vendor"
      inputs: ["Approved changes"]
      outputs: ["Revised PO"]
      automatable: true

    - step: 5
      name: "Vendor Acknowledgment"
      actor: "System"
      action: "Await vendor confirmation of changes"
      inputs: ["Revised PO"]
      outputs: ["Acknowledgment"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRO-010 | **Vendor cannot fulfill entire order** | Medium | Accept partial shipment; backorder or cancel remainder |
| EC-PRO-011 | **Price changed after PO issued** | High | Require change order approval; maintain audit trail |
| EC-PRO-012 | **Wrong items shipped** | Medium | Create return; issue replacement PO or credit |
| EC-PRO-013 | **Vendor goes out of business** | High | Cancel open POs; find alternate vendors; expedite critical orders |
| EC-PRO-014 | **Blanket PO exceeds limit** | Medium | Alert buyer; require new approval or close PO |
| EC-PRO-015 | **PO sent to wrong vendor** | High | Void immediately; issue correct PO; document error |
| EC-PRO-016 | **Duplicate PO created** | Medium | Detect by vendor + items + date; cancel duplicate |
| EC-PRO-017 | **Currency fluctuation affects PO value** | Medium | Track exchange rate at PO date; reconcile at payment |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRO-010 | **Optimal vendor selection** | Item requirements, vendor history | Ranked vendor list | Better vendor choices |
| AI-PRO-011 | **Price anomaly detection** | PO prices, market data | Price alerts | Catches pricing errors |
| AI-PRO-012 | **Delivery prediction** | Vendor history, order details | Expected delivery date | Better planning |
| AI-PRO-013 | **Contract compliance check** | PO terms, active contracts | Compliance status | Ensures contract usage |

---

## Package 3: Vendors

### Purpose

Manage vendor relationships, contracts, and performance scoring.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What vendor information do you track? (contacts, certifications, insurance)
- Do you use vendor classifications or tiers?
- How do you manage vendor contracts?
- Do you track vendor diversity (minority, women-owned, etc.)?

**Workflow Discovery**:
- What's your vendor onboarding process?
- How often do you review vendor performance?
- Who can add or modify vendor records?
- How do you handle vendor deactivation?

**Edge Case Probing**:
- How do you handle vendor mergers or acquisitions?
- What if a vendor loses required certification?
- How do you manage vendor data privacy?

### Entity Templates

#### Vendor

```json
{
  "id": "data.vendors.vendor",
  "name": "Vendor",
  "type": "data",
  "namespace": "vendors",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "A supplier or service provider from whom we purchase.",
    "fields": [
      { "name": "vendor_number", "type": "string", "required": true, "description": "Unique vendor identifier" },
      { "name": "name", "type": "string", "required": true, "description": "Vendor name" },
      { "name": "legal_name", "type": "string", "required": false, "description": "Legal entity name if different" },
      { "name": "vendor_type", "type": "enum", "required": true, "values": ["supplier", "manufacturer", "distributor", "contractor", "service", "consultant"], "description": "Vendor category" },
      { "name": "status", "type": "enum", "required": true, "values": ["prospect", "pending_approval", "active", "on_hold", "inactive", "blocked"], "description": "Vendor status" },
      { "name": "tax_id", "type": "string", "required": false, "description": "Tax ID / EIN" },
      { "name": "duns_number", "type": "string", "required": false, "description": "D&B DUNS number" },
      { "name": "website", "type": "url", "required": false, "description": "Vendor website" },
      { "name": "primary_contact_name", "type": "string", "required": false, "description": "Main contact person" },
      { "name": "primary_contact_email", "type": "email", "required": true, "description": "Main contact email" },
      { "name": "primary_contact_phone", "type": "phone", "required": false, "description": "Main contact phone" },
      { "name": "address", "type": "address", "required": false, "description": "Primary address" },
      { "name": "remit_to_address", "type": "address", "required": false, "description": "Payment address" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Standard payment terms" },
      { "name": "currency", "type": "string", "required": false, "description": "Preferred currency" },
      { "name": "lead_time_days", "type": "integer", "required": false, "description": "Typical delivery lead time" },
      { "name": "minimum_order_amount", "type": "decimal", "required": false, "description": "Minimum order value" },
      { "name": "diversity_classifications", "type": "array", "required": false, "description": "Diversity certifications (MBE, WBE, etc.)" },
      { "name": "quality_score", "type": "decimal", "required": false, "description": "Quality rating (0-100)" },
      { "name": "delivery_score", "type": "decimal", "required": false, "description": "On-time delivery rating (0-100)" },
      { "name": "service_score", "type": "decimal", "required": false, "description": "Service rating (0-100)" },
      { "name": "overall_score", "type": "decimal", "required": false, "description": "Composite vendor score" },
      { "name": "notes", "type": "text", "required": false, "description": "Internal notes" }
    ],
    "relationships": [
      { "entity": "VendorContact", "type": "one_to_many", "required": false },
      { "entity": "VendorContract", "type": "one_to_many", "required": false },
      { "entity": "PurchaseOrder", "type": "one_to_many", "required": false },
      { "entity": "VendorCertification", "type": "one_to_many", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.vendors",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### VendorContract

```json
{
  "id": "data.vendors.vendor_contract",
  "name": "Vendor Contract",
  "type": "data",
  "namespace": "vendors",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Formal agreement with a vendor including pricing and terms.",
    "fields": [
      { "name": "contract_number", "type": "string", "required": true, "description": "Unique contract identifier" },
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Vendor party to contract" },
      { "name": "contract_type", "type": "enum", "required": true, "values": ["master", "pricing", "blanket_po", "service_agreement", "nda"], "description": "Type of contract" },
      { "name": "status", "type": "enum", "required": true, "values": ["draft", "pending_signature", "active", "expired", "terminated"], "description": "Contract status" },
      { "name": "effective_date", "type": "date", "required": true, "description": "Contract start date" },
      { "name": "expiration_date", "type": "date", "required": false, "description": "Contract end date" },
      { "name": "auto_renew", "type": "boolean", "required": false, "description": "Auto-renewal enabled" },
      { "name": "renewal_notice_days", "type": "integer", "required": false, "description": "Days before expiry to notify" },
      { "name": "total_value", "type": "decimal", "required": false, "description": "Total contract value" },
      { "name": "spent_to_date", "type": "decimal", "required": false, "description": "Amount spent against contract" },
      { "name": "remaining_value", "type": "decimal", "required": false, "description": "Remaining contract value" },
      { "name": "payment_terms", "type": "string", "required": false, "description": "Contract payment terms" },
      { "name": "description", "type": "text", "required": false, "description": "Contract description" },
      { "name": "document_id", "type": "uuid", "required": false, "description": "Link to contract document" }
    ],
    "relationships": [
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "ContractPricing", "type": "one_to_many", "required": false },
      { "entity": "Document", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.vendors",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### VendorScorecard

```json
{
  "id": "data.vendors.vendor_scorecard",
  "name": "Vendor Scorecard",
  "type": "data",
  "namespace": "vendors",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Periodic vendor performance evaluation record.",
    "fields": [
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Vendor being evaluated" },
      { "name": "evaluation_period", "type": "string", "required": true, "description": "Period covered (Q1 2026, etc.)" },
      { "name": "evaluation_date", "type": "date", "required": true, "description": "Date of evaluation" },
      { "name": "evaluator_id", "type": "uuid", "required": true, "description": "Person conducting evaluation" },
      { "name": "quality_score", "type": "decimal", "required": true, "description": "Quality rating (0-100), weight 40%" },
      { "name": "quality_notes", "type": "text", "required": false, "description": "Quality observations" },
      { "name": "delivery_score", "type": "decimal", "required": true, "description": "Delivery rating (0-100), weight 35%" },
      { "name": "delivery_notes", "type": "text", "required": false, "description": "Delivery observations" },
      { "name": "service_score", "type": "decimal", "required": true, "description": "Service rating (0-100), weight 25%" },
      { "name": "service_notes", "type": "text", "required": false, "description": "Service observations" },
      { "name": "overall_score", "type": "decimal", "required": true, "description": "Weighted composite score" },
      { "name": "recommendation", "type": "enum", "required": false, "values": ["preferred", "approved", "conditional", "probation", "remove"], "description": "Status recommendation" },
      { "name": "action_items", "type": "text", "required": false, "description": "Required improvements" }
    ],
    "relationships": [
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.vendors",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.vendors.onboard

```yaml
workflow:
  id: "wf.vendors.onboard"
  name: "Vendor Onboarding"
  trigger: "New vendor needs to be added"
  actors: ["Buyer", "Vendor", "Compliance", "System"]

  steps:
    - step: 1
      name: "Initial Request"
      actor: "Buyer"
      action: "Submit new vendor request with basic info"
      inputs: ["Vendor name", "Contact info", "Reason for adding"]
      outputs: ["Vendor prospect record"]

    - step: 2
      name: "Send Vendor Questionnaire"
      actor: "System"
      action: "Send onboarding questionnaire to vendor"
      inputs: ["Vendor contact email"]
      outputs: ["Questionnaire request"]
      automatable: true

    - step: 3
      name: "Vendor Completes Questionnaire"
      actor: "Vendor"
      action: "Provide company info, certifications, banking details"
      inputs: ["Questionnaire form"]
      outputs: ["Completed questionnaire"]

    - step: 4
      name: "Compliance Review"
      actor: "Compliance"
      action: "Verify tax ID, certifications, insurance"
      inputs: ["Questionnaire responses", "Supporting documents"]
      outputs: ["Compliance status"]
      decision_point: "Pass compliance checks?"

    - step: 5
      name: "Activate Vendor"
      actor: "System"
      action: "Set vendor to active status"
      inputs: ["Approved compliance review"]
      outputs: ["Active vendor record"]
      condition: "Compliance approved"
      automatable: true

    - step: 6
      name: "Notify Stakeholders"
      actor: "System"
      action: "Inform buyer and vendor of activation"
      inputs: ["Active vendor"]
      outputs: ["Notification emails"]
      automatable: true
```

#### wf.vendors.performance_review

```yaml
workflow:
  id: "wf.vendors.performance_review"
  name: "Vendor Performance Review"
  trigger: "Scheduled review period or incident"
  actors: ["Procurement Manager", "Quality Team", "System"]

  steps:
    - step: 1
      name: "Gather Metrics"
      actor: "System"
      action: "Collect delivery, quality, and service data"
      inputs: ["Vendor ID", "Review period"]
      outputs: ["Performance metrics"]
      automatable: true

    - step: 2
      name: "Calculate Scores"
      actor: "System"
      action: "Apply scoring formula (Quality 40%, Delivery 35%, Service 25%)"
      inputs: ["Performance metrics"]
      outputs: ["Calculated scores"]
      automatable: true

    - step: 3
      name: "Review and Adjust"
      actor: "Procurement Manager"
      action: "Review scores, add qualitative notes"
      inputs: ["Calculated scores", "Incident history"]
      outputs: ["Final scorecard"]
      decision_point: "Adjust scores based on context?"

    - step: 4
      name: "Determine Action"
      actor: "Procurement Manager"
      action: "Decide vendor status based on scores"
      inputs: ["Final scorecard"]
      outputs: ["Status recommendation"]
      decision_point: "Preferred, approved, conditional, probation, or remove?"

    - step: 5
      name: "Update Vendor Record"
      actor: "System"
      action: "Update vendor status and scores"
      inputs: ["Status recommendation"]
      outputs: ["Updated vendor record"]
      automatable: true

    - step: 6
      name: "Communicate Results"
      actor: "Procurement Manager"
      action: "Share feedback with vendor if needed"
      inputs: ["Scorecard", "Action items"]
      outputs: ["Vendor communication"]
      condition: "Issues identified or status changed"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRO-020 | **Vendor acquired by another company** | Medium | Update records; review contracts; assess impact on pricing/terms |
| EC-PRO-021 | **Vendor loses required certification** | High | Place on hold; find alternatives; set deadline for recertification |
| EC-PRO-022 | **Duplicate vendor records** | Low | Merge records; update PO references; prevent future duplicates |
| EC-PRO-023 | **Vendor on government sanctions list** | Critical | Block immediately; cancel open orders; escalate to legal |
| EC-PRO-024 | **Contract expires with open POs** | Medium | Extend or negotiate new contract before expiry |
| EC-PRO-025 | **Vendor requests bank account change** | High | Verify through separate channel; require dual approval |
| EC-PRO-026 | **Vendor performance drops significantly** | High | Place on probation; develop improvement plan; find backups |
| EC-PRO-027 | **Vendor capacity cannot meet demand** | Medium | Qualify additional vendors; adjust order quantities |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRO-020 | **Risk assessment** | Vendor data, market signals | Risk score | Early warning of vendor issues |
| AI-PRO-021 | **Contract analysis** | Contract document | Key terms, risks, renewal dates | Better contract visibility |
| AI-PRO-022 | **Spend optimization** | Purchase history, contracts | Consolidation opportunities | Cost savings |
| AI-PRO-023 | **Vendor matching** | Requirements | Best-fit vendors | Faster vendor selection |

---

## Package 4: Receiving

### Purpose

Track incoming shipments, verify quantities and quality, and update inventory records.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- What do you capture at receiving? (packing slip, condition, photos)
- Do you perform quality inspections?
- How do you handle partial shipments?
- Do you track lot numbers or serial numbers?

**Workflow Discovery**:
- Who receives shipments? (warehouse staff, department)
- What's your process for inspecting goods?
- How do you handle damaged goods?
- When do goods go to inventory vs direct to user?

**Edge Case Probing**:
- What if shipment has no packing slip?
- How do you handle over-shipments?
- What if the wrong items are received?

### Entity Templates

#### Receipt

```json
{
  "id": "data.receiving.receipt",
  "name": "Receipt",
  "type": "data",
  "namespace": "receiving",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Record of goods or services received from a vendor.",
    "fields": [
      { "name": "receipt_number", "type": "string", "required": true, "description": "Unique receipt identifier (e.g., RCV-2026-0001)" },
      { "name": "purchase_order_id", "type": "uuid", "required": true, "description": "Related purchase order" },
      { "name": "vendor_id", "type": "uuid", "required": true, "description": "Vendor who shipped" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "received", "inspected", "accepted", "rejected", "partial_reject"], "description": "Receipt status" },
      { "name": "receipt_date", "type": "date", "required": true, "description": "Date goods received" },
      { "name": "received_by", "type": "uuid", "required": true, "description": "User who received shipment" },
      { "name": "packing_slip_number", "type": "string", "required": false, "description": "Vendor's packing slip reference" },
      { "name": "carrier", "type": "string", "required": false, "description": "Shipping carrier" },
      { "name": "tracking_number", "type": "string", "required": false, "description": "Carrier tracking number" },
      { "name": "delivery_location", "type": "string", "required": false, "description": "Where goods were delivered" },
      { "name": "condition_on_arrival", "type": "enum", "required": false, "values": ["good", "damaged", "partial_damage"], "description": "Shipment condition" },
      { "name": "notes", "type": "text", "required": false, "description": "Receiving notes" },
      { "name": "inspection_required", "type": "boolean", "required": false, "description": "Quality inspection needed" },
      { "name": "inspected_by", "type": "uuid", "required": false, "description": "Inspector if applicable" },
      { "name": "inspected_at", "type": "datetime", "required": false, "description": "Inspection timestamp" }
    ],
    "relationships": [
      { "entity": "PurchaseOrder", "type": "many_to_one", "required": true },
      { "entity": "Vendor", "type": "many_to_one", "required": true },
      { "entity": "ReceiptLine", "type": "one_to_many", "required": true },
      { "entity": "User", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.receiving",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### ReceiptLine

```json
{
  "id": "data.receiving.receipt_line",
  "name": "Receipt Line Item",
  "type": "data",
  "namespace": "receiving",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Individual item on a receipt with quantity and condition.",
    "fields": [
      { "name": "receipt_id", "type": "uuid", "required": true, "description": "Parent receipt" },
      { "name": "po_line_id", "type": "uuid", "required": true, "description": "Related PO line item" },
      { "name": "line_number", "type": "integer", "required": true, "description": "Display order" },
      { "name": "description", "type": "string", "required": true, "description": "Item description" },
      { "name": "quantity_ordered", "type": "decimal", "required": true, "description": "Quantity on PO" },
      { "name": "quantity_received", "type": "decimal", "required": true, "description": "Quantity received this shipment" },
      { "name": "quantity_accepted", "type": "decimal", "required": false, "description": "Quantity passing inspection" },
      { "name": "quantity_rejected", "type": "decimal", "required": false, "description": "Quantity failing inspection" },
      { "name": "unit_of_measure", "type": "string", "required": true, "description": "Unit (each, box, etc.)" },
      { "name": "lot_number", "type": "string", "required": false, "description": "Lot/batch number" },
      { "name": "serial_numbers", "type": "array", "required": false, "description": "Serial numbers if tracked" },
      { "name": "storage_location", "type": "string", "required": false, "description": "Where item was stored" },
      { "name": "condition", "type": "enum", "required": false, "values": ["good", "damaged", "defective"], "description": "Item condition" },
      { "name": "rejection_reason", "type": "string", "required": false, "description": "Why items rejected" },
      { "name": "notes", "type": "text", "required": false, "description": "Line notes" }
    ],
    "relationships": [
      { "entity": "Receipt", "type": "many_to_one", "required": true },
      { "entity": "POLine", "type": "many_to_one", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.receiving",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.receiving.receive_shipment

```yaml
workflow:
  id: "wf.receiving.receive_shipment"
  name: "Receive Shipment"
  trigger: "Shipment arrives from vendor"
  actors: ["Receiving Clerk", "Quality Inspector", "System"]

  steps:
    - step: 1
      name: "Log Arrival"
      actor: "Receiving Clerk"
      action: "Record shipment arrival, carrier, tracking info"
      inputs: ["Packing slip", "PO number"]
      outputs: ["Receipt header"]

    - step: 2
      name: "Match to PO"
      actor: "System"
      action: "Look up purchase order and expected items"
      inputs: ["PO number"]
      outputs: ["Expected items list"]
      automatable: true

    - step: 3
      name: "Count and Verify"
      actor: "Receiving Clerk"
      action: "Count items, verify against PO and packing slip"
      inputs: ["Physical items", "Expected items"]
      outputs: ["Receipt lines with quantities"]
      decision_point: "Quantities match? Condition acceptable?"

    - step: 4
      name: "Quality Inspection"
      actor: "Quality Inspector"
      action: "Inspect items requiring quality check"
      inputs: ["Items flagged for inspection"]
      outputs: ["Inspection results"]
      condition: "Items require inspection"

    - step: 5
      name: "Accept or Reject"
      actor: "Receiving Clerk"
      action: "Record accepted and rejected quantities"
      inputs: ["Verification results", "Inspection results"]
      outputs: ["Final receipt"]

    - step: 6
      name: "Update PO Status"
      actor: "System"
      action: "Update PO line quantities received"
      inputs: ["Final receipt"]
      outputs: ["Updated PO"]
      automatable: true

    - step: 7
      name: "Put Away"
      actor: "Receiving Clerk"
      action: "Move items to storage location"
      inputs: ["Accepted items"]
      outputs: ["Storage locations recorded"]
      condition: "Items go to inventory"

    - step: 8
      name: "Handle Rejections"
      actor: "Receiving Clerk"
      action: "Quarantine rejected items, initiate return"
      inputs: ["Rejected items"]
      outputs: ["Return request"]
      condition: "Items rejected"
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRO-030 | **Shipment arrives without PO reference** | Medium | Hold shipment; research vendor and recent orders; match or refuse |
| EC-PRO-031 | **Quantity received exceeds PO quantity** | Medium | Accept up to PO amount; refuse excess or request approval |
| EC-PRO-032 | **Wrong items received** | Medium | Document discrepancy; initiate return; request correct items |
| EC-PRO-033 | **Damaged in transit** | Medium | Document damage with photos; file carrier claim; request replacement |
| EC-PRO-034 | **Quality inspection fails** | Medium | Quarantine items; notify vendor; request credit or replacement |
| EC-PRO-035 | **Serial numbers don't match** | High | Do not accept; contact vendor; potential counterfeit concern |
| EC-PRO-036 | **Partial shipment received** | Low | Accept partial; update PO; track backorder |
| EC-PRO-037 | **Shipment for canceled PO** | Medium | Refuse delivery or arrange return; notify vendor |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRO-030 | **Packing slip OCR** | Packing slip image | Structured data | Faster data entry |
| AI-PRO-031 | **Anomaly detection** | Receipt vs historical | Unusual quantity/item flags | Catches shipping errors |
| AI-PRO-032 | **Quality prediction** | Vendor, item, lot | Quality risk score | Target inspection efforts |
| AI-PRO-033 | **Damage classification** | Damage photos | Damage type and severity | Consistent damage reporting |

---

## Package 5: Matching

### Purpose

Match invoices against purchase orders and receipts for payment authorization.

### Discovery Questions (R2/R3)

**Entity Discovery**:
- Do you use 2-way or 3-way matching?
- What variance tolerances do you allow?
- How do you track match status per invoice line?

**Workflow Discovery**:
- When does matching occur? (invoice entry, batch)
- Who resolves match exceptions?
- What documents do you need for exception approval?
- How do you handle service invoices without receipts?

**Edge Case Probing**:
- Invoice price differs from PO price?
- Invoice quantity exceeds received quantity?
- Multiple invoices for same PO?

### Entity Templates

#### InvoiceMatch

```json
{
  "id": "data.matching.invoice_match",
  "name": "Invoice Match",
  "type": "data",
  "namespace": "matching",
  "tags": ["core-entity", "mvp"],
  "status": "discovered",

  "spec": {
    "purpose": "Three-way match record linking invoice to PO and receipt.",
    "fields": [
      { "name": "match_id", "type": "string", "required": true, "description": "Unique match identifier" },
      { "name": "invoice_id", "type": "uuid", "required": true, "description": "Vendor invoice being matched" },
      { "name": "purchase_order_id", "type": "uuid", "required": true, "description": "Related purchase order" },
      { "name": "receipt_id", "type": "uuid", "required": false, "description": "Related receipt (for 3-way match)" },
      { "name": "match_type", "type": "enum", "required": true, "values": ["two_way", "three_way", "no_po"], "description": "Type of match performed" },
      { "name": "status", "type": "enum", "required": true, "values": ["pending", "matched", "exception", "approved", "rejected"], "description": "Match status" },
      { "name": "matched_at", "type": "datetime", "required": false, "description": "When match completed" },
      { "name": "matched_by", "type": "uuid", "required": false, "description": "User who approved match" },
      { "name": "exception_reason", "type": "string", "required": false, "description": "Why match failed" },
      { "name": "exception_details", "type": "json", "required": false, "description": "Detailed variance information" },
      { "name": "override_reason", "type": "string", "required": false, "description": "Why exception was approved" },
      { "name": "notes", "type": "text", "required": false, "description": "Match notes" }
    ],
    "relationships": [
      { "entity": "VendorInvoice", "type": "many_to_one", "required": true },
      { "entity": "PurchaseOrder", "type": "many_to_one", "required": true },
      { "entity": "Receipt", "type": "many_to_one", "required": false },
      { "entity": "MatchLine", "type": "one_to_many", "required": true }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.matching",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### MatchLine

```json
{
  "id": "data.matching.match_line",
  "name": "Match Line Item",
  "type": "data",
  "namespace": "matching",
  "tags": ["core-entity"],
  "status": "discovered",

  "spec": {
    "purpose": "Line-level match comparison between invoice, PO, and receipt.",
    "fields": [
      { "name": "match_id", "type": "uuid", "required": true, "description": "Parent match record" },
      { "name": "invoice_line_id", "type": "uuid", "required": true, "description": "Invoice line being matched" },
      { "name": "po_line_id", "type": "uuid", "required": true, "description": "PO line being matched" },
      { "name": "receipt_line_id", "type": "uuid", "required": false, "description": "Receipt line being matched" },
      { "name": "po_quantity", "type": "decimal", "required": true, "description": "Quantity on PO" },
      { "name": "receipt_quantity", "type": "decimal", "required": false, "description": "Quantity received" },
      { "name": "invoice_quantity", "type": "decimal", "required": true, "description": "Quantity invoiced" },
      { "name": "quantity_variance", "type": "decimal", "required": false, "description": "Quantity difference" },
      { "name": "quantity_variance_percent", "type": "decimal", "required": false, "description": "Quantity variance %" },
      { "name": "po_unit_price", "type": "decimal", "required": true, "description": "PO unit price" },
      { "name": "invoice_unit_price", "type": "decimal", "required": true, "description": "Invoice unit price" },
      { "name": "price_variance", "type": "decimal", "required": false, "description": "Price difference" },
      { "name": "price_variance_percent", "type": "decimal", "required": false, "description": "Price variance %" },
      { "name": "status", "type": "enum", "required": true, "values": ["matched", "quantity_exception", "price_exception", "both_exception"], "description": "Line match status" },
      { "name": "within_tolerance", "type": "boolean", "required": true, "description": "Variance within allowed tolerance" }
    ],
    "relationships": [
      { "entity": "InvoiceMatch", "type": "many_to_one", "required": true },
      { "entity": "VendorInvoiceLine", "type": "many_to_one", "required": true },
      { "entity": "POLine", "type": "many_to_one", "required": true },
      { "entity": "ReceiptLine", "type": "many_to_one", "required": false }
    ]
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.matching",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

#### MatchTolerance

```json
{
  "id": "data.matching.match_tolerance",
  "name": "Match Tolerance",
  "type": "data",
  "namespace": "matching",
  "tags": ["configuration"],
  "status": "discovered",

  "spec": {
    "purpose": "Configurable tolerance rules for invoice matching.",
    "fields": [
      { "name": "name", "type": "string", "required": true, "description": "Tolerance rule name" },
      { "name": "tolerance_type", "type": "enum", "required": true, "values": ["price", "quantity", "total"], "description": "What tolerance applies to" },
      { "name": "tolerance_percent", "type": "decimal", "required": true, "description": "Allowed variance percentage (e.g., 2.0 for 2%)" },
      { "name": "tolerance_amount", "type": "decimal", "required": false, "description": "Allowed variance in currency" },
      { "name": "apply_to", "type": "enum", "required": true, "values": ["per_line", "per_invoice", "per_po"], "description": "Level at which tolerance applies" },
      { "name": "vendor_category", "type": "string", "required": false, "description": "Apply to specific vendor category" },
      { "name": "item_category", "type": "string", "required": false, "description": "Apply to specific item category" },
      { "name": "active", "type": "boolean", "required": true, "description": "Tolerance is active" }
    ],
    "relationships": []
  },

  "metadata": {
    "source_round": 2,
    "confidence": "high",
    "module_source": "procurement.matching",
    "created_at": "{{ ISO_DATE }}",
    "updated_at": "{{ ISO_DATE }}",
    "version": 1
  }
}
```

### Workflow Templates

#### wf.matching.three_way_match

```yaml
workflow:
  id: "wf.matching.three_way_match"
  name: "Three-Way Match"
  trigger: "Vendor invoice received"
  actors: ["AP Clerk", "Buyer", "Manager", "System"]

  steps:
    - step: 1
      name: "Enter Invoice"
      actor: "AP Clerk"
      action: "Enter or capture invoice details"
      inputs: ["Vendor invoice"]
      outputs: ["Invoice record"]

    - step: 2
      name: "Identify PO"
      actor: "System"
      action: "Match invoice to purchase order"
      inputs: ["Invoice PO reference", "Vendor ID"]
      outputs: ["Matched PO"]
      automatable: true

    - step: 3
      name: "Identify Receipts"
      actor: "System"
      action: "Find receipts against the PO"
      inputs: ["Matched PO"]
      outputs: ["Related receipts"]
      automatable: true

    - step: 4
      name: "Compare Line Items"
      actor: "System"
      action: "Compare quantities and prices across invoice, PO, receipt"
      inputs: ["Invoice lines", "PO lines", "Receipt lines"]
      outputs: ["Match results with variances"]
      automatable: true

    - step: 5
      name: "Apply Tolerance Rules"
      actor: "System"
      action: "Check variances against configured tolerances (2-5%)"
      inputs: ["Match results", "Tolerance rules"]
      outputs: ["Match status (pass/exception)"]
      automatable: true

    - step: 6a
      name: "Auto-Approve Match"
      actor: "System"
      action: "Approve invoice for payment"
      inputs: ["Match within tolerance"]
      outputs: ["Approved invoice"]
      condition: "All lines within tolerance"
      automatable: true

    - step: 6b
      name: "Route Exception"
      actor: "System"
      action: "Route to appropriate resolver"
      inputs: ["Match with exceptions"]
      outputs: ["Exception notification"]
      condition: "One or more lines exceed tolerance"
      automatable: true

    - step: 7
      name: "Resolve Exception"
      actor: "Buyer"
      action: "Investigate variance, contact vendor if needed"
      inputs: ["Exception details", "Supporting documents"]
      outputs: ["Resolution decision"]
      decision_point: "Accept variance? Request credit? Reject invoice?"

    - step: 8
      name: "Approve Exception"
      actor: "Manager"
      action: "Approve exception override if within authority"
      inputs: ["Resolution decision", "Variance amount"]
      outputs: ["Final approval"]
      condition: "Exception requires manager approval"

    - step: 9
      name: "Queue for Payment"
      actor: "System"
      action: "Add approved invoice to payment queue"
      inputs: ["Approved invoice"]
      outputs: ["Payment scheduled"]
      automatable: true
```

### Edge Case Library

| ID | Scenario | Risk Level | Resolution Approach |
|----|----------|------------|---------------------|
| EC-PRO-040 | **Invoice price exceeds PO price** | High | Flag exception; require buyer approval; may need vendor credit |
| EC-PRO-041 | **Invoice quantity exceeds receipt** | High | Block payment for excess; request supporting receipt |
| EC-PRO-042 | **Multiple invoices for same PO line** | Medium | Track cumulative invoiced vs ordered; prevent over-billing |
| EC-PRO-043 | **Receipt not yet entered** | Medium | Hold invoice until receipt; alert receiving |
| EC-PRO-044 | **No PO for invoice** | High | Route to approver; create retroactive PO if approved |
| EC-PRO-045 | **Currency mismatch** | Medium | Convert at invoice date rate; document exchange rate used |
| EC-PRO-046 | **Invoice for canceled PO** | High | Reject invoice; notify vendor; may need to return goods |
| EC-PRO-047 | **Tolerance percentage varies by vendor** | Low | Support vendor-specific tolerance rules; default to standard |

### AI Touchpoints

| ID | Touchpoint | Input | Output | Value |
|----|------------|-------|--------|-------|
| AI-PRO-040 | **Invoice data extraction** | Invoice PDF/image | Structured invoice data | Reduces manual entry |
| AI-PRO-041 | **Automatic PO matching** | Invoice details, open POs | Best-match PO | Faster matching |
| AI-PRO-042 | **Exception resolution** | Exception history | Suggested resolution | Faster exception handling |
| AI-PRO-043 | **Fraud detection** | Invoice patterns | Anomaly score | Catches duplicate/fraudulent invoices |

---

## Cross-Package Relationships

The Procurement module packages interconnect to form a complete procure-to-pay system:

```
┌─────────────────────────────────────────────────────────────────┐
│                     REQUISITIONS                                 │
│  (Creates purchase requests, routes for approval)                │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                      PURCHASING                                  │
│  (Converts approved requisitions to POs, sends to vendors)       │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       RECEIVING                                  │
│  (Records goods received against POs)                            │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                       MATCHING                                   │
│  (Three-way match: PO vs Receipt vs Invoice)                     │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 ACCOUNTS PAYABLE (Financial Module)              │
│  (Approved invoices queued for payment)                          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                       VENDORS                                    │
│  (Vendor master data used across all packages)                   │
│  (Performance scoring from PO, Receipt, and Match data)          │
└─────────────────────────────────────────────────────────────────┘
```

### Key Integration Points Within Procurement

| From | To | Integration |
|------|-----|-------------|
| Requisitions | Purchasing | Approved requisition creates draft PO |
| Purchasing | Receiving | PO provides expected items list |
| Purchasing | Vendors | PO uses vendor master data and contracts |
| Receiving | Purchasing | Receipt updates PO quantities received |
| Receiving | Matching | Receipt provides received quantities for match |
| Matching | Purchasing | Match compares invoice to PO |
| Matching | Receiving | Match compares invoice to receipt |
| Vendors | Purchasing | Contract pricing applied to PO |
| Vendors | Receiving | Vendor performance updated from receipt data |

---

## Integration Points (External Systems)

### Inventory Management

| System | Use Case | Notes |
|--------|----------|-------|
| **SAP MM** | Enterprise inventory | Full ERP integration |
| **Oracle Inventory** | Enterprise inventory | Oracle ecosystem |
| **NetSuite Inventory** | Mid-market inventory | Cloud-based |
| **Fishbowl** | SMB inventory | QuickBooks integration |
| **inFlow** | Small business | Easy to implement |

### Accounts Payable

| System | Use Case | Notes |
|--------|----------|-------|
| **Bill.com** | AP automation | Popular cloud AP |
| **Coupa** | Procurement suite | End-to-end P2P |
| **SAP Ariba** | Enterprise procurement | Global vendor network |
| **Tipalti** | Global payments | Multi-currency support |
| **AvidXchange** | Mid-market AP | Invoice automation |

### General Ledger

| System | Use Case | Notes |
|--------|----------|-------|
| **QuickBooks** | SMB accounting | Most popular |
| **Xero** | Cloud accounting | Strong API |
| **Sage Intacct** | Mid-market | Multi-entity support |
| **NetSuite GL** | Enterprise | Full ERP |
| **Oracle Financials** | Enterprise | Complex requirements |

### Budgeting

| System | Use Case | Notes |
|--------|----------|-------|
| **Adaptive Planning** | Enterprise budgeting | Workday owned |
| **Anaplan** | Connected planning | Flexible modeling |
| **Planful** | FP&A platform | Cloud-native |
| **Vena** | Excel-based | Familiar interface |

### Document Management

| System | Use Case | Notes |
|--------|----------|-------|
| **DocuSign** | Contract signatures | E-signature standard |
| **PandaDoc** | Proposals and contracts | Sales-friendly |
| **Adobe Sign** | Enterprise signatures | Adobe ecosystem |
| **Dropbox** | File storage | Simple file sharing |
| **SharePoint** | Enterprise docs | Microsoft ecosystem |

---

## Compliance Considerations

### Segregation of Duties

| Function | Should NOT Also Perform |
|----------|-------------------------|
| Create requisition | Approve own requisition |
| Create PO | Approve own PO |
| Receive goods | Create PO for same goods |
| Enter invoice | Approve own invoice |
| Match invoice | Make payment |

### Audit Requirements

| Area | Retention | Notes |
|------|-----------|-------|
| Requisitions | 7 years | Include approval chain |
| Purchase Orders | 7 years | All revisions |
| Receipts | 7 years | Include inspection records |
| Vendor Contracts | Contract term + 7 years | Signed copies |
| Match Documentation | 7 years | Exception approvals |

### Vendor Compliance

| Requirement | Implementation |
|-------------|----------------|
| W-9 collection | Collect before first payment |
| 1099 reporting | Track payments > $600/year |
| Insurance verification | Track certificates of insurance |
| Diversity tracking | Capture certifications |
| Sanctions screening | Check against OFAC, other lists |

### Internal Controls

| Control | Purpose |
|---------|---------|
| Approval thresholds | Prevent unauthorized purchases |
| Three-way match | Verify goods/services before payment |
| Vendor master controls | Prevent fraudulent vendors |
| PO required policy | Ensure proper authorization |
| Budget checking | Prevent overspending |

---

## Anti-Patterns (What to Avoid)

### Complex Approval Matrices

**Avoid**: Building approval matrices with dozens of rules based on department, category, vendor, project, and amount combinations.

**Why**: Creates confusion, slows processing, requires constant maintenance.

**Instead**: Keep approval tiers simple (amount-based), with few category-specific exceptions.

### Punch-Out for Every Vendor

**Avoid**: Implementing punch-out catalog integration with every vendor.

**Why**: Expensive to implement and maintain; many vendors don't support it.

**Instead**: Use punch-out only for high-volume vendors with good catalog systems. Use standard POs for others.

### Building Your Own EDI

**Avoid**: Building custom EDI integration from scratch.

**Why**: EDI standards are complex; many edge cases; compliance requirements.

**Instead**: Use an EDI provider (SPS Commerce, TrueCommerce) or adopt modern alternatives (API, portal).

---

## Quick Reference

### Entity Summary

| Package | Core Entities | Supporting Entities |
|---------|---------------|---------------------|
| Requisitions | Requisition, RequisitionLine | ApprovalRule |
| Purchasing | PurchaseOrder, POLine | - |
| Vendors | Vendor, VendorContract | VendorScorecard, VendorContact |
| Receiving | Receipt, ReceiptLine | - |
| Matching | InvoiceMatch, MatchLine | MatchTolerance |

### Workflow Summary

| ID | Workflow | Trigger |
|----|----------|---------|
| wf.requisitions.submit_and_approve | Submit and approve requisition | Employee requests purchase |
| wf.purchasing.create_and_send | Create and send PO | Approved requisition or manual |
| wf.purchasing.change_order | Process PO change | Need to modify PO |
| wf.vendors.onboard | Vendor onboarding | New vendor needed |
| wf.vendors.performance_review | Performance review | Scheduled review period |
| wf.receiving.receive_shipment | Receive shipment | Shipment arrives |
| wf.matching.three_way_match | Three-way match | Vendor invoice received |

### Approval Tier Summary

| Amount Range | Approver | Notes |
|--------------|----------|-------|
| $0 - $500 | Auto-approve | Within budget, from catalog |
| $500 - $5,000 | Manager | Direct supervisor |
| $5,000 - $25,000 | Director | Department head |
| $25,000 - $100,000 | VP | Vice president |
| > $100,000 | CFO | Executive approval |

### Vendor Scoring Weights

| Factor | Weight | Measurement |
|--------|--------|-------------|
| Quality | 40% | Defect rate, returns, inspections |
| Delivery | 35% | On-time delivery percentage |
| Service | 25% | Responsiveness, issue resolution |

### Match Tolerance Defaults

| Variance Type | Default Tolerance | Notes |
|---------------|-------------------|-------|
| Price variance | 2% | Per line item |
| Quantity variance | 2% | Per line item |
| Total invoice | 5% | Overall invoice |

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-05 | Initial release |
